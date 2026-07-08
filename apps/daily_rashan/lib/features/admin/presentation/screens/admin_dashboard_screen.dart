import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/admin/admin_api_utils.dart';
import '../../../../core/admin/admin_theme.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/admin/admin_skeleton.dart';
import '../providers/admin_providers.dart';
import '../widgets/admin_shell.dart';
import '../widgets/dashboard/dashboard_live_activity.dart';
import '../widgets/dashboard/dashboard_charts.dart';
import '../widgets/dashboard/dashboard_header.dart';
import '../widgets/dashboard/dashboard_insights_panels.dart';
import '../widgets/dashboard/dashboard_inventory_panels.dart';
import '../widgets/dashboard/dashboard_kpi_grid.dart';
import '../widgets/dashboard/dashboard_recent_orders.dart';
import '../widgets/dashboard/live_operations_panel.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({
    super.key,
    this.embedded = false,
    this.onNavigate,
  });

  final bool embedded;
  final ValueChanged<AdminSection>? onNavigate;

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  DateTime _lastUpdated = DateTime.now();
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    ref.invalidate(adminDashboardProvider);
    await ref.read(adminDashboardProvider.future);
    if (mounted) {
      setState(() {
        _refreshing = false;
        _lastUpdated = DateTime.now();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(adminDashboardProvider);

    ref.listen(adminDashboardProvider, (prev, next) {
      if (next.hasValue && prev?.isLoading == true) {
        setState(() => _lastUpdated = DateTime.now());
      }
    });

    final content = dashboardAsync.when(
      loading: () => const DashboardSkeleton(),
      error: (e, _) => _DashboardError(
        message: '$e',
        onRetry: _refresh,
      ),
      data: (stats) => _DashboardBody(
        stats: stats,
        lastUpdated: _lastUpdated,
        isRefreshing: _refreshing,
        onRefresh: _refresh,
        onNavigate: widget.onNavigate,
      ),
    );

    if (widget.embedded) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: AdminSemanticColors.surface,
      appBar: AppBar(title: const Text('Dashboard')),
      body: content,
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.stats,
    required this.lastUpdated,
    required this.isRefreshing,
    this.onRefresh,
    this.onNavigate,
  });

  final Map<String, dynamic> stats;
  final DateTime lastUpdated;
  final bool isRefreshing;
  final VoidCallback? onRefresh;
  final ValueChanged<AdminSection>? onNavigate;

  @override
  Widget build(BuildContext context) {
    final sales7 = (stats['salesLast7Days'] as List?) ?? [];
    final sales30 = (stats['salesLast30Days'] as List?) ?? [];
    final recent = stats['recentOrders'] as List? ?? [];
    final lowStock = stats['lowStockProducts'] as List? ?? [];
    final topProducts = stats['topProducts'] as List? ?? [];
    final deliveryOps = AdminApiUtils.asMapOrNull(stats['deliveryOps']) ?? {};
    final ordersByStatus = stats['ordersByStatus'] as List?;

    final revenueSpark = sparklineFromSales(sales7, 'revenue');
    final ordersSpark = sparklineFromSales(sales7, 'orders');

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 1100;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AdminSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DashboardHeader(
                stats: stats,
                lastUpdated: lastUpdated,
                isRefreshing: isRefreshing,
                onRefresh: onRefresh,
                onNavigate: onNavigate,
              ),
              const SizedBox(height: AdminSpacing.xxl),
              DashboardKpiGrid(
                stats: stats,
                lowStockCount: lowStock.length,
                deliveryOps: deliveryOps,
                revenueSparkline: revenueSpark,
                ordersSparkline: ordersSpark,
                revenueTrend: computeTrend(sales7, 'revenue'),
                ordersTrend: computeTrend(sales7, 'orders'),
              ),
              const SizedBox(height: AdminSpacing.lg),
              LiveOperationsPanel(
                stats: stats,
                deliveryOps: deliveryOps,
                lowStockCount: lowStock.length,
                failedPayments: countFailedPayments(recent),
                packingPending: countStatus(ordersByStatus, 'PACKED'),
              ),
              const SizedBox(height: AdminSpacing.lg),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: DashboardLiveActivityPanel(stats: stats),
                    ),
                    const SizedBox(width: AdminSpacing.md),
                    Expanded(
                      flex: 3,
                      child: DashboardChartContainer(
                        title: 'Revenue (7 days)',
                        subtitle: 'Daily gross revenue',
                        height: 180,
                        legend: const [
                          ChartLegendDot(color: AppColors.primaryGreen, label: 'Revenue'),
                        ],
                        child: RevenueBarChart(data: sales7),
                      ),
                    ),
                  ],
                )
              else ...[
                DashboardLiveActivityPanel(stats: stats),
                const SizedBox(height: AdminSpacing.md),
                DashboardChartContainer(
                  title: 'Revenue (7 days)',
                  height: 160,
                  child: RevenueBarChart(data: sales7),
                ),
              ],
              const SizedBox(height: AdminSpacing.md),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: DashboardChartContainer(
                        title: 'Orders trend',
                        subtitle: 'Last 7 days',
                        height: 180,
                        legend: const [
                          ChartLegendDot(color: AppColors.orangeAccent, label: 'Orders'),
                        ],
                        child: OrdersLineChart(data: sales7),
                      ),
                    ),
                    const SizedBox(width: AdminSpacing.md),
                    Expanded(
                      flex: 2,
                      child: DashboardChartContainer(
                        title: 'Delivery performance',
                        subtitle: 'Ops preview',
                        height: 180,
                        child: DeliveryPerformancePlaceholder(deliveryOps: deliveryOps),
                      ),
                    ),
                  ],
                )
              else ...[
                DashboardChartContainer(
                  title: 'Orders trend',
                  height: 150,
                  child: OrdersLineChart(data: sales7),
                ),
                const SizedBox(height: AdminSpacing.md),
                DashboardChartContainer(
                  title: 'Delivery performance',
                  height: 120,
                  child: DeliveryPerformancePlaceholder(deliveryOps: deliveryOps),
                ),
              ],
              const SizedBox(height: AdminSpacing.md),
              DashboardChartContainer(
                title: 'Revenue trend (30 days)',
                subtitle: 'Rolling monthly view',
                height: 140,
                child: RevenueTrendChart(data: sales30),
              ),
              const SizedBox(height: AdminSpacing.lg),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: DashboardRecentOrdersPanel(
                        recentOrders: recent,
                        onViewAll: () => onNavigate?.call(AdminSection.orders),
                      ),
                    ),
                    const SizedBox(width: AdminSpacing.lg),
                    Expanded(
                      child: Column(
                        children: [
                          DashboardLowStockPanel(
                            products: lowStock,
                            onViewInventory: () =>
                                onNavigate?.call(AdminSection.inventory),
                          ),
                          const SizedBox(height: AdminSpacing.lg),
                          DashboardTopProductsPanel(topProducts: topProducts),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                DashboardRecentOrdersPanel(
                  recentOrders: recent,
                  onViewAll: () => onNavigate?.call(AdminSection.orders),
                ),
                const SizedBox(height: AdminSpacing.lg),
                DashboardLowStockPanel(
                  products: lowStock,
                  onViewInventory: () => onNavigate?.call(AdminSection.inventory),
                ),
                const SizedBox(height: AdminSpacing.lg),
                DashboardTopProductsPanel(topProducts: topProducts),
              ],
              const SizedBox(height: AdminSpacing.xxl),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: CustomerInsightsPanel(stats: stats)),
                    const SizedBox(width: AdminSpacing.lg),
                    Expanded(
                      child: DeliveryInsightsPanel(
                        deliveryOps: deliveryOps,
                        stats: stats,
                      ),
                    ),
                  ],
                )
              else ...[
                CustomerInsightsPanel(stats: stats),
                const SizedBox(height: AdminSpacing.lg),
                DeliveryInsightsPanel(deliveryOps: deliveryOps, stats: stats),
              ],
              const SizedBox(height: AdminSpacing.lg),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: AdminSemanticColors.textMuted),
            const SizedBox(height: AdminSpacing.lg),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AdminSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
