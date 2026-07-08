import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/customer/customer_insights_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OffersCenterScreen extends ConsumerWidget {
  const OffersCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(customerInsightsProvider).valueOrNull;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Offers & Rewards'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Offers'),
              Tab(text: 'Coupons'),
              Tab(text: 'Refer'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OffersTab(points: insights?.loyaltyPoints ?? 0),
            const _CouponsTab(),
            const _ReferralTab(),
          ],
        ),
      ),
    );
  }
}

class _OffersTab extends StatelessWidget {
  const _OffersTab({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _OfferCard(
          title: 'WELCOME50',
          subtitle: '₹50 off on first order above ₹299',
          color: AppColors.orangeAccent,
          onTap: () {},
        ),
        _OfferCard(
          title: 'Free delivery',
          subtitle: 'On orders above ₹499',
          color: AppColors.primaryGreen,
          onTap: () {},
        ),
        _OfferCard(
          title: 'Rewards points',
          subtitle: 'You have $points points — redeem coming soon',
          color: AppColors.navyBlue,
          onTap: () {},
        ),
      ],
    );
  }
}

class _CouponsTab extends StatelessWidget {
  const _CouponsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const Text(
          'Available coupons',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        _CouponTile(code: 'WELCOME50', desc: '₹50 off · min ₹299'),
        _CouponTile(code: 'FREEDEL', desc: 'Free delivery · min ₹499'),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: () => context.go('/cart'),
          child: const Text('Apply coupon in cart'),
        ),
      ],
    );
  }
}

class _ReferralTab extends StatelessWidget {
  const _ReferralTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const Icon(Icons.card_giftcard, size: 64, color: AppColors.primaryGreen),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Refer friends, earn rewards',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Share your code and both get ₹100 off. Coming soon.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGrey),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'DR-REFER-XXXX',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(
            onPressed: () {},
            child: const Text('Share referral link'),
          ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.15), child: Icon(Icons.local_offer, color: color)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _CouponTile extends StatelessWidget {
  const _CouponTile({required this.code, required this.desc});

  final String code;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryGreen, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(code, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('Copy')),
        ],
      ),
    );
  }
}
