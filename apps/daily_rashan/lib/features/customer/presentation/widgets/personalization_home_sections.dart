import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/customer/customer_insights_provider.dart';
import '../../../../core/customer/customer_prefs_provider.dart';
import '../../../../core/customer/personalization_engine.dart';
import '../../../../shared/widgets/premium_product_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/app_success_snackbar.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

class PersonalizationHomeSections extends ConsumerWidget {
  const PersonalizationHomeSections({
    super.key,
    required this.homeData,
    required this.orders,
  });

  final Map<String, dynamic> homeData;
  final List<dynamic> orders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(customerInsightsProvider).valueOrNull;
    final prefs = ref.watch(customerPrefsProvider).valueOrNull;
    final quantities = ref.watch(cartQuantitiesProvider);

    final recommended = PersonalizationEngine.recommendedForYou(
      homeData: homeData,
      purchaseCounts: insights?.purchaseCounts ?? {},
      searchHistory: prefs?.searchHistory ?? [],
    );
    final fromPurchases = PersonalizationEngine.basedOnYourPurchases(
      orders: orders,
      homeData: homeData,
    );
    final popular = PersonalizationEngine.popularInYourArea(homeData);
    final viewed = PersonalizationEngine.recentlyViewedProducts(
      viewedIds: insights?.recentlyViewed ?? [],
      homeData: homeData,
    );

    return Column(
      children: [
        _ProductRow(
          title: 'Recommended for you',
          products: recommended,
          quantities: quantities,
        ),
        if (fromPurchases.isNotEmpty)
          _ProductRow(
            title: 'Based on your purchases',
            products: fromPurchases,
            quantities: quantities,
          ),
        _ProductRow(
          title: 'Popular in your area',
          products: popular,
          quantities: quantities,
        ),
        if (viewed.isNotEmpty)
          _ProductRow(
            title: 'Recently viewed',
            products: viewed,
            quantities: quantities,
          ),
      ],
    );
  }
}

class _ProductRow extends ConsumerWidget {
  const _ProductRow({
    required this.title,
    required this.products,
    required this.quantities,
  });

  final String title;
  final List<Map<String, dynamic>> products;
  final Map<String, int> quantities;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title),
        SizedBox(
          height: PremiumProductCard.horizontalListHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: products.length,
            itemBuilder: (_, i) {
              final product = products[i];
              final id = product['id'] as String;
              final qty = quantities[id] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: PremiumProductCard(
                  product: product,
                  quantity: qty,
                  onAddToCart: () {
                    ref.read(cartProvider.notifier).addItem(id);
                    showSuccessSnackBar(context, '${product['name']} added');
                  },
                  onIncrement: () =>
                      ref.read(cartProvider.notifier).addOrIncrement(id),
                  onDecrement: () =>
                      ref.read(cartProvider.notifier).decrementProduct(id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
