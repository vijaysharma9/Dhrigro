import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/admin/admin_api_utils.dart';
import '../../../../core/admin/admin_theme.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/admin/admin_state_widgets.dart';
import '../providers/admin_providers.dart';
import 'admin_order_detail_sheet.dart';

enum DeliveryBoardColumn {
  pendingAssignment,
  assigned,
  pickedUp,
  nearCustomer,
  delivered,
  failed,
}

extension on DeliveryBoardColumn {
  String get label => switch (this) {
        DeliveryBoardColumn.pendingAssignment => 'Pending assignment',
        DeliveryBoardColumn.assigned => 'Assigned',
        DeliveryBoardColumn.pickedUp => 'Picked up',
        DeliveryBoardColumn.nearCustomer => 'Near customer',
        DeliveryBoardColumn.delivered => 'Delivered',
        DeliveryBoardColumn.failed => 'Failed',
      };

  Color get color => switch (this) {
        DeliveryBoardColumn.pendingAssignment => AdminSemanticColors.warning,
        DeliveryBoardColumn.assigned => AppColors.navyBlue,
        DeliveryBoardColumn.pickedUp => AppColors.orangeAccent,
        DeliveryBoardColumn.nearCustomer => AdminSemanticColors.info,
        DeliveryBoardColumn.delivered => AppColors.primaryGreen,
        DeliveryBoardColumn.failed => AppColors.errorRed,
      };
}

DeliveryBoardColumn classifyOrder(Map<String, dynamic> o) {
  final status = o['status'] as String? ?? '';
  final hasAssignment = o['assignment'] != null;
  final paymentFailed = o['paymentStatus'] == 'FAILED';

  if (paymentFailed || status == 'CANCELLED') {
    return DeliveryBoardColumn.failed;
  }
  if (status == 'DELIVERED') return DeliveryBoardColumn.delivered;
  if (status == 'OUT_FOR_DELIVERY') {
    final placed = DateTime.tryParse(o['placedAt'] as String? ?? '');
    if (placed != null && DateTime.now().difference(placed).inMinutes > 45) {
      return DeliveryBoardColumn.nearCustomer;
    }
    return DeliveryBoardColumn.pickedUp;
  }
  if (hasAssignment && (status == 'PACKED' || status == 'CONFIRMED')) {
    return DeliveryBoardColumn.assigned;
  }
  if (status == 'CONFIRMED' || status == 'PACKED') {
    return DeliveryBoardColumn.pendingAssignment;
  }
  return DeliveryBoardColumn.pendingAssignment;
}

class AdminDeliveryBoard extends ConsumerWidget {
  const AdminDeliveryBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(adminDeliveryBoardProvider);
    final opsAsync = ref.watch(adminDeliveryOpsProvider);

