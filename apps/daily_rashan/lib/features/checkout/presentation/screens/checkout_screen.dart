import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/trust_section.dart';
import '../../../customer/presentation/widgets/cart_smart_recommendations.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/customer/customer_insights_provider.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../payment/data/payment_repository.dart';
import '../../../payment/services/razorpay_checkout_service.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _step = 0;
  List<dynamic> _addresses = [];
  String? _selectedAddressId;
  String _deliveryType = 'NEXT_DAY_MORNING';
  String _paymentMethod = 'COD';
  String _instructions = '';
  bool _loading = true;
  bool _placing = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) _paymentMethod = 'COD';
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    ref.read(razorpayCheckoutServiceProvider).dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/addresses');
      final data = res.data;
      if (mounted) {
        setState(() {
          _addresses =
              data is List ? data : (data as Map?)?['data'] as List? ?? [];
          _selectedAddressId = _addresses.isNotEmpty
              ? (_addresses.first as Map)['id'] as String?
              : null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = 'Could not load addresses. Pull to retry.';
        });
      }
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
        final savings = _num(order['discountAmount']);
        await ref.read(customerInsightsProvider.notifier).recordOrderPlaced(
              savings: savings,
            );
        ref.trackEvent(AnalyticsEvents.orderPlaced, {
          'order_id': orderId ?? '',
          'payment_method': _paymentMethod,
        });
        if (mounted) {
          context.go(
            '/orders/success?orderId=${orderId ?? ''}'
            '&orderNumber=${Uri.encodeComponent(order['orderNumber'] as String? ?? '')}'
            '&total=${order['totalAmount']}',
          );
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
            content: Text('Razorpay works on mobile apps. Order saved — pay via app or COD.'),
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
          final savings = 0.0;
          await ref.read(customerInsightsProvider.notifier).recordOrderPlaced(
                savings: savings,
              );
          ref.trackEvent(AnalyticsEvents.orderPlaced, {
            'order_id': orderId,
            'payment_method': 'RAZORPAY',
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment successful!'),
                backgroundColor: AppColors.successGreen,
              ),
            );
            context.go('/orders/success?orderId=$orderId');
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: EmptyStateWidget(
          icon: Icons.wifi_off,
          title: 'Could not load checkout',
          subtitle: _loadError,
          actionLabel: 'Retry',
          onAction: _load,
        ),
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
              FilledButton(
                onPressed: () => context.push('/location-setup'),
                child: const Text('Set delivery location'),
              ),
            ],
          ),
        ),
      );
    }

    final cart = ref.watch(cartProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(
        children: [
          _StepIndicator(current: _step),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (_step == 0) ..._addressStep(),
                if (_step == 1) ..._deliveryStep(),
                if (_step == 2) ..._paymentStep(),
                if (_step == 3) ..._reviewStep(cart),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              if (_step > 0)
                OutlinedButton(
                  onPressed: () => setState(() => _step--),
                  child: const Text('Back'),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _placing
                      ? null
                      : () {
                          if (_step < 3) {
                            setState(() => _step++);
                          } else {
                            _placeOrder();
                          }
                        },
                  child: _placing
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_step < 3 ? 'Continue' : 'Place order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _addressStep() => [
        const Text('Delivery address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
      ];

  List<Widget> _deliveryStep() => [
        const Text('Delivery slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Card(
          margin: const EdgeInsets.only(top: 8),
          child: Column(
            children: [
              RadioListTile<String>(
                title: const Text('Next morning delivery'),
                subtitle: const Text('Delivered by 9 AM tomorrow'),
                secondary: const Icon(Icons.wb_sunny_outlined),
                value: 'NEXT_DAY_MORNING',
                groupValue: _deliveryType,
                onChanged: (v) => setState(() => _deliveryType = v!),
              ),
              RadioListTile<String>(
                title: const Text('Same day delivery'),
                subtitle: const Text('Evening slot · extra fee may apply'),
                secondary: const Icon(Icons.bolt, color: AppColors.orangeAccent),
                value: 'SAME_DAY',
                groupValue: _deliveryType,
                onChanged: (v) => setState(() => _deliveryType = v!),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Icon(Icons.schedule, color: AppColors.primaryGreen),
              SizedBox(width: 8),
              Text('Estimated delivery: 10–30 minutes after dispatch'),
            ],
          ),
        ),
      ];

  List<Widget> _paymentStep() => [
        const Text('Payment method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
              if (!kIsWeb)
                RadioListTile<String>(
                  title: const Text('Pay online (Razorpay)'),
                  subtitle: const Text('UPI, Cards — secure checkout'),
                  value: 'RAZORPAY',
                  groupValue: _paymentMethod,
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Row(
          children: [
            Icon(Icons.lock, size: 16, color: AppColors.textGrey),
            SizedBox(width: 6),
            Text('100% secure payments', style: TextStyle(color: AppColors.textGrey)),
          ],
        ),
      ];

  List<Widget> _reviewStep(Map<String, dynamic>? cart) => [
        const Text('Review order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: AppSpacing.md),
        if (cart != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  _summaryRow('Subtotal', cart['subtotal']),
                  _summaryRow('Discount', cart['discountAmount']),
                  _summaryRow('Delivery', cart['deliveryFee']),
                  const Divider(),
                  _summaryRow('Total', cart['total'], bold: true),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Delivery instructions (optional)',
            hintText: 'Ring the bell, leave at door...',
          ),
          maxLines: 2,
          onChanged: (v) => _instructions = v,
        ),
        const SizedBox(height: AppSpacing.lg),
        const CheckoutTrustRow(),
        const TrustSection(),
      ];

  Widget _summaryRow(String label, dynamic value, {bool bold = false}) {
    final v = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
          Text(
            '₹${v.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : null,
              color: bold ? AppColors.primaryGreen : null,
            ),
          ),
        ],
      ),
    );
  }

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});

  final int current;

  static const _labels = ['Address', 'Delivery', 'Payment', 'Review'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final active = i <= current;
          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: active
                              ? AppColors.primaryGreen
                              : AppColors.borderLight,
                        ),
                      ),
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: active
                          ? AppColors.primaryGreen
                          : AppColors.borderLight,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          color: active ? Colors.white : AppColors.textGrey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (i < _labels.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i < current
                              ? AppColors.primaryGreen
                              : AppColors.borderLight,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _labels[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: i == current ? FontWeight.bold : null,
                    color: i == current ? AppColors.navyBlue : AppColors.textGrey,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
