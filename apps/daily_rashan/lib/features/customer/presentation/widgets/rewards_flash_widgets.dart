import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/deal_card.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/customer/customer_insights_provider.dart';
import '../../../../core/customer/customer_prefs_provider.dart';

/// Rewards / loyalty card for home — gamification placeholder.
class RewardsHomeCard extends ConsumerWidget {
  const RewardsHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(customerInsightsProvider).valueOrNull;
    final points = insights?.loyaltyPoints ?? 0;
    final savings = insights?.monthlySavings ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () => context.push('/offers'),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.navyBlue,
                AppColors.navyBlue.withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stars, color: AppColors.orangeAccent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dhrigro Rewards',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$points points · Saved ₹${savings.toStringAsFixed(0)} this month',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Personalized offer chips based on local prefs + purchase history.
class PersonalizedOffersSection extends ConsumerWidget {
  const PersonalizedOffersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(customerPrefsProvider).valueOrNull;
    final insights = ref.watch(customerInsightsProvider).valueOrNull;
    final orders = insights?.ordersPlaced ?? 0;

    final offers = <_PersonalOffer>[
      if (prefs?.welcomeCouponClaimed != true)
        const _PersonalOffer(
          title: 'Welcome offer',
          subtitle: 'Use WELCOME50 on first order',
          icon: Icons.celebration,
        ),
      if (orders >= 3)
        const _PersonalOffer(
          title: 'Loyalty bonus',
          subtitle: 'Extra 5% off staples this week',
          icon: Icons.loyalty,
        ),
      const _PersonalOffer(
        title: 'Free delivery',
        subtitle: 'On orders above ₹499',
        icon: Icons.local_shipping,
      ),
      if ((prefs?.searchHistory ?? []).isNotEmpty)
        _PersonalOffer(
          title: 'Because you searched',
          subtitle: 'Deals on ${prefs!.searchHistory.first}',
          icon: Icons.search,
        ),
    ];

    if (offers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              const Text(
                'For you',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/offers'),
                child: const Text('See all'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 88,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: offers.length,
            itemBuilder: (_, i) {
              final offer = offers[i];
              return GestureDetector(
                onTap: () => context.push('/offers'),
                child: Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      Icon(offer.icon, color: AppColors.orangeAccent, size: 28),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              offer.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              offer.subtitle,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textGrey,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PersonalOffer {
  const _PersonalOffer({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

/// Flash deal row with countdown timer.
class FlashDealsSection extends StatefulWidget {
  const FlashDealsSection({
    super.key,
    required this.products,
    required this.childBuilder,
  });

  final List<Map<String, dynamic>> products;
  final Widget Function(Map<String, dynamic> product) childBuilder;

  @override
  State<FlashDealsSection> createState() => _FlashDealsSectionState();
}

class _FlashDealsSectionState extends State<FlashDealsSection> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _remaining = end.difference(now);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = _remaining - const Duration(seconds: 1);
        if (_remaining.isNegative) _remaining = Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _countdown {
    final h = _remaining.inHours;
    final m = _remaining.inMinutes.remainder(60);
    final s = _remaining.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              const Text(
                'Flash deals',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer, size: 14, color: Colors.red.shade600),
                    const SizedBox(width: 4),
                    Text(
                      _countdown,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: DealCard.listHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: widget.products.take(6).length,
            itemBuilder: (_, i) => widget.childBuilder(widget.products[i]),
          ),
        ),
      ],
    );
  }
}
