import 'package:flutter/material.dart';
import '../../../../../core/admin/admin_theme.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../shared/widgets/admin/admin_section_header.dart';

class LiveOperationsPanel extends StatelessWidget {
  const LiveOperationsPanel({
    super.key,
    required this.stats,
    required this.deliveryOps,
    required this.lowStockCount,
    required this.failedPayments,
    required this.packingPending,
  });

  final Map<String, dynamic> stats;
  final Map<String, dynamic> deliveryOps;
  final int lowStockCount;
  final int failedPayments;
  final int packingPending;

  @override
  Widget build(BuildContext context) {
    final items = [
      _OpsItem(
        label: 'Active deliveries',
        value: '${deliveryOps['activeDeliveries'] ?? 0}',
        icon: Icons.local_shipping,
        color: AppColors.navyBlue,
        priority: _Priority.live,
      ),
      _OpsItem(
        label: 'Pending packing',
        value: '$packingPending',
        icon: Icons.inventory_2_outlined,
        color: AppColors.orangeAccent,
        priority: packingPending > 5 ? _Priority.high : _Priority.medium,
      ),
      _OpsItem(
        label: 'Delayed / pending',
        value: '${stats['pendingOrders'] ?? 0}',
        icon: Icons.schedule,
        color: AdminSemanticColors.warning,
        priority: _Priority.medium,
      ),
      _OpsItem(
        label: 'Failed payments',
        value: '$failedPayments',
        icon: Icons.payment_outlined,
        color: AppColors.errorRed,
        priority: failedPayments > 0 ? _Priority.critical : _Priority.low,
      ),
      _OpsItem(
        label: 'Partners online',
        value: '${deliveryOps['partnersOnline'] ?? 0}',
        icon: Icons.two_wheeler,
        color: AppColors.primaryGreen,
        priority: _Priority.live,
      ),
      _OpsItem(
        label: 'Low stock alerts',
        value: '$lowStockCount',
        icon: Icons.warning_amber_rounded,
        color: AppColors.errorRed,
        priority: lowStockCount > 0 ? _Priority.high : _Priority.low,
      ),
    ];

    return AdminPanelCard(
      padding: const EdgeInsets.all(AdminSpacing.md),
      header: const AdminSectionHeader(
        title: 'Live operations',
        subtitle: 'Real-time ops snapshot',
        icon: Icons.sensors,
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final cols = c.maxWidth > 900 ? 3 : (c.maxWidth > 500 ? 2 : 1);
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: AdminSpacing.sm,
              mainAxisSpacing: AdminSpacing.sm,
              childAspectRatio: 2.8,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => _OpsTile(item: items[i]),
          );
        },
      ),
    );
  }
}

enum _Priority { live, critical, high, medium, low }

class _OpsItem {
  const _OpsItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.priority,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final _Priority priority;
}

class _OpsTile extends StatelessWidget {
  const _OpsTile({required this.item});

  final _OpsItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.md, vertical: AdminSpacing.sm),
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AdminRadius.sm),
        border: Border.all(color: item.color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(item.icon, size: 18, color: item.color),
              if (item.priority == _Priority.live)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: item.color.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AdminSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AdminSemanticColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: item.color,
                  ),
                ),
              ],
            ),
          ),
          if (item.priority == _Priority.critical || item.priority == _Priority.high)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AdminRadius.pill),
              ),
              child: Text(
                item.priority == _Priority.critical ? 'CRIT' : 'HIGH',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: item.color,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

int countStatus(List<dynamic>? ordersByStatus, String status) {
  if (ordersByStatus == null) return 0;
  for (final item in ordersByStatus) {
    final m = item as Map<String, dynamic>;
    if (m['status'] == status) {
      return m['_count']?['status'] as int? ?? 0;
    }
  }
  return 0;
}

int countFailedPayments(List<dynamic> recentOrders) {
  return recentOrders.where((o) {
    final order = o as Map<String, dynamic>;
    return (order['paymentStatus'] as String?)?.toUpperCase() == 'FAILED';
  }).length;
}
