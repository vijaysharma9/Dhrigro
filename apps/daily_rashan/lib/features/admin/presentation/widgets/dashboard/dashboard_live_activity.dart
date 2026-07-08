import 'package:flutter/material.dart';
import '../../../../../core/admin/admin_live_ops.dart';
import '../../../../../core/admin/admin_theme.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../shared/widgets/admin/admin_section_header.dart';
import '../../../../../shared/widgets/admin/live_ops_timeline.dart';

enum ActivitySeverity { info, success, warning, critical, live }

class ActivityItem {
  const ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.severity,
  });

  final String title;
  final String subtitle;
  final DateTime time;
  final IconData icon;
  final ActivitySeverity severity;
}

List<ActivityItem> buildActivityFeed(Map<String, dynamic> stats) {
  final items = <ActivityItem>[];
  final now = DateTime.now();

  final recent = stats['recentOrders'] as List? ?? [];
  for (final raw in recent.take(5)) {
    if (raw is! Map) continue;
    final order = Map<String, dynamic>.from(raw);
    final status = order['status'] as String? ?? '';
    final placedAt = order['placedAt'];
    final time = placedAt is String
        ? DateTime.tryParse(placedAt) ?? now
        : now;
    final paymentFailed = order['paymentStatus'] == 'FAILED';
    items.add(
      ActivityItem(
        title: paymentFailed
            ? 'Payment failed · #${order['orderNumber'] ?? ''}'
            : 'New order · #${order['orderNumber'] ?? ''}',
        subtitle: '₹${order['totalAmount'] ?? 0} · $status',
        time: time,
        icon: paymentFailed ? Icons.payment_outlined : Icons.shopping_bag_outlined,
        severity: paymentFailed ? ActivitySeverity.critical : ActivitySeverity.success,
      ),
    );
  }

  final lowStock = stats['lowStockProducts'] as List? ?? [];
  for (final raw in lowStock.take(3)) {
    if (raw is! Map) continue;
    final p = Map<String, dynamic>.from(raw);
    items.add(
      ActivityItem(
        title: 'Low stock alert',
        subtitle: '${p['name'] ?? 'SKU'} · ${p['stock'] ?? 0} left',
        time: now.subtract(const Duration(minutes: 12)),
        icon: Icons.warning_amber_rounded,
        severity: ActivitySeverity.warning,
      ),
    );
  }

  final deliveryOps = stats['deliveryOps'] as Map<String, dynamic>? ?? {};
  final active = deliveryOps['activeDeliveries'] as int? ?? 0;
  if (active > 0) {
    items.add(
      ActivityItem(
        title: '$active deliveries in progress',
        subtitle: '${deliveryOps['partnersOnline'] ?? 0} partners online',
        time: now,
        icon: Icons.local_shipping_outlined,
        severity: ActivitySeverity.live,
      ),
    );
  }

  final newCustomers = stats['activeUsersToday'] as int? ?? 0;
  if (newCustomers > 0) {
    items.add(
      ActivityItem(
        title: '$newCustomers active customers today',
        subtitle: '${stats['totalCustomers'] ?? 0} total registered',
        time: now.subtract(const Duration(hours: 1)),
        icon: Icons.person_add_outlined,
        severity: ActivitySeverity.info,
      ),
    );
  }

  items.sort((a, b) => b.time.compareTo(a.time));
  return items.take(12).toList();
}

class DashboardLiveActivityPanel extends StatelessWidget {
  const DashboardLiveActivityPanel({super.key, required this.stats});

  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    final events = buildLiveOpsEvents(stats);
    final liveCount = events.where((e) => e.severity == LiveOpsSeverity.live).length;

    return AdminPanelCard(
      padding: const EdgeInsets.all(AdminSpacing.md),
      header: AdminSectionHeader(
        title: 'Live activity',
        subtitle: liveCount > 0 ? '$liveCount live events' : 'Real-time ops stream',
        icon: Icons.notifications_active_outlined,
        trailing: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.primaryGreen,
            shape: BoxShape.circle,
          ),
        ),
      ),
      child: LiveOpsTimeline(events: events, maxHeight: 220, compact: true),
    );
  }
}
