import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/category_icons.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../providers/categories_provider.dart';
import 'products_list_screen.dart';

/// Customer-facing category browser: shows every top-level category with its
/// icon, image, product count and featured badge. Selecting a category reveals
/// its subcategories.
class CategoryBrowseScreen extends ConsumerWidget {
  const CategoryBrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(categoriesProvider);
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width > 1000 ? 5 : (width > 700 ? 4 : (width > 480 ? 3 : 2));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyStateWidget(
          icon: Icons.wifi_off,
          title: 'Could not load categories',
          subtitle: 'Check your connection and try again',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(categoriesProvider),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('No categories yet'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.82,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (_, i) => _CategoryCard(
              category: categories[i],
              onTap: () => _openCategory(context, categories[i]),
            ),
          );
        },
      ),
    );
  }

  void _openCategory(BuildContext context, Map<String, dynamic> category) {
    final children =
        (category['children'] as List? ?? []).cast<Map<String, dynamic>>();
    if (children.isEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductsListScreen(
            categoryId: category['id'] as String,
            title: category['name'] as String?,
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubcategoryScreen(category: category),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final Map<String, dynamic> category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category['color'] as String?);
    final image = category['imageUrl'] as String?;
    final featured = category['isFeatured'] as bool? ?? false;
    final count = (category['_count'] as Map?)?['products'] as int? ?? 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(14),
                        child: image != null && image.isNotEmpty
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: image,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Icon(
                                    categoryIcon(category['icon'] as String?),
                                    color: color,
                                    size: 28,
                                  ),
                                ),
                              )
                            : Icon(
                                categoryIcon(category['icon'] as String?),
                                color: color,
                                size: 28,
                              ),
                      ),
                    ),
                    if (featured)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '★',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category['name'] as String? ?? '',
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count items',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the subcategories of a selected category, plus an "All" shortcut.
class SubcategoryScreen extends StatelessWidget {
  const SubcategoryScreen({super.key, required this.category});

  final Map<String, dynamic> category;

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category['color'] as String?);
    final children =
        (category['children'] as List? ?? []).cast<Map<String, dynamic>>();
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width > 700 ? 4 : (width > 480 ? 3 : 2);

    void openProducts({String? subcategoryId, String? title}) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductsListScreen(
            categoryId: category['id'] as String,
            subcategoryId: subcategoryId,
            title: title ?? category['name'] as String?,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(title: Text(category['name'] as String? ?? 'Category')),
      body: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 0.9,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: children.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return _SubTile(
              color: color,
              icon: categoryIcon(category['icon'] as String?),
              label: 'All ${category['name']}',
              onTap: () => openProducts(),
            );
          }
          final sub = children[i - 1];
          final count = (sub['_count'] as Map?)?['products'] as int? ?? 0;
          return _SubTile(
            color: color,
            icon: categoryIcon(sub['icon'] as String?),
            label: sub['name'] as String? ?? '',
            subtitle: '$count items',
            onTap: () => openProducts(
              subcategoryId: sub['id'] as String,
              title: sub['name'] as String?,
            ),
          );
        },
      ),
    );
  }
}

class _SubTile extends StatelessWidget {
  const _SubTile({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
  });

  final Color color;
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
