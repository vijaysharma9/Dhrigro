import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/admin/admin_stat_card.dart';
import '../../../../shared/widgets/admin/order_status_chip.dart';
import '../providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider);
    final width = MediaQuery.sizeOf(context).width;
    final columns = width > 1200 ? 4 : (width > 800 ? 3 : 2);

    final content = dashboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (stats) {
        final sales7 = (stats['salesLast7Days'] as List?) ?? [];
        final sales30 = (stats['salesLast30Days'] as List?) ?? [];
        final recent = stats['recentOrders'] as List? ?? [];
        final lowStock = stats['lowStockProducts'] as List? ?? [];
        final topProducts = stats['topProducts'] as List? ?? [];
        final deliveryOps = stats['deliveryOps'] as Map<String, dynamic>? ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Operations overview',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.navyBlue,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Live snapshot · pull to refresh from toolbar',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 24),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  AdminStatCard(
                    title: 'Revenue today',
                    value: '₹${stats['revenueToday'] ?? 0}',
                    icon: Icons.currency_rupee,
                    color: AppColors.primaryGreen,
                  ),
                  AdminStatCard(
                    title: 'Orders today',
                    value: '${stats['ordersToday'] ?? 0}',
                    icon: Icons.shopping_bag,
                    color: AppColors.orangeAccent,
                  ),
                  AdminStatCard(
                    title: 'Pending deliveries',
                    value: '${stats['pendingDeliveries'] ?? 0}',
                    icon: Icons.local_shipping,
                    color: AppColors.navyBlue,
                  ),
                  AdminStatCard(
                    title: 'Active users today',
                    value: '${stats['activeUsersToday'] ?? 0}',
                    icon: Icons.people,
                    color: AppColors.primaryGreen,
                    subtitle: '${stats['totalCustomers'] ?? 0} total customers',
                  ),
                  AdminStatCard(
                    title: 'Pending orders',
                    value: '${stats['pendingOrders'] ?? 0}',
                    icon: Icons.pending_actions,
                    color: AppColors.orangeAccent,
                  ),
                  AdminStatCard(
                    title: 'Total revenue',
                    value: '₹${stats['totalRevenue'] ?? 0}',
                    icon: Icons.trending_up,
                    color: AppColors.navyBlue,
                  ),
                  AdminStatCard(
                    title: 'Low stock SKUs',
                    value: '${lowStock.length}',
                    icon: Icons.warning_amber,
                    color: AppColors.errorRed,
                  ),
                  AdminStatCard(
                    title: 'Total orders',
                    value: '${stats['totalOrders'] ?? 0}',
                    icon: Icons.receipt_long,
                    color: AppColors.navyBlue,
                  ),
                  AdminStatCard(
                    title: 'Active deliveries',
                    value: '${deliveryOps['activeDeliveries'] ?? 0}',
                    icon: Icons.delivery_dining,
                    color: AppColors.orangeAccent,
                  ),
                  AdminStatCard(
                    title: 'Partners online',
                    value: '${deliveryOps['partnersOnline'] ?? 0}',
                    icon: Icons.two_wheeler,
                    color: AppColors.primaryGreen,
                  ),
                  AdminStatCard(
                    title: 'Delivered today',
                    value: '${deliveryOps['deliveriesToday'] ?? 0}',
                    icon: Icons.check_circle_outline,
                    color: AppColors.navyBlue,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text('Sales (7 days)', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: _SalesBarChart(data: sales7),
              ),
              const SizedBox(height: 32),
              Text('Revenue trend (30 days)', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: _RevenueLineChart(data: sales30),
              ),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recent orders',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        ...recent.take(8).map((o) {
                          final order = o as Map<String, dynamic>;
                          final user = order['user'] as Map<String, dynamic>?;
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.borderLight),
                            ),
                            child: ListTile(
                              title: Text(order['orderNumber'] as String? ?? ''),
                              subtitle: Text(user?['name'] as String? ?? ''),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('₹${order['totalAmount']}'),
                                  OrderStatusChip(
                                    status: order['status'] as String? ?? '',
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Top products',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        ...topProducts.map((p) {
                          final item = p as Map<String, dynamic>;
                          return ListTile(
                            dense: true,
                            title: Text(item['productName'] as String? ?? ''),
                            trailing: Text('${item['quantitySold'] ?? 0}'),
                          );
                        }),
                        const SizedBox(height: 24),
                        Text('Low stock',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        ...lowStock.map((p) {
                          final prod = p as Map<String, dynamic>;
                          return ListTile(
                            dense: true,
                            title: Text(prod['name'] as String? ?? ''),
                            trailing: Text(
                              '${prod['stock']} left',
                              style: const TextStyle(
                                color: AppColors.orangeAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (embedded) return content;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: content,
    );
  }
}

class _SalesBarChart extends StatelessWidget {
  const _SalesBarChart({required this.data});

  final List<dynamic> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No sales data'));
    }

    final spots = <BarChartGroupData>[];
    double maxY = 1;

    for (var i = 0; i < data.length; i++) {
      final d = data[i] as Map<String, dynamic>;
      final revenue = (d['revenue'] as num?)?.toDouble() ?? 0;
      if (revenue > maxY) maxY = revenue;
      spots.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: revenue,
              color: AppColors.primaryGreen,
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: maxY * 1.2,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                final date = (data[i] as Map)['date'] as String? ?? '';
                final label = date.length >= 5 ? date.substring(5) : date;
                return Text(label, style: const TextStyle(fontSize: 10));
              },
            ),
          ),
        ),
        barGroups: spots,
      ),
    );
  }
}

class _RevenueLineChart extends StatelessWidget {
  const _RevenueLineChart({required this.data});

  final List<dynamic> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No revenue data'));
    }

    final spots = <FlSpot>[];
    double maxY = 1;

    for (var i = 0; i < data.length; i++) {
      final d = data[i] as Map<String, dynamic>;
      final revenue = (d['revenue'] as num?)?.toDouble() ?? 0;
      if (revenue > maxY) maxY = revenue;
      spots.add(FlSpot(i.toDouble(), revenue));
    }

    return LineChart(
      LineChartData(
        maxY: maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.borderLight,
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.orangeAccent,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.orangeAccent.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