    return ordersAsync.when(
      loading: () => const AdminLoadingState(message: 'Loading dispatch board…'),
      error: (e, _) => AdminErrorState(
        error: e,
        title: 'Could not load board',
        onRetry: () => ref.invalidate(adminDeliveryBoardProvider),
      ),
      data: (res) {
        final rows = AdminApiUtils.asMapList(res['data']);
        final grouped = <DeliveryBoardColumn, List<Map<String, dynamic>>>{};
        for (final col in DeliveryBoardColumn.values) {
          grouped[col] = [];
        }
        for (final o in rows) {
          grouped[classifyOrder(o)]!.add(o);
        }

        final fleetHealth = _fleetHealth(opsAsync.valueOrNull, grouped);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AdminSpacing.lg,
                AdminSpacing.md,
                AdminSpacing.lg,
                0,
              ),
              child: _FleetHealthBanner(health: fleetHealth),
            ),
            const SizedBox(height: AdminSpacing.md),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) {
                  final horizontal = c.maxWidth > 900;
                  if (horizontal) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.lg),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: DeliveryBoardColumn.values
                            .map((col) => _BoardColumn(
                                  column: col,
                                  orders: grouped[col]!,
                                  width: 220,
                                  onOpen: (id) => showAdminOrderDetailSheet(
                                    context,
                                    orderId: id,
                                    onUpdated: () =>
                                        ref.invalidate(adminDeliveryBoardProvider),
                                  ),
                                ))
                            .toList(),
                      ),
                    );
                  }
                  return ListView(
                    padding: const EdgeInsets.all(AdminSpacing.lg),
                    children: DeliveryBoardColumn.values
                        .map((col) => _BoardColumn(
                              column: col,
                              orders: grouped[col]!,
                              width: double.infinity,
                              onOpen: (id) => showAdminOrderDetailSheet(
                                context,
                                orderId: id,
                                onUpdated: () =>
                                    ref.invalidate(adminDeliveryBoardProvider),
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

enum FleetHealth { healthy, overloaded, delayed, critical }

FleetHealth _fleetHealth(
  Map<String, dynamic>? ops,
  Map<DeliveryBoardColumn, List<Map<String, dynamic>>> grouped,
) {
  final pending = grouped[DeliveryBoardColumn.pendingAssignment]!.length;
  final online = ops?['partnersOnline'] as int? ?? 0;
  final delayed = grouped[DeliveryBoardColumn.pickedUp]!.length +
      grouped[DeliveryBoardColumn.nearCustomer]!.length;

  if (online == 0 && pending > 0) return FleetHealth.critical;
  if (pending > online * 3) return FleetHealth.overloaded;
  if (delayed > 5) return FleetHealth.delayed;
  return FleetHealth.healthy;
}

class _FleetHealthBanner extends StatelessWidget {
  const _FleetHealthBanner({required this.health});

  final FleetHealth health;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (health) {
      FleetHealth.healthy => ('Fleet healthy', AppColors.primaryGreen, Icons.check_circle_outline),
      FleetHealth.overloaded => ('Fleet overloaded', AdminSemanticColors.warning, Icons.warning_amber),
      FleetHealth.delayed => ('Delivery delays detected', AppColors.orangeAccent, Icons.schedule),
      FleetHealth.critical => ('Critical — no partners online', AppColors.errorRed, Icons.error_outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.md, vertical: AdminSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AdminRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AdminSpacing.sm),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 12)),
        ],
      ),
    );
  }
}

class _BoardColumn extends StatelessWidget {
  const _BoardColumn({
    required this.column,
    required this.orders,
    required this.width,
    required this.onOpen,
  });

  final DeliveryBoardColumn column;
  final List<Map<String, dynamic>> orders;
  final double width;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: AdminSpacing.md, bottom: AdminSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: column.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  column.label,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: column.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AdminRadius.pill),
                ),
                child: Text(
                  '${orders.length}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: column.color),
                ),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.sm),
          ...orders.take(12).map(
                (o) => _BoardCard(
                  order: o,
                  onTap: () => onOpen(o['id'] as String),
                ),
              ),
          if (orders.length > 12)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${orders.length - 12} more',
                style: const TextStyle(fontSize: 10, color: AdminSemanticColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  const _BoardCard({required this.order, required this.onTap});

  final Map<String, dynamic> order;
  final VoidCallback onTap;

  Duration? get _slaRemaining {
    final placed = DateTime.tryParse(order['placedAt'] as String? ?? '');
    if (placed == null) return null;
    const sla = Duration(hours: 2);
    final deadline = placed.add(sla);
    final remaining = deadline.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get _isUrgent {
    final r = _slaRemaining;
    return r != null && r.inMinutes < 30;
  }

  @override
  Widget build(BuildContext context) {
    final user = AdminApiUtils.asMapOrNull(order['user']);
    final sla = _slaRemaining;
    final urgent = _isUrgent;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: urgent ? 2 : 0,
      color: urgent ? AppColors.errorRed.withValues(alpha: 0.04) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AdminRadius.sm),
        side: const BorderSide(color: AdminSemanticColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AdminRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(AdminSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '#${order['orderNumber']}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
              ),
              Text(
                user?['name'] as String? ?? 'Customer',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10),
              ),
              Text(
                '₹${order['totalAmount']}',
                style: const TextStyle(fontSize: 10, color: AdminSemanticColors.textMuted),
              ),
              if (sla != null)
                Text(
                  sla.inMinutes <= 0
                      ? 'SLA breached'
                      : 'SLA ${sla.inMinutes}m left',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: urgent ? AppColors.errorRed : AdminSemanticColors.warning,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
