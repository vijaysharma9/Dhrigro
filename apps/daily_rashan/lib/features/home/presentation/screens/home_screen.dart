import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeDataProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width > 800;
    final crossAxisCount = isWide ? 6 : (width > 600 ? 4 : 2);

    return Scaffold(
      body: SafeArea(
        child: homeAsync.when(
          loading: () => const HomeSkeleton(),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (data) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(homeDataProvider);
              ref.invalidate(recentOrdersProvider);
            },
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(
                  child: _buildSearchBar(context),
                ),
                SliverToBoxAdapter(
                  child: _buildDeliveryCard(context, data),
                ),
                SliverToBoxAdapter(
                  child: _buildBanners(context, data['banners'] as List? ?? []),
                ),
                SliverToBoxAdapter(
                  child: SectionHeader(
                    title: 'Shop by category',
                    onSeeAll: () => context.go('/categories'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildCategories(
                    context,
                    data['categories'] as List? ?? [],
                    isWide,
                  ),
                ),
                _productSection(
                  context,
                  ref,
                  'Featured',
                  data['featuredProducts'] as List? ?? [],
                  crossAxisCount,
                ),
                _productSection(
                  context,
                  ref,
                  'Best sellers',
                  data['bestSellers'] as List? ?? [],
                  crossAxisCount,
                ),
                _productSection(
                  context,
                  ref,
                  'Trending now',
                  data['trendingProducts'] as List? ?? [],
                  crossAxisCount,
                ),
                SliverToBoxAdapter(
                  child: _buildOffersBanner(context),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.appName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
              ),
              const Text(
                'Deliver to Home',
                style: TextStyle(color: AppColors.textGrey, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () => context.push('/products'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: AppColors.textGrey),
              SizedBox(width: 12),
              Text(
                'Search for atta, milk, vegetables...',
                style: TextStyle(color: AppColors.textGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(BuildContext context, Map<String, dynamic> data) {
    final info = data['deliveryInfo'] as Map<String, dynamic>? ?? {};
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryGreen, Color(0xFF2ECC71)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.delivery_dining, color: Colors.white, size: 32),
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
        ],
      ),
    );
  }

  Widget _buildBanners(BuildContext context, List banners) {
    if (banners.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: CarouselSlider(
        options: CarouselOptions(
          height: 160,
          autoPlay: true,
          enlargeCenterPage: true,
          viewportFraction: 0.9,
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

  Widget _buildCategories(BuildContext context, List categories, bool isWide) {
    return SizedBox(
      height: isWide ? 120 : 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (_, i) {
          final cat = categories[i] as Map<String, dynamic>;
          return GestureDetector(
            onTap: () => context.push(
              '/products?categoryId=${cat['id']}',
            ),
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: cat['imageUrl'] as String? ?? '',
                      width: 64,
                      height: 64,
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

  Widget _productSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    List products,
    int crossAxisCount,
  ) {
    if (products.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            onSeeAll: () => context.push('/products'),
          ),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              itemBuilder: (_, i) {
                final product = products[i] as Map<String, dynamic>;
                return ProductCard(
                  product: product,
                  onAddToCart: () {
                    ref.read(cartProvider.notifier).addItem(product['id'] as String);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Added to cart')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOffersBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.orangeAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.orangeAccent.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.local_offer, color: AppColors.orangeAccent, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Use code WELCOME50',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹50 off on orders above ₹299',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
