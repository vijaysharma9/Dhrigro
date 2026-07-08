import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_decorations.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/customer/customer_prefs_provider.dart';
import '../../../../shared/widgets/deal_card.dart';
import '../../../../shared/widgets/premium_product_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/trust_section.dart';
import '../../../../shared/widgets/app_success_snackbar.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../customer/presentation/widgets/order_again_section.dart';
import '../../../customer/presentation/widgets/personalization_home_sections.dart';
import '../../../customer/presentation/widgets/rewards_flash_widgets.dart';
import '../../../../core/customer/customer_insights_provider.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const _quickActions = [
    _QuickAction('Fruits', Icons.apple, 'fruits-vegetables'),
    _QuickAction('Vegetables', Icons.grass, 'fruits-vegetables'),
    _QuickAction('Dairy', Icons.breakfast_dining, 'dairy-refrigerated'),
    _QuickAction('Grocery', Icons.store, 'rice-flour-grains'),
    _QuickAction('Beverages', Icons.local_cafe, 'beverages'),
    _QuickAction('Offers', Icons.local_offer, null),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeDataProvider);
    final buyAgainAsync = ref.watch(recentOrdersProvider);
    final prefs = ref.watch(customerPrefsProvider).valueOrNull;
    final quantities = ref.watch(cartQuantitiesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: SafeArea(
        child: homeAsync.when(
          loading: () => const HomeSkeleton(),
          error: (e, _) => EmptyStateWidget(
            icon: Icons.wifi_off,
            title: 'Unable to load home',
            subtitle: 'Check your connection and try again',
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(homeDataProvider),
          ),
          data: (data) => RefreshIndicator(
            color: AppColors.primaryGreen,
            onRefresh: () async {
              ref.invalidate(homeDataProvider);
              ref.invalidate(recentOrdersProvider);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _HomeHeader(
                    locationLabel: prefs?.deliveryLabel ?? 'Set location',
                    pincode: prefs?.deliveryPincode,
                    onLocationTap: () => context.push('/location-setup'),
                  ),
                ),
                SliverToBoxAdapter(child: _SearchBar()),
                SliverToBoxAdapter(child: _EtaStrip(data: data)),
                const SliverToBoxAdapter(child: RewardsHomeCard()),
                SliverToBoxAdapter(
                  child: _HeroBanners(banners: data['banners'] as List? ?? []),
                ),
                SliverToBoxAdapter(child: _QuickActionsRow(actions: _quickActions)),
                SliverToBoxAdapter(child: _InsightsSync()),
                SliverToBoxAdapter(
                  child: buyAgainAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (orders) => OrderAgainSection(
                      orders: orders,
                      quantities: quantities,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: PersonalizedOffersSection()),
                SliverToBoxAdapter(
                  child: FlashDealsSection(
                    products: _dealProducts(data),
                    childBuilder: (product) {
                      final id = product['id'] as String;
                      final qty = quantities[id] ?? 0;
                      return DealCard(
                        product: product,
                        quantity: qty,
                        onAddToCart: () => _cartHandlers(
                          ref,
                          context,
                          id,
                          product: product,
                        ),
                        onIncrement: () =>
                            ref.read(cartProvider.notifier).addOrIncrement(id),
                        onDecrement: () =>
                            ref.read(cartProvider.notifier).decrementProduct(id),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Shop by category',
                    onSeeAll: () => context.go('/categories'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _CategoriesRow(
                    categories: data['categories'] as List? ?? [],
                  ),
                ),
                SliverToBoxAdapter(
                  child: buyAgainAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (orders) => PersonalizationHomeSections(
                      homeData: data,
                      orders: orders,
                    ),
                  ),
                ),
                ..._productSections(data, ref, context, quantities),
                const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
                const SliverToBoxAdapter(child: TrustSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _dealProducts(Map<String, dynamic> data) {
    final featured = (data['featuredProducts'] as List? ?? []).cast<Map<String, dynamic>>();
    final best = (data['bestSellers'] as List? ?? []).cast<Map<String, dynamic>>();
    final seen = <String>{};
    final deals = <Map<String, dynamic>>[];
    for (final p in [...featured, ...best]) {
      final id = p['id'] as String?;
      if (id != null && seen.add(id) && p['discountPrice'] != null) {
        deals.add(p);
      }
    }
    return deals.take(8).toList();
  }

  void _cartHandlers(
    WidgetRef ref,
    BuildContext context,
    String id, {
    Map<String, dynamic>? product,
  }) {
    final qty = ref.read(cartQuantitiesProvider)[id] ?? 0;
    if (qty == 0) {
      ref.read(cartProvider.notifier).addItem(id);
      if (product != null) {
        showSuccessSnackBar(context, '${product['name']} added to cart');
      }
    }
  }

  List<Widget> _productSections(
    Map<String, dynamic> data,
    WidgetRef ref,
    BuildContext context,
    Map<String, int> quantities,
  ) {
    return [
      ('Trending now', data['trendingProducts'] as List? ?? []),
      ('Best sellers', data['bestSellers'] as List? ?? []),
      ('Featured', data['featuredProducts'] as List? ?? []),
    ].map((section) {
      final products = section.$2;
      if (products.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
      return SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: section.$1,
              onSeeAll: () => context.push('/products'),
            ),
            SizedBox(
              height: PremiumProductCard.horizontalListHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: products.length,
                itemBuilder: (_, i) {
                  final product = products[i] as Map<String, dynamic>;
                  final id = product['id'] as String;
                  final qty = quantities[id] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: PremiumProductCard(
                      product: product,
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
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.locationLabel,
    this.pincode,
    required this.onLocationTap,
  });

  final String locationLabel;
  final String? pincode;
  final VoidCallback onLocationTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onLocationTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            size: 18, color: AppColors.primaryGreen),
                        const SizedBox(width: 4),
                        Text(
                          'Delivery in 10 minutes',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.orangeAccent,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            locationLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.navyBlue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (pincode != null)
                          Text(
                            ' · $pincode',
                            style: const TextStyle(color: AppColors.textGrey),
                          ),
                        const Icon(Icons.keyboard_arrow_down, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Wallet — coming soon',
          ),
          IconButton(
            onPressed: () => context.push('/notifications'),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: GestureDetector(
        onTap: () => context.push('/search'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: AppColors.primaryGreen),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Search atta, milk, vegetables...',
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ),
              Icon(Icons.mic_none, color: AppColors.textGrey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _EtaStrip extends StatelessWidget {
  const _EtaStrip({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final info = data['deliveryInfo'] as Map<String, dynamic>? ?? {};
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppDecorations.heroGradient,
        child: Row(
          children: [
            const Icon(Icons.delivery_dining, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info['message'] as String? ?? AppStrings.deliveryMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (info['sameDayEnabled'] == true)
                    const Text(
                      AppStrings.sameDayDelivery,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '~10 min',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroBanners extends StatelessWidget {
  const _HeroBanners({required this.banners});

  final List banners;

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) return const SizedBox(height: AppSpacing.lg);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 168,
          autoPlay: true,
          enlargeCenterPage: true,
          viewportFraction: 0.92,
          autoPlayInterval: const Duration(seconds: 4),
        ),
        items: banners.map<Widget>((b) {
          final banner = b as Map<String, dynamic>;
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: banner['imageUrl'] as String? ?? '',
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(this.label, this.icon, this.slug);
  final String label;
  final IconData icon;
  final String? slug;
}

class _QuickActionsRow extends StatelessWidget {
  const _QuickActionsRow({required this.actions});

  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        itemCount: actions.length,
        itemBuilder: (_, i) {
          final action = actions[i];
          return GestureDetector(
            onTap: () {
              if (action.label == 'Offers') {
                context.push('/offers');
              } else if (action.slug != null) {
                context.push('/search?query=${Uri.encodeComponent(action.label)}');
              } else {
                context.push('/search?query=offers');
              }
            },
            child: Container(
              width: 72,
              margin: const EdgeInsets.only(right: 10),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Icon(action.icon, color: AppColors.primaryGreen),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    action.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InsightsSync extends ConsumerWidget {
  const _InsightsSync();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(recentOrdersProvider, (_, next) {
      next.whenData((orders) {
        ref.read(customerInsightsProvider.notifier).recordPurchaseFromOrders(orders);
      });
    });
    return const SizedBox.shrink();
  }
}

class _CategoriesRow extends StatelessWidget {
  const _CategoriesRow({required this.categories});

  final List categories;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final cat = categories[i] as Map<String, dynamic>;
          return GestureDetector(
            onTap: () => context.push('/products?categoryId=${cat['id']}'),
            child: Container(
              width: 84,
              margin: const EdgeInsets.only(right: 10),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: cat['imageUrl'] as String? ?? '',
                      width: 68,
                      height: 68,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    cat['name'] as String? ?? '',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
