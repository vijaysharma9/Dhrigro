import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../payment/data/payment_repository.dart';
import '../../../payment/services/razorpay_checkout_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  List<dynamic> _addresses = [];
  String? _selectedAddressId;
  String _deliveryType = 'NEXT_DAY_MORNING';
  String _paymentMethod = 'COD';
  String _instructions = '';
  bool _loading = true;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    ref.read(razorpayCheckoutServiceProvider).dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final dio = ref.read(dioProvider);
    final res = await dio.get('/addresses');
    final data = res.data;
    if (mounted) {
      setState(() {
        _addresses = data is List ? data : (data as Map?)?['data'] as List? ?? [];
        _selectedAddressId = _addresses.isNotEmpty
            ? (_addresses.first as Map)['id'] as String?
            : null;
        _loading = false;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddressId == null || _placing) return;

    setState(() => _placing = true);

    try {
      final repo = ref.read(paymentRepositoryProvider);
      final order = await repo.placeOrder(
        addressId: _selectedAddressId!,
        deliveryType: _deliveryType,
        paymentMethod: _paymentMethod,
        deliveryInstructions: _instructions,
      );

      final orderId = order['id'] as String?;
      final requiresPayment = order['requiresPayment'] == true;

      if (_paymentMethod == 'RAZORPAY' && requiresPayment && orderId != null) {
        await _startRazorpayPayment(orderId);
      } else {
        ref.invalidate(cartProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order placed successfully!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
          context.go('/orders');
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Future<void> _startRazorpayPayment(String orderId) async {
    final razorpay = ref.read(razorpayCheckoutServiceProvider);
    final repo = ref.read(paymentRepositoryProvider);

    if (!razorpay.isSupported) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Razorpay works on mobile apps. Order saved — pay via app or choose COD.',
            ),
          ),
        );
        context.go('/orders/$orderId');
      }
      return;
    }

    await razorpay.startCheckout(
      orderId: orderId,
      onSuccess: ({
        required String orderId,
        required String razorpayOrderId,
        required String razorpayPaymentId,
        required String razorpaySignature,
      }) async {
        try {
          await repo.verifyRazorpayPayment(
            orderId: orderId,
            razorpayOrderId: razorpayOrderId,
            razorpayPaymentId: razorpayPaymentId,
            razorpaySignature: razorpaySignature,
          );
          ref.invalidate(cartProvider);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment successful!'),
                backgroundColor: AppColors.successGreen,
              ),
            );
            context.go('/orders/$orderId');
          }
        } on ApiException catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.message), backgroundColor: AppColors.errorRed),
            );
          }
        }
      },
      onFailure: (message) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: AppColors.errorRed),
          );
          context.go('/orders/$orderId');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_addresses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off, size: 48, color: AppColors.textGrey),
              const SizedBox(height: 16),
              const Text('Add a delivery address first'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Delivery address',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ..._addresses.map((a) {
            final addr = a as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(top: 8),
              child: RadioListTile<String>(
                value: addr['id'] as String,
                groupValue: _selectedAddressId,
                onChanged: (v) => setState(() => _selectedAddressId = v),
                title: Text(addr['label'] as String? ?? 'Address'),
                subtitle: Text(
                  '${addr['addressLine1']}, ${addr['city']} - ${addr['pincode']}',
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          const Text(
            'Delivery type',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Next morning delivery'),
                  subtitle: const Text('Delivered by 9 AM'),
                  value: 'NEXT_DAY_MORNING',
                  groupValue: _deliveryType,
                  onChanged: (v) => setState(() => _deliveryType = v!),
                ),
                RadioListTile<String>(
                  title: const Text('Same day delivery'),
                  subtitle: const Text('Extra fee may apply'),
                  value: 'SAME_DAY',
                  groupValue: _deliveryType,
                  onChanged: (v) => setState(() => _deliveryType = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold)),
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Cash on Delivery'),
                  subtitle: const Text('Pay when order arrives'),
                  value: 'COD',
                  groupValue: _paymentMethod,
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
                RadioListTile<String>(
                  title: const Text('Pay online'),
                  subtitle: Text(
                    kIsWeb
                        ? 'Use mobile app for Razorpay'
                        : 'UPI, Cards via Razorpay',
                  ),
                  value: 'RAZORPAY',
                  groupValue: _paymentMethod,
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Delivery instructions (optional)',
            ),
            maxLines: 2,
            onChanged: (v) => _instructions = v,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _placing ? null : _placeOrder,
            child: _placing
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _paymentMethod == 'RAZORPAY'
                        ? 'Place order & Pay'
                        : 'Place order',
                  ),
          ),
        ),
      ),
    );
  }
}
