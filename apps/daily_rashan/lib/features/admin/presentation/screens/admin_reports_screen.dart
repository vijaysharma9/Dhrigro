import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/admin/admin_api_utils.dart';
import '../../../../core/admin/admin_theme.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/csv_download.dart';
import '../../../../shared/widgets/admin/admin_page_layout.dart';
import '../../../../shared/widgets/admin/admin_state_widgets.dart';
import '../../../../shared/widgets/admin/admin_stat_card.dart';
import '../../../../shared/widgets/admin/admin_toast.dart';
import '../../data/admin_repository.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  DateTime? _from;
  DateTime? _to;
  OrdersReport? _ordersReport;
  RevenueReport? _revenueReport;
  List<TopProductReport> _topProducts = [];
  Object? _error;
  bool _loading = false;

  String? get _fromIso => _from?.toIso8601String().split('T').first;
  String? get _toIso => _to?.toIso8601String().split('T').first;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(adminRepositoryProvider);
      final results = await Future.wait([
        repo.ordersReportTyped(fromDate: _fromIso, toDate: _toIso),
        repo.revenueReportTyped(fromDate: _fromIso, toDate: _toIso),
        repo.topProductsReportTyped(fromDate: _fromIso, toDate: _toIso),
      ]);
      if (!mounted) return;
      setState(() {
        _ordersReport = results[0] as OrdersReport;
        _revenueReport = results[1] as RevenueReport;
        _topProducts = results[2] as List<TopProductReport>;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _export(String type) async {
    try {
      final csv = await ref.read(adminRepositoryProvider).exportReport(
            type,
            fromDate: _fromIso,
            toDate: _toIso,
          );
      await downloadCsv('$type-report.csv', csv);
      if (mounted) AdminToast.success(context, '$type report downloaded');
    } catch (e) {
      if (mounted) AdminToast.error(context, AdminApiUtils.dioMessage(e));
    }
  }

  @override
  void initState() {
    super.initState();
    _from = DateTime.now().subtract(const Duration(days: 30));
    _to = DateTime.now();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');

    return AdminPageLayout(
      title: 'Reports',
      subtitle: 'Revenue, orders, and product performance',
      actions: [
        PopupMenuButton<String>(
          onSelected: _export,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'orders', child: Text('Export orders CSV')),
            PopupMenuItem(value: 'revenue', child: Text('Export revenue CSV')),
            PopupMenuItem(value: 'products', child: Text('Export products CSV')),
          ],
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.download_outlined, size: 18),
                SizedBox(width: 6),
                Text('Export'),
              ],
            ),
          ),
        ),
      ],
      filters: Wrap(
        spacing: AdminSpacing.sm,
        runSpacing: AdminSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _from ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _from = d);
            },
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text('From ${ _from != null ? fmt.format(_from!) : '—'}'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _to ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _to = d);
            },
            icon: const Icon(Icons.calendar_today, size: 16),
            label: Text('To ${_to != null ? fmt.format(_to!) : '—'}'),
          ),
          FilledButton(onPressed: _load, child: const Text('Apply')),
        ],
      ),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const AdminLoadingState(message: 'Generating reports…');
    }
    if (_error != null) {
      return AdminErrorState(
        error: _error!,
        title: 'Could not load reports',
        onRetry: _load,
      );
    }

    final orders = _ordersReport;
    final revenue = _revenueReport;
    if (orders == null || revenue == null) {
      return const AdminEmptyState(
        title: 'No report data',
        message: 'Select a date range and apply to generate reports.',
        icon: Icons.analytics_outlined,
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExecutiveInsights(
            orders: orders,
            revenue: revenue,
            topProducts: _topProducts,
          ),
          const SizedBox(height: AdminSpacing.lg),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 900 ? 4 : (c.maxWidth > 500 ? 2 : 1);
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cols,
                crossAxisSpacing: AdminSpacing.md,
                mainAxisSpacing: AdminSpacing.md,
                childAspectRatio: 2.6,
                children: [
                  AdminStatCard(
                    title: 'Total orders',
                    value: '${orders.totalOrders}',
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.navyBlue,
                    compact: true,
                  ),
                  AdminStatCard(
                    title: 'Order revenue',
                    value: '₹${orders.totalRevenue.toStringAsFixed(0)}',
                    icon: Icons.currency_rupee,
                    color: AppColors.primaryGreen,
                    compact: true,
                  ),
                  AdminStatCard(
                    title: 'Days with sales',
                    value: '${revenue.byDay.length}',
                    icon: Icons.calendar_month_outlined,
                    color: AppColors.navyBlue,
                    compact: true,
                  ),
                  AdminStatCard(
                    title: 'Period revenue',
                    value: '₹${revenue.totalRevenue.toStringAsFixed(0)}',
                    icon: Icons.trending_up,
                    color: AppColors.orangeAccent,
                    compact: true,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AdminSpacing.xxl),
          Text('Top products', style: AdminTypography.sectionTitle(context)),
          const SizedBox(height: AdminSpacing.md),
          if (_topProducts.isEmpty)
            const AdminEmptyState(
              title: 'No product sales',
              message: 'No orders in this date range.',
              icon: Icons.shopping_bag_outlined,
            )
          else
            ..._topProducts.map((p) => _TopProductRow(product: p)),
          const SizedBox(height: AdminSpacing.lg),
          _ExportCenter(onExport: _export),
        ],
      ),
    );
  }
}

