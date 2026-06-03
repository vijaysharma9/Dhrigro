import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

final productDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, id) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/products/$id');
  return res.data as Map<String, dynamic>;
});

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));

    return Scaffold(
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (product) {
          final images = product['images'] as List? ?? [];
          final basePrice = _num(product['basePrice']);
          final discount = product['discountPrice'] != null
              ? _num(product['discountPrice'])
              : null;
          final price = discount ?? basePrice;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: images.isEmpty
                      ? Container(color: Colors.grey.shade100)
                      : CarouselSlider(
                          options: CarouselOptions(
                            height: 300,
                            viewportFraction: 1,
                          ),
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'] as String? ?? '',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '₹${price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                          if (discount != null) ...[
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
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.navyBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product['deliveryEstimate'] as String? ??
                              'Next morning delivery',
                          style: const TextStyle(
                            color: AppColors.navyBlue,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(product['description'] as String? ?? ''),
                      const SizedBox(height: 24),
                      if ((product['relatedProducts'] as List?)?.isNotEmpty ==
                          true) ...[
                        Text(
                          'Related products',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                (product['relatedProducts'] as List).length,
                            itemBuilder: (_, i) {
                              final p = (product['relatedProducts'] as List)[i]
                                  as Map<String, dynamic>;
                              return ProductCard(product: p);
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: productAsync.maybeWhen(
        data: (product) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                ref.read(cartProvider.notifier).addItem(productId);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to cart')),
                );
              },
              child: const Text('Add to cart'),
            ),
          ),
        ),
        orElse: () => null,
      ),
    );
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }
}
