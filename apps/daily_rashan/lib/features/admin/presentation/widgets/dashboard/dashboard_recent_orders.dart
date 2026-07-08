import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/admin/admin_api_utils.dart';
import '../../../../../core/admin/admin_theme.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../shared/widgets/admin/admin_data_table.dart';
import '../../../../../shared/widgets/admin/admin_section_header.dart';
import '../../../../../shared/widgets/admin/order_status_chip.dart';

class DashboardRecentOrdersPanel extends StatelessWidget {
  const DashboardRecentOrdersPanel({
    super.key,
    required this.recentOrders,
    this.onOrderTap,
    this.onViewAll,
  });

  final List<dynamic> recentOrders;
  final void Function(Map<String, dynamic> order)? onOrderTap;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final rows = AdminApiUtils.asMapList(recentOrders).take(8).toList();
    final fmt = DateFormat('HH:mm');

    return AdminPanelCard(
      padding: EdgeInsets.zero,
      header: AdminSectionHeader(
        title: 'Recent orders',
        subtitle: '${rows.length} latest',
        icon: Icons.receipt_long_outlined,
        trailing: onViewAll != null
            ? TextButton(onPressed: onViewAll, child: const Text('View all'))
            : null,
      ),
      child: AdminDataTable<Map<String, dynamic>>(
        columns: [
          AdminColumn(
            label: 'Order',
            flex: 2,
            cellBuilder: (o) => Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.12),
                  child: Text(
                    _initials(o),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
                const SizedBox(width: AdminSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o['orderNumber'] as String? ?? '—',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _customerName(o),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AdminSemanticColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AdminColumn(
            label: 'Status',
            cellBuilder: (o) => OrderStatusChip(status: o['status'] as String? ?? ''),
          ),
          AdminColumn(
            label: 'Payment',
            cellBuilder: (o) {
              final ps = (o['paymentStatus'] as String? ?? 'PENDING').toUpperCase();
              final color = ps == 'PAID'
                  ? AppColors.primaryGreen
                  : ps == 'FAILED'
                      ? AppColors.errorRed
                      : AdminSemanticColors.warning;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AdminRadius.pill),
                ),
                child: Text(
                  ps,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                ),
              );
            },
          ),
          AdminColumn(
            label: 'Total',
            align: TextAlign.end,
            cellBuilder: (o) => Text(
              '₹${o['totalAmount']}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          AdminColumn(
            label: 'Time',
            align: TextAlign.end,
            cellBuilder: (o) {
              final placed = o['placedAt'] as String?;
              final dt = placed != null ? DateTime.tryParse(placed) : null;
              return Text(
                dt != null ? fmt.format(dt) : '—',
                style: const TextStyle(fontSize: 11, color: AdminSemanticColors.textMuted),
              );
            },
          ),
        ],
        rows: rows,
        onRowTap: onOrderTap,
        emptyMessage: 'No recent orders',
        emptyIcon: Icons.shopping_bag_outlined,
        bare: true,
      ),
    );
  }

  String _customerName(Map<String, dynamic> o) {
    final user = AdminApiUtils.asMapOrNull(o['user']);
    return user?['name'] as String? ?? user?['phone'] as String? ?? 'Customer';
  }

  String _initials(Map<String, dynamic> o) {
    final name = _customerName(o);
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
