import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/admin/admin_api_utils.dart';
import '../../../core/admin/admin_theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/admin/presentation/widgets/admin_shell.dart';

class AdminNotificationItem {
  const AdminNotificationItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.severity,
    this.section,
  });

  final String title;
  final String subtitle;
  final DateTime time;
  final Color severity;
  final AdminSection? section;
}

List<AdminNotificationItem> notificationsFromDashboard(Map<String, dynamic> stats) {
  final items = <AdminNotificationItem>[];
  final now = DateTime.now();

  final recent = stats['recentOrders'] as List? ?? [];
  for (final raw in recent.take(3)) {
    if (raw is! Map) continue;
    final o = AdminApiUtils.asMap(raw);
    if (o['paymentStatus'] == 'FAILED') {
      items.add(AdminNotificationItem(
        title: 'Payment failed',
        subtitle: 'Order #${o['orderNumber']}',
        time: now,
        severity: AppColors.errorRed,
        section: AdminSection.orders,
      ));
    }
  }

  final lowStock = stats['lowStockProducts'] as List? ?? [];
  for (final raw in lowStock.take(2)) {
    if (raw is! Map) continue;
    final p = AdminApiUtils.asMap(raw);
    items.add(AdminNotificationItem(
      title: 'Low stock',
      subtitle: '${p['name']} · ${p['stock']} left',
      time: now.subtract(const Duration(minutes: 15)),
      severity: AdminSemanticColors.warning,
      section: AdminSection.inventory,
    ));
  }

  final pending = stats['pendingOrders'] as int? ?? 0;
  if (pending > 0) {
    items.add(AdminNotificationItem(
      title: '$pending pending orders',
      subtitle: 'Needs fulfillment attention',
      time: now,
      severity: AppColors.orangeAccent,
      section: AdminSection.orders,
    ));
  }

  final deliveryOps = AdminApiUtils.asMapOrNull(stats['deliveryOps']) ?? {};
  final active = deliveryOps['activeDeliveries'] as int? ?? 0;
  if (active > 0) {
    items.add(AdminNotificationItem(
      title: '$active active deliveries',
      subtitle: '${deliveryOps['partnersOnline'] ?? 0} partners online',
      time: now,
      severity: AppColors.primaryGreen,
      section: AdminSection.delivery,
    ));
  }

  return items.take(8).toList();
}

class AdminNotificationsMenu extends StatelessWidget {
  const AdminNotificationsMenu({
    super.key,
    required this.items,
    this.onNavigate,
  });

  final List<AdminNotificationItem> items;
  final ValueChanged<AdminSection>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm');
    return PopupMenuButton<void>(
      offset: const Offset(0, 40),
      tooltip: 'Notifications',
      itemBuilder: (_) {
        if (items.isEmpty) {
          return [
            const PopupMenuItem(
              enabled: false,
              child: Text('No new alerts', style: TextStyle(fontSize: 12)),
            ),
          ];
        }
        return items
            .map(
              (n) => PopupMenuItem<void>(
                onTap: () {
                  if (n.section != null) onNavigate?.call(n.section!);
                },
                child: SizedBox(
                  width: 280,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(color: n.severity, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: AdminSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(n.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            Text(n.subtitle, style: const TextStyle(fontSize: 11, color: AdminSemanticColors.textMuted)),
                          ],
                        ),
                      ),
                      Text(fmt.format(n.time), style: const TextStyle(fontSize: 10, color: AdminSemanticColors.textMuted)),
                    ],
                  ),
                ),
              ),
            )
            .toList();
      },
      child: IconButton(
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.notifications_outlined, size: 20),
            if (items.isNotEmpty)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.errorRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        onPressed: () {},
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
