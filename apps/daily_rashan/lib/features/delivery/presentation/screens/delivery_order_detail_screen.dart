import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/delivery_repository.dart';
import 'delivery_otp_screen.dart';

class DeliveryOrderDetailScreen extends ConsumerStatefulWidget {
  const DeliveryOrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<DeliveryOrderDetailScreen> createState() =>
      _DeliveryOrderDetailScreenState();
}

class _DeliveryOrderDetailScreenState
    extends ConsumerState<DeliveryOrderDetailScreen> {
  Map<String, dynamic>? _assignment;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data =
          await ref.read(deliveryRepositoryProvider).getOrder(widget.orderId);
      setState(() => _assignment = data);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _action(Future<Map<String, dynamic>> Function() fn) async {
    try {
      await fn();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.errorRed),
        );
      }
    }
  }

  Future<void> _openMaps(Map<String, dynamic> address) async {
    final lat = address['latitude'];
    final lng = address['longitude'];
    final line = '${address['line1']}, ${address['city']} ${address['pincode']}';
    final uri = lat != null && lng != null
        ? Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
          )
        : Uri.parse(
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(line)}',
          );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callCustomer(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final assignment = _assignment;
    if (assignment == null) {
      return const Scaffold(body: Center(child: Text('Order not found')));
    }

    final order = assignment['order'] as Map<String, dynamic>? ?? {};
    final user = order['user'] as Map<String, dynamic>?;
    final address = order['address'] as Map<String, dynamic>?;
    final status = assignment['status'] as String? ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(order['orderNumber'] as String? ?? 'Order'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Chip(
            label: Text(status.replaceAll('_', ' ')),
            backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),
          Text('Customer: ${user?['name']}'),
          Text('Phone: ${user?['phone']}'),
          if (address != null) Text('${address['line1']}, ${address['pincode']}'),
          Text('Total: ₹${order['totalAmount']}'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _callCustomer(user?['phone'] as String?),
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: address != null ? () => _openMaps(address) : null,
                  icon: const Icon(Icons.map),
                  label: const Text('Maps'),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          if (status == 'ASSIGNED') ...[
            FilledButton(
              onPressed: () => _action(() => ref
                  .read(deliveryRepositoryProvider)
                  .acceptOrder(widget.orderId)),
              child: const Text('Accept order'),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => _action(
                () => ref.read(deliveryRepositoryProvider).pickOrder(widget.orderId),
              ),
              child: const Text('Mark picked'),
            ),
          ],
          if (status == 'PICKED' || status == 'ASSIGNED') ...[
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => _action(
                () => ref.read(deliveryRepositoryProvider).startOrder(widget.orderId),
              ),
              child: const Text('Start delivery'),
            ),
          ],
          if (status == 'ON_THE_WAY') ...[
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                final ok = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DeliveryOtpScreen(orderId: widget.orderId),
                  ),
                );
                if (ok == true) await _load();
              },
              child: const Text('Complete with OTP'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await ref
                      .read(deliveryRepositoryProvider)
                      .resendOtp(widget.orderId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('OTP resent')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                }
              },
              child: const Text('Resend OTP to customer'),
            ),
          ],
        ],
      ),
    );
  }
}
