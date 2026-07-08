import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/admin/admin_api_utils.dart';
import '../../../../core/admin/admin_theme.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/admin/admin_data_table.dart';
import '../../../../shared/widgets/admin/admin_page_layout.dart';
import '../../../../shared/widgets/admin/admin_search_bar.dart';
import '../../../../shared/widgets/admin/admin_state_widgets.dart';
import '../../../../shared/widgets/admin/admin_stat_card.dart';
import '../../../../shared/widgets/admin/admin_toast.dart';
import '../../data/admin_repository.dart';
import '../providers/admin_providers.dart';

class AdminInventoryScreen extends ConsumerStatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  ConsumerState<AdminInventoryScreen> createState() =>
      _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends ConsumerState<AdminInventoryScreen> {
  late final DebouncedSearch _debouncedSearch;

  @override
  void initState() {
    super.initState();
    _debouncedSearch = DebouncedSearch((q) {
      ref.read(adminInventoryQueryProvider.notifier).update(
            (s) => s.copyWith(search: q, page: 1),
          );
    });
  }

  @override
  void dispose() {
    _debouncedSearch.dispose();
    super.dispose();
  }

  Future<void> _editStock(Map<String, dynamic> product) async {
    final stockCtrl = TextEditingController(text: '${product['stock'] ?? 0}');
    var isActive = product['isActive'] as bool? ?? true;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(product['name'] as String? ?? 'Update stock'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Stock quantity'),
              ),
              SwitchListTile(
                title: const Text('Available'),
                value: isActive,
                onChanged: (v) => setLocal(() => isActive = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (ok == true) {
      await ref.read(adminRepositoryProvider).updateStock(
            product['id'] as String,
            stock: int.tryParse(stockCtrl.text) ?? 0,
            isActive: isActive,
          );
      ref.invalidate(adminInventoryListProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(adminInventoryListProvider);
    final query = ref.watch(adminInventoryQueryProvider);

    return AdminPageLayout(
      title: 'Inventory',
      subtitle: 'Stock levels and SKU health',
      actions: [
        OutlinedButton.icon(
          onPressed: () => AdminToast.info(context, 'CSV bulk upload coming soon'),
          icon: const Icon(Icons.upload_file_outlined, size: 18),
          label: const Text('Bulk CSV'),
        ),
      ],
      filters: AdminFiltersToolbar(
        children: [
          SizedBox(
            width: 280,
            child: AdminSearchBar(hint: 'Search SKU or product', onChanged: _debouncedSearch),
          ),
          FilterChip(
            label: const Text('Low stock only'),
            selected: query.lowStock,
            onSelected: (v) {
              ref.read(adminInventoryQueryProvider.notifier).update(
                    (s) => s.copyWith(lowStock: v, page: 1),
                  );
            },
          ),
          FilterChip(
            label: const Text('Fast movers'),
            selected: query.fastMoving,
            onSelected: (v) {
              ref.read(adminInventoryQueryProvider.notifier).update(
                    (s) => s.copyWith(fastMoving: v, page: 1),
                  );
            },
          ),
        ],
      ),
      child: inventoryAsync.when(
        loading: () => const AdminLoadingState(message: 'Loading inventory…'),
        error: (e, _) => AdminErrorState(
          error: e,
          title: 'Could not load inventory',
          onRetry: () => ref.invalidate(adminInventoryListProvider),
        ),
        data: (res) {
          final rows = AdminApiUtils.asMapList(res['data']);
          final meta = AdminApiUtils.asMap(res['meta'], context: 'inventory.meta');
          final total = meta['total'] as int? ?? rows.length;
          final lowCount = meta['lowStockCount'] as int? ??
              rows.where((p) => (p['stock'] as int? ?? 0) <= 10).length;
          final outCount = rows.where((p) => (p['stock'] as int? ?? 0) <= 0).length;
          final hiddenCount = rows.where((p) => p['isActive'] != true).length;

          if (rows.isEmpty && !query.lowStock && query.search.isEmpty) {
            return const AdminEmptyState(
              title: 'No inventory records',
              message: 'Products will appear here once added to catalog.',
              icon: Icons.warehouse_outlined,
            );
          }

          return Column(
            children: [
              LayoutBuilder(
                builder: (context, c) {
                  final cols = c.maxWidth > 900 ? 4 : 2;
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: cols,
                    crossAxisSpacing: AdminSpacing.md,
                    mainAxisSpacing: AdminSpacing.md,
                    childAspectRatio: 2.8,
                    children: [
                      AdminStatCard(
                        title: 'Total SKUs',
                        value: '$total',
                        icon: Icons.inventory_2_outlined,
                        color: AppColors.navyBlue,
                        compact: true,
                      ),
                      AdminStatCard(
                        title: 'Low stock',
                        value: '$lowCount',
                        icon: Icons.warning_amber_rounded,
                        color: AdminSemanticColors.warning,
                        compact: true,
                      ),
                      AdminStatCard(
                        title: 'Out of stock',
                        value: '$outCount',
                        icon: Icons.remove_shopping_cart_outlined,
                        color: AppColors.errorRed,
                        compact: true,
                      ),
                      AdminStatCard(
                        title: 'Hidden',
                        value: '$hiddenCount',
                        icon: Icons.visibility_off_outlined,
                        color: AdminSemanticColors.textSecondary,
                        compact: true,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AdminSpacing.lg),
              Expanded(
                child: AdminDataTable<Map<String, dynamic>>(
                  virtualized: true,
                  columns: [
                    AdminColumn(
                      label: 'Product',
                      flex: 3,
                      cellBuilder: (p) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['name'] as String? ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          if (p['sku'] != null)
                            Text(
                              p['sku'] as String,
                              style: const TextStyle(fontSize: 10, color: AdminSemanticColors.textMuted),
                            ),
                        ],
                      ),
                    ),
                    AdminColumn(
                      label: 'Stock health',
                      flex: 2,
                      cellBuilder: (p) => _StockHealthBar(stock: p['stock'] as int? ?? 0),
                    ),
                    AdminColumn(
                      label: 'Qty',
                      cellBuilder: (p) {
                        final stock = p['stock'] as int? ?? 0;
                        return Text(
                          '$stock',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: stock <= 0
                                ? AppColors.errorRed
                                : stock <= 10
                                    ? AdminSemanticColors.warning
                                    : null,
                          ),
                        );
                      },
                    ),
                    AdminColumn(
                      label: 'Status',
                      cellBuilder: (p) {
                        final active = p['isActive'] as bool? ?? true;
                        return Chip(
                          label: Text(active ? 'Live' : 'Hidden', style: const TextStyle(fontSize: 10)),
                          visualDensity: VisualDensity.compact,
                          backgroundColor: (active ? AppColors.primaryGreen : AppColors.errorRed)
                              .withValues(alpha: 0.1),
                        );
                      },
                    ),
                    AdminColumn(
                      label: '',
                      cellBuilder: (p) => IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () => _editStock(p),
                      ),
                    ),
                  ],
                  rows: rows,
                  onRowTap: _editStock,
                ),
              ),
              AdminPaginationBar(
                page: meta['page'] as int? ?? 1,
                totalPages: meta['totalPages'] as int? ?? 1,
                totalItems: total,
                onPageChanged: (p) {
                  ref.read(adminInventoryQueryProvider.notifier).update(
                        (s) => s.copyWith(page: p),
                      );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StockHealthBar extends StatelessWidget {
  const _StockHealthBar({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    const maxStock = 100;
    final pct = (stock / maxStock).clamp(0.0, 1.0);
    final color = stock <= 0
        ? AppColors.errorRed
        : stock <= 10
            ? AdminSemanticColors.warning
            : AppColors.primaryGreen;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AdminRadius.pill),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: AdminSemanticColors.borderSubtle,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          stock <= 0 ? 'Critical' : stock <= 10 ? 'Low' : 'OK',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
        ),
      ],
    );
  }
}
