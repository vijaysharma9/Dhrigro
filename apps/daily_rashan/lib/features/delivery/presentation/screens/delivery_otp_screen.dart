import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/delivery_repository.dart';

class DeliveryOtpScreen extends ConsumerStatefulWidget {
  const DeliveryOtpScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<DeliveryOtpScreen> createState() => _DeliveryOtpScreenState();
}

class _DeliveryOtpScreenState extends ConsumerState<DeliveryOtpScreen> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_otpCtrl.text.trim().length < 4) return;
    setState(() => _loading = true);
    try {
      await ref.read(deliveryRepositoryProvider).deliverOrder(
            widget.orderId,
            _otpCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), backgroundColor: AppColors.errorRed),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery OTP'),
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ask the customer for the 6-digit OTP sent via notification.',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Delivery OTP',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Confirm delivery'),
            ),
          ],
        ),
      ),
    );
  }
}
