import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_decorations.dart';
import '../../core/utils/product_formatters.dart';
import 'quantity_stepper.dart';

/// Horizontal deal card for flash deals row.
class DealCard extends StatelessWidget {
  const DealCard({super.key, required this.product, this.onAddToCart, this.quantity = 0, this.onIncrement, this.onDecrement});

  /// Matches [FlashDealsSection] list height.
  static const double listHeight = 112;

  final Map<String, dynamic> product;
  final VoidCallback? onAddToCart;
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    final imageUrl = ProductFormatters.imageUrl(product) ?? '';
    final price = ProductFormatters.price(product);
    final discountPct = ProductFormatters.discountPercent(product);

    return GestureDetector(
      onTap: () => context.push('/products/${product['id']}'),
      child: Container(
        width: 280,
        height: listHeight,
        margin: const EdgeInsets.only(right: 12),
        decoration: AppDecorations.card(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: listHeight,
                    height: listHeight,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: listHeight,
                      height: listHeight,
                      color: AppColors.primaryGreen.withValues(alpha: 0.08),
                      child: const Icon(Icons.image, color: AppColors.primaryGreen),
                    ),
                  ),
                ),
                if (discountPct != null)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.orangeAccent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$discountPct% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'] as String? ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, height: 1.2),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '₹${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryGreen,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        if (quantity > 0 && onIncrement != null)
                          QuantityStepper(
                            quantity: quantity,
                            onDecrement: onDecrement!,
                            onIncrement: onIncrement!,
                            compact: true,
                          )
                        else if (onAddToCart != null)
                          AddToCartButton(onTap: onAddToCart!),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 12, color: Colors.red.shade400),
                        const SizedBox(width: 4),
                        Text(
                          'Ends soon',
                          style: TextStyle(fontSize: 10, color: Colors.red.shade400),
                        ),
                        const Spacer(),
                        if (ProductFormatters.inStock(product))
                          const Text(
                            'In stock',
                            style: TextStyle(fontSize: 10, color: AppColors.successGreen),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
