import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/customer/customer_prefs_provider.dart';
import '../../../../core/customer/address_sync.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class LocationOnboardingScreen extends ConsumerStatefulWidget {
  const LocationOnboardingScreen({super.key});

  @override
  ConsumerState<LocationOnboardingScreen> createState() =>
      _LocationOnboardingScreenState();
}

class _LocationOnboardingScreenState
    extends ConsumerState<LocationOnboardingScreen> {
  final _pincodeController = TextEditingController();
  final _labelController = TextEditingController(text: 'Home');
  final _addressLineController = TextEditingController();
  bool _checking = false;
  bool _saving = false;
  bool _serviceable = false;
  String? _error;
  String? _city;

  @override
  void dispose() {
    _pincodeController.dispose();
    _labelController.dispose();
    _addressLineController.dispose();
    super.dispose();
  }

  Future<void> _checkPincode() async {
    final pincode = _pincodeController.text.trim();
    if (pincode.length != 6) {
      setState(() {
        _error = 'Enter a valid 6-digit pincode';
        _serviceable = false;
      });
      return;
    }

    setState(() {
      _checking = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get(
        '/delivery/check-pincode',
        queryParameters: {'pincode': pincode},
      );
      final data = res.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _serviceable = data['serviceable'] == true;
          _city = data['city'] as String?;
          _error = _serviceable ? null : 'Delivery not available in this area yet';
          _checking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checking = false;
          _error = 'Could not verify pincode. Try again.';
        });
      }
    }
  }

  Future<void> _continue() async {
    if (!_serviceable) {
      await _checkPincode();
      if (!_serviceable) return;
    }

    final addressLine = _addressLineController.text.trim();
    if (addressLine.length < 5) {
      setState(() => _error = 'Enter your house no. and street (min 5 characters)');
      return;
    }

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      setState(() => _error = 'Please sign in to save your delivery address');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final pincode = _pincodeController.text.trim();
      final label = _labelController.text.trim().isEmpty
          ? 'Home'
          : _labelController.text.trim();

      await ref.read(customerPrefsProvider.notifier).setLocation(
            pincode: pincode,
            label: label,
          );

      await syncDeliveryAddress(
        dio: ref.read(dioProvider),
        pincode: pincode,
        label: label,
        addressLine1: addressLine,
        fullName: user.name ?? 'Customer',
        phone: user.phone ?? '',
        city: _city,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'Could not save address. Check connection and try again.';
        });
      }
      return;
    }

    if (mounted) setState(() => _saving = false);

    final claimed =
        ref.read(customerPrefsProvider).value?.welcomeCouponClaimed ?? false;
    if (!claimed && mounted) {
      await _showWelcomeOffer();
    }

    if (mounted) context.go('/home');
  }

  Future<void> _showWelcomeOffer() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.celebration, size: 48, color: AppColors.orangeAccent),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Welcome to Dhrigro!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Use code WELCOME50 for ₹50 off on your first order above ₹299.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGrey),
            ),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.orangeAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.orangeAccent),
              ),
              child: const Text(
                'WELCOME50',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: AppColors.orangeAccent,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await ref
                      .read(customerPrefsProvider.notifier)
                      .claimWelcomeCoupon();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text('Claim offer'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Refer a friend — coming soon'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery location')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryGreen, Color(0xFF2ECC71)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.white, size: 36),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Where should we deliver?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'We deliver fresh groceries to your doorstep',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            TextField(
              controller: _pincodeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Pincode',
                hintText: '110001',
                suffixIcon: _checking
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: _checkPincode,
                      ),
              ),
              onChanged: (_) => setState(() => _serviceable = false),
              onSubmitted: (_) => _checkPincode(),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!, style: const TextStyle(color: AppColors.errorRed)),
            ],
            if (_serviceable) ...[
              const SizedBox(height: AppSpacing.sm),
              const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.successGreen, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'Great! We deliver to your area',
                    style: TextStyle(color: AppColors.successGreen),
                  ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Address label',
                hintText: 'Home, Office...',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _addressLineController,
              decoration: const InputDecoration(
                labelText: 'House no. & street',
                hintText: 'Flat 12, Green Park Main Road',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _continue,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Continue shopping'),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text('Use current location — coming soon'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
