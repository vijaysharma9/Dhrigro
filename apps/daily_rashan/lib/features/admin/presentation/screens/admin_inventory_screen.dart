import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/admin/admin_data_table.dart';
import '../../../../shared/widgets/admin/admin_search_bar.dart';
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
  final _bulkStockCtrl = TextEditingController();

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
    _bulkStockCtrl.dispose();
    super.dispose();
  }

  Future<void> _editStock(Map<String, dynamic> product) async {
    final stockCtrl = TextEditingController(
      text: '${product['stock'] ?? 0}',
    );
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
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
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
    final lowStockCount = inventoryAsync.valueOrNull?['meta']?['lowStockCount'];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Inventory', style: Theme.of(context).textTheme.headlineSmall),
              if (lowStockCount != null) ...[
                const SizedBox(width: 12),
                Chip(
                  label: Text('$lowStockCount low stock'),
                  backgroundColor: AppColors.orangeAccent.withValues(alpha: 0.15),
                ),
              ],
              const Spacer(),
              FilterChip(
                label: const Text('Low stock only'),
                selected: query.lowStock,
                onSelected: (v) {
                  ref.read(adminInventoryQueryProvider.notifier).update(
                        (s) => s.copyWith(lowStock: v, page: 1),
                      );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          AdminSearchBar(hint: 'Search products', onChanged: _debouncedSearch),
          const SizedBox(height: 16),
          Expanded(
            child: inventoryAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (res) {
                final rows = (res['data'] as List? ?? [])
                    .cast<Map<String, dynamic>>();
                final meta = res['meta'] as Map<String, dynamic>? ?? {};

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: AdminDataTable<Map<String, dynamic>>(
                          columns: [
                            AdminColumn(
                              label: 'Product',
                              flex: 3,
                              cellBuilder: (p) => Text(
                                p['name'] as String? ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            AdminColumn(
                              label: 'Stock',
                              cellBuilder: (p) {
                                final stock = p['stock'] as int? ?? 0;
                                final low = stock <= 10;
                                return Text(
                                  '$stock',
                                  style: TextStyle(
                                    color: low ? AppColors.orangeAccent : null,
                                    fontWeight: low ? FontWeight.bold : null,
                                  ),
                                );
                              },
                            ),
                            AdminColumn(
                              label: 'Status',
                              cellBuilder: (p) {
                                final active = p['isActive'] as bool? ?? true;
                                return Text(active ? 'Available' : 'Hidden');
                              },
                            ),
                            AdminColumn(
                              label: '',
                              cellBuilder: (p) => IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _editStock(p),
                              ),
                            ),
                          ],
                          rows: rows,
                        ),
                      ),
                    ),
                    AdminPaginationBar(
                      page: meta['page'] as int? ?? 1,
                      totalPages: meta['totalPages'] as int? ?? 1,
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
          ),
        ],
      ),
    );
  }
}
