import 'package:flutter/material.dart';
import '../../../../../core/admin/admin_theme.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../shared/widgets/admin/admin_stat_card.dart';

class DashboardKpiGrid extends StatelessWidget {
  const DashboardKpiGrid({
    super.key,
    required this.stats,
    required this.lowStockCount,
    required this.deliveryOps,
    required this.revenueSparkline,
    required this.ordersSparkline,
    this.revenueTrend,
    this.ordersTrend,
  });

  final Map<String, dynamic> stats;
  final int lowStockCount;
  final Map<String, dynamic> deliveryOps;
  final List<double> revenueSparkline;
  final List<double> ordersSparkline;
  final double? revenueTrend;
  final double? ordersTrend;

  int get _totalOrders => stats['totalOrders'] as int? ?? 0;
  num get _totalRevenue => stats['totalRevenue'] as num? ?? 0;

  String get _avgOrderValue {
    if (_totalOrders == 0) return '₹0';
    return '₹${(_totalRevenue / _totalOrders).toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cols = w > 1400 ? 4 : (w > 900 ? 3 : (w > 500 ? 2 : 1));

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          crossAxisSpacing: AdminSpacing.md,
          mainAxisSpacing: AdminSpacing.md,
          childAspectRatio: 2.55,
          children: [
            AdminStatCard(
              title: 'Revenue today',
              value: '₹${stats['revenueToday'] ?? 0}',
              icon: Icons.currency_rupee,
              color: AppColors.primaryGreen,
              sparkline: revenueSparkline,
              trendPercent: revenueTrend,
              trendUp: (revenueTrend ?? 0) >= 0,
              live: true,
            ),
            AdminStatCard(
              title: 'Orders today',
              value: '${stats['ordersToday'] ?? 0}',
              icon: Icons.shopping_bag_outlined,
              color: AppColors.orangeAccent,
              sparkline: ordersSparkline,
              trendPercent: ordersTrend,
              trendUp: (ordersTrend ?? 0) >= 0,
            ),
            AdminStatCard(
              title: 'Active deliveries',
              value: '${deliveryOps['activeDeliveries'] ?? 0}',
              icon: Icons.local_shipping_outlined,
              color: AppColors.navyBlue,
              live: true,
              subtitle: '${stats['pendingDeliveries'] ?? 0} pending',
            ),
            AdminStatCard(
              title: 'Pending orders',
              value: '${stats['pendingOrders'] ?? 0}',
              icon: Icons.pending_actions_outlined,
              color: AppColors.orangeAccent,
            ),
            AdminStatCard(
              title: 'Partners online',
              value: '${deliveryOps['partnersOnline'] ?? 0}',
              icon: Icons.two_wheeler_outlined,
              color: AppColors.primaryGreen,
              live: true,
            ),
            AdminStatCard(
              title: 'Low stock SKUs',
              value: '$lowStockCount',
              icon: Icons.warning_amber_rounded,
              color: AppColors.errorRed,
            ),
            AdminStatCard(
              title: 'Total customers',
              value: '${stats['totalCustomers'] ?? 0}',
              icon: Icons.people_outline,
              color: AppColors.navyBlue,
              subtitle: '${stats['activeUsersToday'] ?? 0} active today',
            ),
            AdminStatCard(
              title: 'Avg order value',
              value: _avgOrderValue,
              icon: Icons.analytics_outlined,
              color: AppColors.primaryGreen,
            ),
          ],
        );
      },
    );
  }
}

/// Compute day-over-day trend from 7-day sales data.
double? computeTrend(List<dynamic> sales7, String field) {
  if (sales7.length < 2) return null;
  final last = sales7.last as Map<String, dynamic>;
  final prev = sales7[sales7.length - 2] as Map<String, dynamic>;
  final a = (last[field] as num?)?.toDouble() ?? 0;
  final b = (prev[field] as num?)?.toDouble() ?? 0;
  if (b == 0) return a > 0 ? 100 : 0;
  return ((a - b) / b) * 100;
}

List<double> sparklineFromSales(List<dynamic> sales7, String field) {
  return sales7
      .map((d) => ((d as Map)[field] as num?)?.toDouble() ?? 0)
      .toList();
}
