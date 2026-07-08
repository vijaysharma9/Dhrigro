import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/premium_product_card.dart';
import '../../../../shared/widgets/shimmer_box.dart';
import '../../../../shared/widgets/app_success_snackbar.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

class ProductsListParams {
  const ProductsListParams({
    this.categoryId,
    this.subcategoryId,
    this.search,
    this.sortBy,
    this.page = 1,
  });

  final String? categoryId;
  final String? subcategoryId;
  final String? search;
  final String? sortBy;
  final int page;

  @override
  bool operator ==(Object other) =>
      other is ProductsListParams &&
      other.categoryId == categoryId &&
      other.subcategoryId == subcategoryId &&
      other.search == search &&
      other.sortBy == sortBy &&
      other.page == page;

  @override
  int get hashCode =>
      Object.hash(categoryId, subcategoryId, search, sortBy, page);
}

final productsListProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, ProductsListParams>(
  (ref, params) async {
    final dio = ref.read(dioProvider);
    final res = await dio.get('/products', queryParameters: {
      if (params.categoryId != null) 'categoryId': params.categoryId,
      if (params.subcategoryId != null) 'subcategoryId': params.subcategoryId,
      if (params.search != null && params.search!.isNotEmpty) 'search': params.search,
      if (params.sortBy != null) 'sortBy': params.sortBy,
      'page': 1,
      'limit': 50,
    });
    return res.data as Map<String, dynamic>;
  },
);

class ProductsListScreen extends ConsumerStatefulWidget {
  const ProductsListScreen({
    super.key,
    this.categoryId,
    this.subcategoryId,
    this.initialSearch,
    this.title,
  });

  final String? categoryId;
  final String? subcategoryId;
  final String? initialSearch;
  final String? title;

  @override
  ConsumerState<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends ConsumerState<ProductsListScreen> {
  String? _sortBy;

  @override
  void initState() {
    super.initState();
    _sortBy = 'popular';
  }

  ProductsListParams get _params => ProductsListParams(
        categoryId: widget.categoryId,
        subcategoryId: widget.subcategoryId,
        search: widget.initialSearch,
        sortBy: _sortBy,
      );

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsListProvider(_params));
    final quantities = ref.watch(cartQuantitiesProvider);
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width > 900 ? 4 : (width > 600 ? 3 : 2);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: Text(widget.title ?? 'Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Popular',
                  selected: _sortBy == 'popular',
                  onTap: () => setState(() => _sortBy = 'popular'),
                ),
                _FilterChip(
                  label: 'Price: Low',
                  selected: _sortBy == 'price_asc',
                  onTap: () => setState(() => _sortBy = 'price_asc'),
                ),
                _FilterChip(
                  label: 'Price: High',
                  selected: _sortBy == 'price_desc',
                  onTap: () => setState(() => _sortBy = 'price_desc'),
                ),
                _FilterChip(
                  label: 'Discount',
                  selected: _sortBy == 'discount',
                  onTap: () => setState(() => _sortBy = 'discount'),
                ),
              ],
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 0.54,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: 6,
                itemBuilder: (_, __) => const ProductCardShimmer(),
              ),
              error: (e, _) => EmptyStateWidget(
                icon: Icons.shopping_bag_outlined,
                title: 'Could not load products',
                subtitle: 'Check your connection and try again',
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(productsListProvider(_params)),
              ),
              data: (data) {
                final products = (data['data'] as List?) ?? [];

                if (products.isEmpty) {
                  return const Center(child: Text('No products found'));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(productsListProvider(_params));
                    await ref.read(productsListProvider(_params).future);
                  },
                  child: GridView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.54,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (_, i) {
                    final product = products[i] as Map<String, dynamic>;
                    final id = product['id'] as String;
                    final qty = quantities[id] ?? 0;
                    return PremiumProductCard(
                      product: product,
                      layout: PremiumProductLayout.grid,
                      quantity: qty,
                      onAddToCart: () {
                        ref.read(cartProvider.notifier).addItem(id);
                        showSuccessSnackBar(
                          context,
                          '${product['name']} added to cart',
                        );
                      },
                      onIncrement: () =>
                          ref.read(cartProvider.notifier).addOrIncrement(id),
                      onDecrement: () =>
                          ref.read(cartProvider.notifier).decrementProduct(id),
                    );
                  },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppColors.primaryGreen.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primaryGreen,
      ),
    );
  }
}
