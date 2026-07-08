import 'package:flutter/material.dart';
import '../../../../../core/admin/admin_theme.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../shared/widgets/admin/admin_section_header.dart';
import '../../../../../shared/widgets/admin/admin_stat_card.dart';

class CustomerInsightsPanel extends StatelessWidget {
  const CustomerInsightsPanel({super.key, required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final totalCustomers = stats['totalCustomers'] as int? ?? 0;
    final activeToday = stats['activeUsersToday'] as int? ?? 0;
    final totalOrders = stats['totalOrders'] as int? ?? 0;
    final totalRevenue = (stats['totalRevenue'] as num?)?.toDouble() ?? 0;
    final avgBasket = totalOrders > 0 ? totalRevenue / totalOrders : 0;
    final repeatRate = totalCustomers > 0
        ? ((activeToday / totalCustomers) * 100).clamp(0, 100)
        : 0;

    return AdminPanelCard(
      padding: const EdgeInsets.all(AdminSpacing.md),
      header: const AdminSectionHeader(
        title: 'Customer insights',
        subtitle: 'Engagement & basket metrics',
        icon: Icons.insights_outlined,
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth > 500 ? 2 : 1;
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: cols,
            crossAxisSpacing: AdminSpacing.sm,
            mainAxisSpacing: AdminSpacing.sm,
            childAspectRatio: 2.2,
            children: [
              _InsightTile(
                label: 'Active today',
                value: '$activeToday',
                hint: 'of $totalCustomers customers',
                icon: Icons.person_outline,
                color: AppColors.primaryGreen,
              ),
              _InsightTile(
                label: 'Avg basket',
                value: '₹${avgBasket.toStringAsFixed(0)}',
                hint: 'per order',
                icon: Icons.shopping_cart_outlined,
                color: AppColors.orangeAccent,
              ),
              _InsightTile(
                label: 'Daily engagement',
                value: '${repeatRate.toStringAsFixed(0)}%',
                hint: 'active / total',
                icon: Icons.repeat,
                color: AppColors.navyBlue,
              ),
              _InsightTile(
                label: 'Total orders',
                value: '$totalOrders',
                hint: 'lifetime',
                icon: Icons.receipt_long_outlined,
                color: AppColors.navyBlue,
              ),
            ],
          );
        },
      ),
    );
  }
}

class DeliveryInsightsPanel extends StatelessWidget {
  const DeliveryInsightsPanel({
    super.key,
    required this.deliveryOps,
    required this.stats,
  });

  final Map<String, dynamic> deliveryOps;
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final delivered = deliveryOps['deliveriesToday'] as int? ?? 0;
    final active = deliveryOps['activeDeliveries'] as int? ?? 0;
    final online = deliveryOps['partnersOnline'] as int? ?? 0;
    final pending = stats['pendingDeliveries'] as int? ?? 0;
    final completionRate = (delivered + active) > 0
        ? (delivered / (delivered + pending + active) * 100).clamp(0, 100)
        : 100;

    return AdminPanelCard(
      padding: const EdgeInsets.all(AdminSpacing.md),
      header: const AdminSectionHeader(
        title: 'Delivery insights',
        subtitle: 'Fleet performance today',
        icon: Icons.delivery_dining_outlined,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: AdminStatCard(
                  title: 'Delivered today',
                  value: '$delivered',
                  icon: Icons.check_circle_outline,
                  color: AppColors.primaryGreen,
                  compact: true,
                ),
              ),
              const SizedBox(width: AdminSpacing.sm),
              Expanded(
                child: AdminStatCard(
                  title: 'In progress',
                  value: '$active',
                  icon: Icons.local_shipping_outlined,
                  color: AppColors.orangeAccent,
                  compact: true,
                  live: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.sm),
          _InsightRow(
            icon: Icons.two_wheeler_outlined,
            label: 'Partners online',
            value: '$online',
          ),
          _InsightRow(
            icon: Icons.speed,
            label: 'Completion rate (est.)',
            value: '${completionRate.toStringAsFixed(0)}%',
          ),
          const SizedBox(height: AdminSpacing.sm),
          const _PartnerRankingPlaceholder(),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.label,
    required this.value,
    required this.hint,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String hint;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AdminRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 11, color: AdminSemanticColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Text(hint, style: const TextStyle(fontSize: 10, color: AdminSemanticColors.textMuted)),
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AdminSemanticColors.textSecondary),
          const SizedBox(width: AdminSpacing.sm),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 12)),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _PartnerRankingPlaceholder extends StatelessWidget {
  const _PartnerRankingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AdminSpacing.md),
      decoration: BoxDecoration(
        color: AdminSemanticColors.borderSubtle,
        borderRadius: BorderRadius.circular(AdminRadius.sm),
      ),
      child: const Row(
        children: [
          Icon(Icons.leaderboard_outlined, size: 16, color: AdminSemanticColors.textMuted),
          SizedBox(width: AdminSpacing.sm),
          Text(
            'Partner performance ranking · coming soon',
            style: TextStyle(fontSize: 11, color: AdminSemanticColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
