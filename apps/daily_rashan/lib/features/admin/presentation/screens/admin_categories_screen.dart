import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/admin/admin_api_utils.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/category_icons.dart';
import '../../../../shared/widgets/admin/admin_state_widgets.dart';
import '../../data/admin_repository.dart';
import '../providers/admin_providers.dart';

/// Master-data management for categories & subcategories:
/// create, edit, disable, reorder (drag & drop), assign icon/colour/image,
/// manage subcategories and view product counts.
class AdminCategoriesScreen extends ConsumerStatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  ConsumerState<AdminCategoriesScreen> createState() =>
      _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends ConsumerState<AdminCategoriesScreen> {
  bool _saving = false;

  void _refresh() {
    ref.invalidate(adminCategoriesProvider);
    ref.invalidate(adminCategoryAnalyticsProvider);
  }

  Future<void> _openEditor({
    Map<String, dynamic>? category,
    String? parentId,
    String? parentName,
  }) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _CategoryEditorDialog(
        category: category,
        parentId: parentId,
        parentName: parentName,
      ),
    );
    if (result == null) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (category == null) {
        await repo.createCategory(result);
      } else {
        await repo.updateCategory(category['id'] as String, result);
      }
      _refresh();
      _toast(category == null ? 'Category created' : 'Category updated');
    } catch (e) {
      _toast(AdminApiUtils.dioMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> category) async {
    final active = category['isActive'] as bool? ?? true;
    try {
      await ref.read(adminRepositoryProvider).updateCategory(
        category['id'] as String,
        {'isActive': !active},
      );
      _refresh();
    } catch (e) {
      _toast(AdminApiUtils.dioMessage(e));
    }
  }

  Future<void> _delete(Map<String, dynamic> category) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category?'),
        content: Text(
          'Delete "${category['name']}"? Products keep their data but the '
          'category is retired.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(adminRepositoryProvider)
          .deleteCategory(category['id'] as String);
      _refresh();
      _toast('Category deleted');
    } catch (e) {
      _toast(AdminApiUtils.dioMessage(e));
    }
  }

  Future<void> _reorder(List<Map<String, dynamic>> ordered) async {
    final items = <Map<String, dynamic>>[
      for (var i = 0; i < ordered.length; i++)
        {'id': ordered[i]['id'], 'sortOrder': i + 1},
    ];
    try {
      await ref.read(adminRepositoryProvider).reorderCategories(items);
      _refresh();
    } catch (e) {
      _toast(AdminApiUtils.dioMessage(e));
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openAnalytics() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CategoryAnalyticsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return Stack(
      children: [
        categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AdminErrorState(
            error: e,
            title: 'Could not load categories',
            onRetry: _refresh,
          ),
          data: (categories) => _buildList(context, categories),
        ),
        if (_saving)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x11000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildList(
    BuildContext context,
    List<Map<String, dynamic>> categories,
  ) {
    final mutable = List<Map<String, dynamic>>.from(categories);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Categories',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              OutlinedButton.icon(
                onPressed: _openAnalytics,
                icon: const Icon(Icons.insights),
                label: const Text('Analytics'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _openEditor(),
                icon: const Icon(Icons.add),
                label: const Text('New category'),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: _CategoryAnalyticsStrip(),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            itemCount: mutable.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = mutable.removeAt(oldIndex);
                mutable.insert(newIndex, item);
              });
              _reorder(mutable);
            },
            itemBuilder: (context, index) {
              final cat = mutable[index];
              return _CategoryTile(
                key: ValueKey(cat['id']),
                category: cat,
                index: index,
                onEdit: () => _openEditor(category: cat),
                onAddSub: () => _openEditor(
                  parentId: cat['id'] as String,
                  parentName: cat['name'] as String?,
                ),
                onEditSub: (sub) => _openEditor(
                  category: sub,
                  parentId: cat['id'] as String,
                  parentName: cat['name'] as String?,
                ),
                onDeleteSub: _delete,
                onToggleActive: () => _toggleActive(cat),
                onDelete: () => _delete(cat),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryAnalyticsStrip extends ConsumerWidget {
  const _CategoryAnalyticsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminCategoryAnalyticsProvider);
    return async.maybeWhen(
      data: (data) {
        final totals = (data['totals'] as Map?)?.cast<String, dynamic>() ?? {};
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatChip(
              label: 'Categories',
              value: '${totals['categories'] ?? 0}',
              icon: Icons.category,
            ),
            _StatChip(
              label: 'Products',
              value: '${totals['products'] ?? 0}',
              icon: Icons.inventory_2,
            ),
            _StatChip(
              label: 'Low stock',
              value: '${totals['lowStock'] ?? 0}',
              icon: Icons.warning_amber_rounded,
              color: AppColors.errorRed,
            ),
            _StatChip(
              label: 'Inventory value',
              value: '₹${totals['inventoryValue'] ?? 0}',
              icon: Icons.currency_rupee,
              color: AppColors.primaryGreen,
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.navyBlue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 8),
          Text('$value ',
              style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    super.key,
    required this.category,
    required this.index,
    required this.onEdit,
    required this.onAddSub,
    required this.onEditSub,
    required this.onDeleteSub,
    required this.onToggleActive,
    required this.onDelete,
  });

  final Map<String, dynamic> category;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onAddSub;
  final ValueChanged<Map<String, dynamic>> onEditSub;
  final ValueChanged<Map<String, dynamic>> onDeleteSub;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category['color'] as String?);
    final children = (category['children'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    final count = (category['_count'] as Map?)?['products'] as int? ?? 0;
    final active = category['isActive'] as bool? ?? true;
    final featured = category['isFeatured'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: ReorderableDragStartListener(
          index: index,
          child: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(categoryIcon(category['icon'] as String?), color: color),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                category['name'] as String? ?? '',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: active ? null : Colors.grey,
                ),
              ),
            ),
            if (featured) ...[
              const SizedBox(width: 8),
              _Badge(label: 'Featured', color: Colors.amber.shade700),
            ],
            if (!active) ...[
              const SizedBox(width: 8),
              _Badge(label: 'Disabled', color: Colors.grey),
            ],
          ],
        ),
        subtitle: Text('$count products · ${children.length} subcategories'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            switch (v) {
              case 'edit':
                onEdit();
              case 'add':
                onAddSub();
              case 'toggle':
                onToggleActive();
              case 'delete':
                onDelete();
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'add', child: Text('Add subcategory')),
            PopupMenuItem(
              value: 'toggle',
              child: Text(active ? 'Disable' : 'Enable'),
            ),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
        children: [
          for (final sub in children)
            ListTile(
              contentPadding: const EdgeInsets.only(left: 72, right: 16),
              dense: true,
              leading: Icon(
                categoryIcon(sub['icon'] as String?),
                size: 20,
                color: color,
              ),
              title: Text(sub['name'] as String? ?? ''),
              subtitle: Text(
                '${(sub['_count'] as Map?)?['products'] as int? ?? 0} products',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () => onEditSub(sub),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: AppColors.errorRed,
                    onPressed: () => onDeleteSub(sub),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 72, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onAddSub,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add subcategory'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _CategoryAnalyticsSheet extends ConsumerWidget {
  const _CategoryAnalyticsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminCategoryAnalyticsProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, controller) => async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(AdminApiUtils.dioMessage(e))),
        data: (data) {
          final byCategory =
              (data['byCategory'] as List? ?? []).cast<Map<String, dynamic>>();
          final topSelling =
              (data['topSelling'] as List? ?? []).cast<Map<String, dynamic>>();
          final maxValue = byCategory.fold<int>(
            1,
            (m, c) => (c['inventoryValue'] as int? ?? 0) > m
                ? c['inventoryValue'] as int
                : m,
          );

          return ListView(
            controller: controller,
            padding: const EdgeInsets.all(20),
            children: [
              Text('Category performance',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              if (topSelling.isNotEmpty) ...[
                const Text('Top selling categories',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: topSelling.map((c) {
                    return Chip(
                      backgroundColor:
                          categoryColor(c['color'] as String?).withValues(alpha: 0.12),
                      label: Text(
                        '${c['name']} · ${c['quantitySold']} sold',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
              const Text('Products & inventory by category',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              ...byCategory.map((c) {
                final color = categoryColor(c['color'] as String?);
                final value = c['inventoryValue'] as int? ?? 0;
                final lowStock = c['lowStock'] as int? ?? 0;
                final products = c['productCount'] as int? ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(categoryIcon(c['icon'] as String?),
                              size: 18, color: color),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(c['name'] as String? ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                          ),
                          Text('$products products · ₹$value',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value / maxValue,
                          minHeight: 8,
                          backgroundColor: Colors.grey.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                      if (lowStock > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '$lowStock low-stock items',
                            style: TextStyle(
                                color: AppColors.errorRed, fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({
    this.category,
    this.parentId,
    this.parentName,
  });

  final Map<String, dynamic>? category;
  final String? parentId;
  final String? parentName;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _aliases;
  late final TextEditingController _image;
  late final TextEditingController _description;
  late String _icon;
  late String _color;
  late bool _featured;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _name = TextEditingController(text: c?['name'] as String? ?? '');
    _aliases = TextEditingController(
      text: ((c?['aliases'] as List?)?.cast<String>() ?? []).join(', '),
    );
    _image = TextEditingController(text: c?['imageUrl'] as String? ?? '');
    _description =
        TextEditingController(text: c?['description'] as String? ?? '');
    _icon = c?['icon'] as String? ?? kCategoryIconChoices.first;
    _color = c?['color'] as String? ?? kCategoryColorChoices.first;
    _featured = c?['isFeatured'] as bool? ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _aliases.dispose();
    _image.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    if (_name.text.trim().isEmpty) return;
    final aliases = _aliases.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    Navigator.pop(context, {
      'name': _name.text.trim(),
      'icon': _icon,
      'color': _color,
      'aliases': aliases,
      'isFeatured': _featured,
      if (_image.text.trim().isNotEmpty) 'imageUrl': _image.text.trim(),
      if (_description.text.trim().isNotEmpty)
        'description': _description.text.trim(),
      if (widget.parentId != null) 'parentId': widget.parentId,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;
    final isSub = widget.parentId != null;
    final title = isEdit
        ? 'Edit ${isSub ? 'subcategory' : 'category'}'
        : 'New ${isSub ? 'subcategory' : 'category'}';

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSub && widget.parentName != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('Parent: ${widget.parentName}',
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name *'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _aliases,
                decoration: const InputDecoration(
                  labelText: 'Aliases (comma separated)',
                  hintText: 'veg, vegetable, fresh vegetables',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _image,
                decoration: const InputDecoration(labelText: 'Image URL'),
              ),
              const SizedBox(height: 16),
              const Text('Icon', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kCategoryIconChoices.map((name) {
                  final selected = name == _icon;
                  return InkWell(
                    onTap: () => setState(() => _icon = name),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selected
                            ? categoryColor(_color).withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? categoryColor(_color)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(categoryIcon(name),
                          color: categoryColor(_color)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Colour',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kCategoryColorChoices.map((hex) {
                  final selected = hex == _color;
                  return InkWell(
                    onTap: () => setState(() => _color = hex),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: categoryColor(hex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.black : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Featured'),
                value: _featured,
                activeThumbColor: AppColors.primaryGreen,
                onChanged: (v) => setState(() => _featured = v),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
