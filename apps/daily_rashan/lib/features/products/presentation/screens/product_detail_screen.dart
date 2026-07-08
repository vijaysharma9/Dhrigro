import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/customer/customer_insights_provider.dart';
import '../../../../core/utils/product_formatters.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/premium_product_card.dart';
import '../../../../shared/widgets/quantity_stepper.dart';
import '../../../../shared/widgets/trust_section.dart';
import '../../../../shared/widgets/app_success_snackbar.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

final productDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/products/$id');
  return res.data as Map<String, dynamic>;
});

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerInsightsProvider.notifier).trackProductView(widget.productId);
      ref.trackEvent(AnalyticsEvents.productViewed, {'product_id': widget.productId});
    });
  }

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final qty = ref.watch(cartQuantitiesProvider)[widget.productId] ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyStateWidget(
          icon: Icons.inventory_2_outlined,
          title: 'Could not load product',
          subtitle: 'Check your connection and try again',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(productDetailProvider(widget.productId)),
        ),
        data: (product) => _ProductBody(product: product, productId: widget.productId, qty: qty),
      ),
      bottomNavigationBar: productAsync.maybeWhen(
        data: (product) => _StickyFooter(
          productId: widget.productId,
          product: product,
          qty: qty,
        ),
        orElse: () => null,
      ),
    );
  }
}

class _ProductBody extends ConsumerWidget {
  const _ProductBody({
    required this.product,
    required this.productId,
    required this.qty,
  });

  final Map<String, dynamic> product;
  final String productId;
  final int qty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = product['images'] as List? ?? [];
    final basePrice = ProductFormatters.basePrice(product);
    final price = ProductFormatters.price(product);
    final discountPct = ProductFormatters.discountPercent(product);
    final rating = ProductFormatters.rating(product);
    final reviews = (product['reviews'] as List?) ?? [];
    final related = (product['relatedProducts'] as List?) ?? [];
    final inStock = ProductFormatters.inStock(product);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: images.isEmpty
                ? Container(color: Colors.grey.shade100)
                : CarouselSlider(
                    options: CarouselOptions(height: 320, viewportFraction: 1),
                    items: images.map<Widget>((url) {
                      return CachedNetworkImage(
                        imageUrl: url as String,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      );
                    }).toList(),
                  ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (discountPct != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.orangeAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$discountPct% OFF',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  product['name'] as String? ?? '',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.navyBlue,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 18),
                    Text(' ${rating.toStringAsFixed(1)}'),
                    const SizedBox(width: 12),
                    Text(
                      product['unit'] as String? ?? 'piece',
                      style: const TextStyle(color: AppColors.textGrey),
                    ),
                    const Spacer(),
                    Icon(
                      inStock ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: inStock ? AppColors.successGreen : AppColors.errorRed,
                    ),
                    Text(
                      inStock ? ' In stock' : ' Out of stock',
                      style: TextStyle(
                        color: inStock ? AppColors.successGreen : AppColors.errorRed,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    if (discountPct != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '₹${basePrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _InfoChip(
                  icon: Icons.delivery_dining,
                  label: product['deliveryEstimate'] as String? ?? 'Delivery by tomorrow 9 AM',
                ),
                const SizedBox(height: AppSpacing.sm),
                const Row(
                  children: [
                    Icon(Icons.verified, size: 16, color: AppColors.successGreen),
                    SizedBox(width: 6),
                    Text(
                      '98% on-time delivery · Freshness guaranteed',
                      style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle('Highlights'),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _HighlightChip('Fresh'),
                    _HighlightChip('Quality checked'),
                    _HighlightChip('Easy returns'),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle('Product details'),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  product['description'] as String? ?? 'No description available.',
                  style: const TextStyle(height: 1.5, color: AppColors.textDark),
                ),
                if (product['weight'] != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text('Weight: ${product['weight']}',
                      style: const TextStyle(color: AppColors.textGrey)),
                ],
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle('Nutrition & facts'),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: const Text(
                    'Nutrition information will be available soon for this product.',
                    style: TextStyle(color: AppColors.textGrey, fontSize: 13),
                  ),
                ),
                if (related.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionTitle('Similar products'),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: PremiumProductCard.horizontalListHeight,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: related.length,
                      itemBuilder: (_, i) {
                        final p = related[i] as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: PremiumProductCard(product: p),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                _SectionTitle('Frequently bought together'),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Customers also bought these items — coming soon',
                  style: TextStyle(color: AppColors.textGrey),
                ),
                if (reviews.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionTitle('Reviews (${reviews.length})'),
                  const SizedBox(height: AppSpacing.sm),
                  ...reviews.take(5).map((r) {
                    final review = r as Map<String, dynamic>;
                    final user = review['user'] as Map<String, dynamic>?;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Text((user?['name'] as String? ?? 'U').substring(0, 1)),
                      ),
                      title: Text(user?['name'] as String? ?? 'Customer'),
                      subtitle: Text(review['comment'] as String? ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          Text('${review['rating']}'),
                        ],
                      ),
                    );
                  }),
                ],
                const SizedBox(height: AppSpacing.lg),
                const TrustSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StickyFooter extends ConsumerWidget {
  const _StickyFooter({
    required this.productId,
    required this.product,
    required this.qty,
  });

  final String productId;
  final Map<String, dynamic> product;
  final int qty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inStock = ProductFormatters.inStock(product);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (qty > 0)
              Expanded(
                child: QuantityStepper(
                  quantity: qty,
                  onDecrement: () =>
                      ref.read(cartProvider.notifier).decrementProduct(productId),
                  onIncrement: () =>
                      ref.read(cartProvider.notifier).addOrIncrement(productId),
                ),
              )
            else
              Expanded(
                child: FilledButton(
                  onPressed: inStock
                      ? () {
                          ref.read(cartProvider.notifier).addItem(productId);
                          showSuccessSnackBar(context, 'Added to cart');
                        }
                      : null,
                  child: Text(inStock ? 'Add to cart' : 'Out of stock'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
        color: AppColors.navyBlue,
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.navyBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.navyBlue),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.08),
      side: BorderSide.none,
    );
  }
}
