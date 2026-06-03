import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/csv_download.dart';
import '../../../../shared/widgets/admin/admin_stat_card.dart';
import '../../data/admin_repository.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  DateTime? _from;
  DateTime? _to;
  Map<String, dynamic>? _ordersReport;
  Map<String, dynamic>? _revenueReport;
  List<dynamic>? _topProducts;
  bool _loading = false;

  String? get _fromIso => _from?.toIso8601String().split('T').first;
  String? get _toIso => _to?.toIso8601String().split('T').first;

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final orders = await repo.ordersReport(fromDate: _fromIso, toDate: _toIso);
      final revenue = await repo.revenueReport(fromDate: _fromIso, toDate: _toIso);
      final top = await repo.topProductsReport(fromDate: _fromIso, toDate: _toIso);
      setState(() {
        _ordersReport = orders;
        _revenueReport = revenue;
        _topProducts = top;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _export(String type) async {
    final csv = await ref.read(adminRepositoryProvider).exportReport(
          type,
          fromDate: _fromIso,
          toDate: _toIso,
        );
    await downloadCsv('$type-report.csv', csv);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$type report downloaded')),
      );
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

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reports', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _from ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _from = d);
                },
                child: Text('From: ${_from != null ? fmt.format(_from!) : '—'}'),
              ),
              OutlinedButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _to ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _to = d);
                },
                child: Text('To: ${_to != null ? fmt.format(_to!) : '—'}'),
              ),
              FilledButton(onPressed: _load, child: const Text('Apply')),
              PopupMenuButton<String>(
                onSelected: _export,
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'orders', child: Text('Export orders CSV')),
                  PopupMenuItem(value: 'revenue', child: Text('Export revenue CSV')),
                  PopupMenuItem(value: 'customers', child: Text('Export customers CSV')),
                  PopupMenuItem(value: 'products', child: Text('Export products CSV')),
                  PopupMenuItem(value: 'coupons', child: Text('Export coupons CSV')),
                ],
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download),
                      SizedBox(width: 8),
                      Text('Export CSV'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, c) {
                        final cols = c.maxWidth > 900 ? 4 : 2;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: cols,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.6,
                          children: [
                            AdminStatCard(
                              title: 'Total orders',
                              value: '${_ordersReport?['totalOrders'] ?? 0}',
                              icon: Icons.receipt_long,
                              color: AppColors.navyBlue,
                            ),
                            AdminStatCard(
                              title: 'Order revenue',
                              value: '₹${_ordersReport?['totalRevenue'] ?? 0}',
                              icon: Icons.check_circle,
                              color: AppColors.primaryGreen,
                            ),
                            AdminStatCard(
                              title: 'Daily breakdown',
                              value: '${(_revenueReport?['byDay'] as Map?)?.length ?? 0} days',
                              icon: Icons.calendar_month,
                              color: AppColors.navyBlue,
                            ),
                            AdminStatCard(
                              title: 'Period revenue',
                              value: '₹${_revenueReport?['summary']?['totalRevenue'] ?? 0}',
                              icon: Icons.currency_rupee,
                              color: AppColors.orangeAccent,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Text('Top products', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    ...(_topProducts ?? []).map((p) {
                      final item = p as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          title: Text(item['productName'] as String? ?? ''),
                          trailing: Text('Sold: ${item['quantitySold'] ?? item['_sum']?['quantity'] ?? 0}'),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
