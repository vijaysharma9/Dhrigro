import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (cart) {
          if (cart == null) {
            return const Center(child: Text('Login to view cart'));
          }
          final items = (cart['items'] as List?) ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i] as Map<String, dynamic>;
                    final product = item['product'] as Map<String, dynamic>;
                    final images = product['images'] as List?;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: images?.isNotEmpty == true
                                ? images!.first as String
                                : '',
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(product['name'] as String? ?? ''),
                        subtitle: Text('₹${item['unitPrice']} x ${item['quantity']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                final q = (item['quantity'] as int) - 1;
                                ref.read(cartProvider.notifier).updateQuantity(
                                      item['id'] as String,
                                      q < 1 ? 0 : q,
                                    );
                              },
                            ),
                            Text('${item['quantity']}'),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                ref.read(cartProvider.notifier).updateQuantity(
                                      item['id'] as String,
                                      (item['quantity'] as int) + 1,
                                    );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              _buildSummary(context, cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummary(BuildContext context, Map<String, dynamic> cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          _row('Subtotal', cart['subtotal']),
          _row('Discount', cart['discountAmount']),
          _row('Delivery', cart['deliveryFee']),
          if ((cart['sameDayFee'] as num?) != null && (cart['sameDayFee'] as num) > 0)
            _row('Same day fee', cart['sameDayFee']),
          const Divider(),
          _row('Total', cart['total'], bold: true),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/checkout'),
              child: Text('Checkout • ₹${cart['total']}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, dynamic value, {bool bold = false}) {
    final v = value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
          Text(
            '₹${v.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : null,
              color: bold ? AppColors.primaryGreen : null,
            ),
          ),
        ],
      ),
    );
  }
}