List<String> buildReportInsights({
  required OrdersReport orders,
  required RevenueReport revenue,
  required List<TopProductReport> topProducts,
}) {
  final insights = <String>[];
  final days = revenue.byDay;
  if (days.length >= 4) {
    final mid = days.length ~/ 2;
    final firstHalf = days.sublist(0, mid).fold<double>(0, (s, d) => s + d.revenue);
    final secondHalf = days.sublist(mid).fold<double>(0, (s, d) => s + d.revenue);
    if (firstHalf > 0) {
      final pct = ((secondHalf - firstHalf) / firstHalf * 100).round();
      if (pct.abs() >= 3) {
        insights.add(
          pct >= 0
              ? 'Revenue up $pct% in the second half of this period'
              : 'Revenue down ${pct.abs()}% in the second half of this period',
        );
      }
    }
  }
  if (orders.totalOrders > 0) {
    insights.add(
      'Average order value ₹${(orders.totalRevenue / orders.totalOrders).toStringAsFixed(0)}',
    );
  }
  if (topProducts.isNotEmpty) {
    insights.add(
      '${topProducts.first.productName} dominates sales (${topProducts.first.quantitySold} units)',
    );
  }
  if (insights.isEmpty) {
    insights.add('Apply a date range to generate period-over-period insights');
  }
  return insights;
}

class _ExecutiveInsights extends StatelessWidget {
  const _ExecutiveInsights({
    required this.orders,
    required this.revenue,
    required this.topProducts,
  });

  final OrdersReport orders;
  final RevenueReport revenue;
  final List<TopProductReport> topProducts;

  @override
  Widget build(BuildContext context) {
    final insights = buildReportInsights(
      orders: orders,
      revenue: revenue,
      topProducts: topProducts,
    );

    return Container(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.navyBlue.withValues(alpha: 0.06),
            AppColors.primaryGreen.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        border: Border.all(color: AdminSemanticColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 18, color: AppColors.primaryGreen),
              const SizedBox(width: AdminSpacing.sm),
              Text('Executive insights', style: AdminTypography.sectionTitle(context)),
              const Spacer(),
              Text(
                '₹${revenue.totalRevenue.toStringAsFixed(0)} period revenue',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AdminSpacing.md),
          ...insights.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppColors.primaryGreen)),
                  Expanded(child: Text(s, style: const TextStyle(fontSize: 12))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportCenter extends StatelessWidget {
  const _ExportCenter({required this.onExport});

  final void Function(String type) onExport;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Export center', style: AdminTypography.sectionTitle(context)),
        const SizedBox(height: AdminSpacing.sm),
        Wrap(
          spacing: AdminSpacing.md,
          runSpacing: AdminSpacing.md,
          children: [
            _ExportTile(title: 'Orders CSV', icon: Icons.receipt_long_outlined, onTap: () => onExport('orders')),
            _ExportTile(title: 'Revenue CSV', icon: Icons.payments_outlined, onTap: () => onExport('revenue')),
            _ExportTile(title: 'Products CSV', icon: Icons.inventory_2_outlined, onTap: () => onExport('products')),
            _ExportTile(
              title: 'PDF report',
              icon: Icons.picture_as_pdf_outlined,
              onTap: () {},
              subtitle: 'Coming soon',
            ),
            _ExportTile(
              title: 'Scheduled export',
              icon: Icons.schedule_send_outlined,
              onTap: () {},
              subtitle: 'Coming soon',
            ),
          ],
        ),
      ],
    );
  }
}

class _TopProductRow extends StatelessWidget {
  const _TopProductRow({required this.product});

  final TopProductReport product;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AdminSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AdminSpacing.lg,
        vertical: AdminSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AdminSemanticColors.border),
        borderRadius: BorderRadius.circular(AdminRadius.sm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              product.productName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '${product.quantitySold} sold',
            style: const TextStyle(
              fontSize: 12,
              color: AdminSemanticColors.textSecondary,
            ),
          ),
          const SizedBox(width: AdminSpacing.lg),
          Text(
            '₹${product.revenue.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _ExportTile extends StatelessWidget {
  const _ExportTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle = 'Download CSV',
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AdminRadius.md),
      child: Ink(
        width: 140,
        padding: const EdgeInsets.all(AdminSpacing.lg),
        decoration: BoxDecoration(
          border: Border.all(color: AdminSemanticColors.border),
          borderRadius: BorderRadius.circular(AdminRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: AppColors.primaryGreen),
            const SizedBox(height: AdminSpacing.sm),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: AdminSemanticColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
