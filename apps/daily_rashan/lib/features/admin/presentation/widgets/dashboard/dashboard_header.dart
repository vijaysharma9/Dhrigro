import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/admin/admin_theme.dart';
import '../../../../../core/config/env_config.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../widgets/admin_shell.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({
    super.key,
    required this.stats,
    required this.lastUpdated,
    this.onRefresh,
    this.onNavigate,
    this.isRefreshing = false,
  });

  final Map<String, dynamic> stats;
  final DateTime lastUpdated;
  final VoidCallback? onRefresh;
  final ValueChanged<AdminSection>? onNavigate;
  final bool isRefreshing;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final name = user?.name?.split(' ').first ?? 'Admin';
    final dateFmt = DateFormat('EEE, d MMM yyyy · HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_greeting()}, $name',
                    style: AdminTypography.pageTitle(context).copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFmt.format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AdminSemanticColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AdminSpacing.sm),
                  Wrap(
                    spacing: AdminSpacing.sm,
                    runSpacing: AdminSpacing.xs,
                    children: [
                      _SummaryChip(
                        icon: Icons.shopping_bag_outlined,
                        label: '${stats['ordersToday'] ?? 0} orders today',
                      ),
                      _SummaryChip(
                        icon: Icons.currency_rupee,
                        label: '₹${stats['revenueToday'] ?? 0} revenue',
                      ),
                      _LiveRefreshChip(
                        lastUpdated: lastUpdated,
                        isRefreshing: isRefreshing,
                        onRefresh: onRefresh,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AdminSpacing.lg),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search orders, users…',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: AdminSemanticColors.borderSubtle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AdminRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  isDense: true,
                ),
                onSubmitted: (_) => onNavigate?.call(AdminSection.orders),
              ),
            ),
          ],
        ),
        const SizedBox(height: AdminSpacing.lg),
        Wrap(
          spacing: AdminSpacing.sm,
          runSpacing: AdminSpacing.sm,
          children: [
            _QuickAction(
              icon: Icons.add_box_outlined,
              label: 'Add product',
              onTap: () => onNavigate?.call(AdminSection.products),
            ),
            _QuickAction(
              icon: Icons.local_offer_outlined,
              label: 'Create coupon',
              onTap: () => onNavigate?.call(AdminSection.coupons),
            ),
            _QuickAction(
              icon: Icons.delivery_dining_outlined,
              label: 'Assign delivery',
              onTap: () => onNavigate?.call(AdminSection.delivery),
            ),
            _QuickAction(
              icon: Icons.download_outlined,
              label: 'Export report',
              onTap: () => onNavigate?.call(AdminSection.reports),
            ),
          ],
        ),
        const SizedBox(height: AdminSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: EnvConfig.isProduction
                  ? AppColors.errorRed.withValues(alpha: 0.1)
                  : AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AdminRadius.pill),
            ),
            child: Text(
              EnvConfig.environment.name.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: EnvConfig.isProduction
                    ? AppColors.errorRed
                    : AppColors.primaryGreen,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AdminSemanticColors.borderSubtle,
        borderRadius: BorderRadius.circular(AdminRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AdminSemanticColors.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _LiveRefreshChip extends StatelessWidget {
  const _LiveRefreshChip({
    required this.lastUpdated,
    required this.isRefreshing,
    this.onRefresh,
  });

  final DateTime lastUpdated;
  final bool isRefreshing;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final ago = DateTime.now().difference(lastUpdated);
    final label = ago.inSeconds < 60
        ? 'Updated just now'
        : 'Updated ${ago.inMinutes}m ago';

    return InkWell(
      onTap: onRefresh,
      borderRadius: BorderRadius.circular(AdminRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AdminRadius.pill),
          border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRefreshing)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AdminSemanticColors.surfaceCard,
      borderRadius: BorderRadius.circular(AdminRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AdminRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AdminRadius.md),
            border: Border.all(color: AdminSemanticColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.navyBlue),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navyBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
