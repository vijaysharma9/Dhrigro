import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/product_card.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

final productsListProvider = FutureProvider.family<Map<String, dynamic>, String?>(
  (ref, categoryId) async {
    final dio = ref.read(dioProvider);
    final res = await dio.get('/products', queryParameters: {
      if (categoryId != null) 'categoryId': categoryId,
      'limit': 50,
    });
    return res.data as Map<String, dynamic>;
  },
);

class ProductsListScreen extends ConsumerWidget {
  const ProductsListScreen({super.key, this.categoryId});

  final String? categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsListProvider(categoryId));
    final width = MediaQuery.sizeOf(context).width;
    final crossAxisCount = width > 900 ? 5 : (width > 600 ? 3 : 2);

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final products = (data['data'] as List?) ?? [];
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: products.length,
            itemBuilder: (_, i) {
              final product = products[i] as Map<String, dynamic>;
              return ProductCard(
                product: product,
                width: double.infinity,
                onAddToCart: () {
                  ref.read(cartProvider.notifier).addItem(product['id'] as String);
                },
              );
            },
          );
        },
      ),
    );
  }
}
