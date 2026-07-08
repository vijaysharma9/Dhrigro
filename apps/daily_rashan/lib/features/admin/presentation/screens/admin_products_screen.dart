import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/admin/admin_theme.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/csv_download.dart';
import '../../../../shared/widgets/admin/admin_data_table.dart';
import '../../../../shared/widgets/admin/admin_ops_widgets.dart';
import '../../../../shared/widgets/admin/admin_page_layout.dart';
import '../../../../shared/widgets/admin/admin_search_bar.dart';
import '../../../../shared/widgets/admin/admin_state_widgets.dart';
import '../../../../shared/widgets/admin/admin_toast.dart';
import '../../data/admin_repository.dart';
import '../providers/admin_providers.dart';
import '../utils/admin_product_import.dart';
import 'admin_product_form_screen.dart';

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  late final DebouncedSearch _debouncedSearch;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _debouncedSearch = DebouncedSearch((q) {
      ref.read(adminProductsQueryProvider.notifier).update(
            (s) => s.copyWith(search: q, page: 1),
          );
    });
  }

  @override
  void dispose() {
    _debouncedSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(adminProductsProvider);
    final query = ref.watch(adminProductsQueryProvider);
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return AdminPageLayout(
      title: 'Products',
      subtitle: 'Manage catalog, pricing, and availability',
      actions: [
        OutlinedButton.icon(
          onPressed: _importing ? null : () => _downloadTemplate(context),
          icon: const Icon(Icons.download_outlined, size: 18),
          label: const Text('Template'),
        ),
        const SizedBox(width: AdminSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _showDuplicates(context),
          icon: const Icon(Icons.copy_all_outlined, size: 18),
          label: const Text('Duplicates'),
        ),
        const SizedBox(width: AdminSpacing.sm),
        OutlinedButton.icon(
          onPressed: _importing ? null : () => _importProducts(context),
          icon: _importing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file_outlined, size: 18),
          label: Text(_importing ? 'Importing…' : 'Import'),
        ),
        const SizedBox(width: AdminSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => ref.invalidate(adminProductsProvider),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Refresh'),
        ),
        const SizedBox(width: AdminSpacing.sm),
        FilledButton.icon(
          onPressed: () => _openForm(context),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add product'),
        ),
      ],
      filters: AdminFiltersToolbar(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
            child: AdminSearchBar(
              hint: 'Search products…',
              onChanged: _debouncedSearch,
            ),
          ),
          categoriesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (cats) => ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 140, maxWidth: 180),
              child: DropdownButtonFormField<String?>(
                isExpanded: true,
                value: query.categoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All categories')),
                  ...cats.map(
                    (c) => DropdownMenuItem(
                      value: c['id'] as String?,
                      child: Text(
                        c['name'] as String? ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => ref.read(adminProductsQueryProvider.notifier).update(
                      (s) => s.copyWith(categoryId: v, page: 1),
                    ),
              ),
            ),
          ),
          FilterChip(
            label: const Text('Featured only'),
            selected: query.isFeatured == true,
            onSelected: (v) => ref.read(adminProductsQueryProvider.notifier).update(
                  (s) => s.copyWith(
                    isFeatured: v ? true : null,
                    clearFeatured: !v,
                    page: 1,
                  ),
                ),
          ),
        ],
      ),
      child: productsAsync.when(
        loading: () => const AdminLoadingState(message: 'Loading products…'),
        error: (e, _) => AdminErrorState(
          error: e,
          title: 'Could not load products',
          onRetry: () => ref.invalidate(adminProductsProvider),
        ),
        data: (page) {
          if (page.data.isEmpty) {
            return AdminEmptyState(
              title: 'No products found',
              message: query.search.isNotEmpty
                  ? 'Try a different search term or clear filters.'
                  : 'Add your first product to get started.',
              icon: Icons.inventory_2_outlined,
              actionLabel: 'Add product',
              onAction: () => _openForm(context),
            );
          }

          return Column(
            children: [
              Expanded(
                child: AdminDataTable<Map<String, dynamic>>(
                  virtualized: true,
                  columns: [
                    AdminColumn(
                      label: 'Product',
                      flex: 3,
                      cellBuilder: (p) => Row(
                        children: [
                          _ProductAvatar(product: p),
                          const SizedBox(width: AdminSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['name'] as String? ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  p['category']?['name'] as String? ?? '—',
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
                      label: 'Price',
                      cellBuilder: (p) => _EditablePriceCell(
                        key: ValueKey('price-${p['id']}'),
                        product: p,
                        onUpdate: (id, value) async {
                          await ref
                              .read(adminRepositoryProvider)
                              .updateProduct(id, {'basePrice': value});
                        },
                      ),
                    ),
                    AdminColumn(
                      label: 'Stock',
                      cellBuilder: (p) {
                        final stock = p['stock'] as int? ?? 0;
                        final color = stock <= 0
                            ? AppColors.errorRed
                            : stock <= 10
                                ? AdminSemanticColors.warning
                                : AppColors.primaryGreen;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text('$stock'),
                          ],
                        );
                      },
                    ),
                    AdminColumn(
                      label: 'Status',
                      cellBuilder: (p) {
                        final active = p['isActive'] == true;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (active ? AppColors.primaryGreen : AppColors.errorRed)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AdminRadius.pill),
                          ),
                          child: Text(
                            active ? 'Active' : 'Hidden',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: active ? AppColors.primaryGreen : AppColors.errorRed,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  rows: page.data,
                  onRowTap: (p) => _openForm(context, productId: p['id'] as String?),
                ),
              ),
              if (page.totalPages > 1)
                AdminPaginationBar(
                  page: page.page,
                  totalPages: page.totalPages,
                  totalItems: page.total,
                  onPageChanged: (p) =>
                      ref.read(adminProductsQueryProvider.notifier).update(
                            (s) => s.copyWith(page: p),
                          ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _downloadTemplate(BuildContext context) async {
    await downloadCsv('product-import-template.csv', AdminProductImport.templateCsv);
    if (mounted) {
      AdminToast.success(
        context,
        'Template downloaded (or copied to clipboard on mobile)',
      );
    }
  }

  Future<void> _importProducts(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    List<Map<String, dynamic>> rows;
    try {
      rows = await AdminProductImport.parseFile(result.files.first);
    } catch (e) {
      if (mounted) AdminToast.errorFrom(context, e);
      return;
    }

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import products'),
        content: Text(
          'Import ${rows.length} product${rows.length == 1 ? '' : 's'} from '
          '"${result.files.first.name}"?\n\n'
          'Existing products are updated when SKU matches, or when the same '
          'name exists in the same category. New rows are only created when no '
          'match is found.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Import')),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    setState(() => _importing = true);
    try {
      final summary = await ref.read(adminRepositoryProvider).importProducts(
            rows,
            matchBy: 'sku_or_name',
          );
      ref.invalidate(adminProductsProvider);
      if (!mounted) return;

      final created = summary['created'] as int? ?? 0;
      final updated = summary['updated'] as int? ?? 0;
      final failed = summary['failed'] as int? ?? 0;
      final errors = summary['errors'] as List? ?? [];

      if (failed == 0) {
        AdminToast.success(context, 'Imported $created new, updated $updated');
      } else {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Import completed with errors'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Created: $created · Updated: $updated · Failed: $failed'),
                  if (errors.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Errors:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: errors.take(8).map((e) {
                          final map = e is Map ? e : <String, dynamic>{};
                          final row = map['row'];
                          final message = map['message'] ?? 'Unknown error';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('Row $row: $message', style: const TextStyle(fontSize: 12)),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) AdminToast.errorFrom(context, e);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _openForm(BuildContext context, {String? productId}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminProductFormScreen(productId: productId),
      ),
    );
    ref.invalidate(adminProductsProvider);
    if (mounted) AdminToast.success(context, productId == null ? 'Product saved' : 'Product updated');
  }

  Future<void> _showDuplicates(BuildContext context) async {
    try {
      final data = await ref.read(adminRepositoryProvider).getDuplicateProducts();
      if (!mounted) return;

      final groups = (data['groups'] as List? ?? []).cast<Map<String, dynamic>>();
      if (groups.isEmpty) {
        AdminToast.success(context, 'No duplicate products found');
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (ctx) => _DuplicateProductsDialog(
          groups: groups,
          totalExtras: data['totalDuplicateProducts'] as int? ?? 0,
          onResolve: (keepId, removeIds) async {
            await ref.read(adminRepositoryProvider).resolveDuplicateProducts(
                  keepId: keepId,
                  removeIds: removeIds,
                );
            ref.invalidate(adminProductsProvider);
          },
        ),
      );
    } catch (e) {
      if (mounted) AdminToast.errorFrom(context, e);
    }
  }
}

class _ProductAvatar extends StatelessWidget {
  const _ProductAvatar({required this.product});

  final Map<String, dynamic> product;

  @override
  Widget build(BuildContext context) {
    final images = product['images'] as List?;
    final thumb = images?.isNotEmpty == true ? images!.first as String? : null;
    return AdminAvatar(
      name: product['name'] as String?,
      imageUrl: thumb,
      size: 36,
    );
  }
}

/// Inline-editable price cell. Tapping the price turns it into a compact
/// numeric field so rates can be changed on the spot without opening the form.
class _EditablePriceCell extends StatefulWidget {
  const _EditablePriceCell({
    super.key,
    required this.product,
    required this.onUpdate,
  });

  final Map<String, dynamic> product;
  final Future<void> Function(String id, num value) onUpdate;

  @override
  State<_EditablePriceCell> createState() => _EditablePriceCellState();
}

class _EditablePriceCellState extends State<_EditablePriceCell> {
  bool _editing = false;
  bool _saving = false;
  bool _hover = false;
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  String get _priceText => '${widget.product['basePrice'] ?? ''}';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _priceText);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEdit() {
    _controller.text = _priceText;
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final value = double.tryParse(_controller.text.trim());
    if (value == null || value < 0) {
      AdminToast.error(context, 'Enter a valid price');
      return;
    }
    final current = double.tryParse(_priceText);
    if (current != null && current == value) {
      setState(() => _editing = false);
      return;
    }

    setState(() => _saving = true);
    try {
      final id = widget.product['id'] as String;
      final normalized = value % 1 == 0 ? value.toInt() : value;
      await widget.onUpdate(id, normalized);
      widget.product['basePrice'] = normalized;
      if (!mounted) return;
      setState(() {
        _editing = false;
        _saving = false;
      });
      AdminToast.success(context, 'Price updated to ₹$normalized');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AdminToast.errorFrom(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_editing) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 96,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !_saving,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                decoration: const InputDecoration(
                  prefixText: '₹',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 4),
            if (_saving)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              _IconAction(
                icon: Icons.check,
                color: AppColors.primaryGreen,
                tooltip: 'Save',
                onTap: _save,
              ),
              _IconAction(
                icon: Icons.close,
                color: AdminSemanticColors.textMuted,
                tooltip: 'Cancel',
                onTap: () => setState(() => _editing = false),
              ),
            ],
          ],
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _startEdit,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '₹${widget.product['basePrice']}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.edit_outlined,
              size: 14,
              color: _hover
                  ? AppColors.primaryGreen
                  : AdminSemanticColors.textMuted.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AdminRadius.sm),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class _DuplicateProductsDialog extends StatefulWidget {
  const _DuplicateProductsDialog({
    required this.groups,
    required this.totalExtras,
    required this.onResolve,
  });

  final List<Map<String, dynamic>> groups;
  final int totalExtras;
  final Future<void> Function(String keepId, List<String> removeIds) onResolve;

  @override
  State<_DuplicateProductsDialog> createState() =>
      _DuplicateProductsDialogState();
}

class _DuplicateProductsDialogState extends State<_DuplicateProductsDialog> {
  bool _working = false;

  Future<void> _mergeGroup(Map<String, dynamic> group) async {
    final products =
        (group['products'] as List? ?? []).cast<Map<String, dynamic>>();
    if (products.length < 2) return;

    // Keep the most recently updated row; retire the rest.
    products.sort((a, b) {
      final aTime = DateTime.tryParse('${a['updatedAt']}') ?? DateTime(1970);
      final bTime = DateTime.tryParse('${b['updatedAt']}') ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });

    final keep = products.first;
    final removeIds = products.skip(1).map((p) => p['id'] as String).toList();

    setState(() => _working = true);
    try {
      await widget.onResolve(keep['id'] as String, removeIds);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Merged ${group['name']}: kept 1, removed ${removeIds.length}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Duplicate products'),
      content: SizedBox(
        width: 520,
        height: 420,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.totalExtras} extra listing(s) found across '
              '${widget.groups.length} product name(s).',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: widget.groups.length,
                itemBuilder: (_, i) {
                  final group = widget.groups[i];
                  final products =
                      (group['products'] as List? ?? []).cast<Map<String, dynamic>>();
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ExpansionTile(
                      title: Text(
                        '${group['name']} (${group['count']} listings)',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      children: [
                        for (final p in products)
                          ListTile(
                            dense: true,
                            title: Text(
                              '₹${p['basePrice']} · SKU: ${p['sku'] ?? '—'}',
                            ),
                            subtitle: Text(
                              '${p['category']?['name'] ?? '—'} · stock ${p['stock']}',
                            ),
                          ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _working ? null : () => _mergeGroup(group),
                            icon: const Icon(Icons.merge_type, size: 18),
                            label: const Text('Keep latest, remove others'),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _working ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
