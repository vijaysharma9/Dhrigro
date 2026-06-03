import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/admin_repository.dart';
import 'admin_product_form_screen.dart';

final adminProductsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(adminRepositoryProvider).getProducts();
});

class AdminProductsScreen extends ConsumerWidget {
  const AdminProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(adminProductsProvider);

    return Scaffold(
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) {
          final products = (data['data'] as List?) ?? [];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Products (${data['meta']?['total'] ?? products.length})',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminProductFormScreen(),
                          ),
                        );
                        ref.invalidate(adminProductsProvider);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add product'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: products.isEmpty
                    ? const Center(child: Text('No products'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final p = products[i] as Map<String, dynamic>;
                          final images = p['images'] as List?;
                          final thumb = images?.isNotEmpty == true
                              ? images!.first as String
                              : null;
                          return Card(
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: thumb != null
                                    ? CachedNetworkImage(
                                        imageUrl: thumb,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                      )
                                    : const SizedBox(
                                        width: 56,
                                        height: 56,
                                        child: Icon(Icons.image),
                                      ),
                              ),
                              title: Text(p['name'] as String? ?? ''),
                              subtitle: Text(
                                '₹${p['basePrice']} • Stock: ${p['stock']}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    p['isActive'] == true
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: p['isActive'] == true
                                        ? AppColors.primaryGreen
                                        : AppColors.errorRed,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AdminProductFormScreen(
                                      productId: p['id'] as String,
                                    ),
                                  ),
                                );
                                ref.invalidate(adminProductsProvider);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
