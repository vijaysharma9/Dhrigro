import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_decorations.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/utils/product_formatters.dart';
import 'quantity_stepper.dart';

/// Premium grocery product card — Blinkit-inspired.
class PremiumProductCard extends StatelessWidget {
  const PremiumProductCard({
    super.key,
    required this.product,
    this.onAddToCart,
    this.quantity = 0,
    this.onIncrement,
    this.onDecrement,
    this.width = 156,
    this.layout = PremiumProductLayout.horizontal,
    this.showOrderCount,
    this.showDeliveryEta,
  });

  /// Use for horizontal `ListView` parents — matches compact card height.
  static const double horizontalListHeight = 246;

  static const double _horizontalImageHeight = 108;

  final Map<String, dynamic> product;
  final VoidCallback? onAddToCart;
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final double width;
  final PremiumProductLayout layout;
  final int? showOrderCount;
  final bool? showDeliveryEta;

  @override
  Widget build(BuildContext context) {
    final imageUrl = ProductFormatters.imageUrl(product) ?? '';
    final price = ProductFormatters.price(product);
    final base = ProductFormatters.basePrice(product);
    final discountPct = ProductFormatters.discountPercent(product);
    final rating = ProductFormatters.rating(product);
    final inStock = ProductFormatters.inStock(product);
    final isGrid = layout == PremiumProductLayout.grid;
    final isHorizontal = layout == PremiumProductLayout.horizontal;
    final horizontalImageHeight = _horizontalImageHeight;
    final showEta = showDeliveryEta ?? !isHorizontal;

    return GestureDetector(
      onTap: () => context.push('/products/${product['id']}'),
      child: Container(
        width: isGrid ? null : width,
        decoration: AppDecorations.card(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: isGrid
                      ? AspectRatio(
                          aspectRatio: 1,
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 320,
                            placeholder: (_, __) => Container(color: Colors.grey.shade100),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.primaryGreen.withValues(alpha: 0.08),
                              child: const Icon(Icons.image, color: AppColors.primaryGreen),
                            ),
                          ),
                        )
                      : SizedBox(
                          width: width,
                          height: horizontalImageHeight,
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: width,
                            height: horizontalImageHeight,
                            fit: BoxFit.cover,
                            memCacheWidth: 320,
                            placeholder: (_, __) => Container(color: Colors.grey.shade100),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.primaryGreen.withValues(alpha: 0.08),
                              child: const Icon(Icons.image, color: AppColors.primaryGreen),
                            ),
                          ),
                        ),
                ),
                if (discountPct != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _Badge(
                      label: '$discountPct% OFF',
                      color: AppColors.orangeAccent,
                    ),
                  ),
                if (product['isBestSeller'] == true)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _Badge(label: 'Bestseller', color: AppColors.navyBlue),
                  )
                else if (!inStock)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _Badge(label: 'Out of stock', color: AppColors.textGrey),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(isHorizontal ? 8 : 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] as String? ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isHorizontal ? 12 : 13,
                      height: 1.2,
                    ),
                  ),
                  if (showOrderCount != null && showOrderCount! > 1) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Ordered ${showOrderCount}x',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.orangeAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product['unit'] as String? ?? 'piece',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textGrey, fontSize: 11),
                        ),
                      ),
                      Icon(Icons.star, size: 12, color: Colors.amber.shade700),
                      const SizedBox(width: 2),
                      Text(
                        rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      if (showEta) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.delivery_dining, size: 12, color: AppColors.navyBlue),
                        const SizedBox(width: 2),
                        const Text(
                          '10m',
                          style: TextStyle(fontSize: 10, color: AppColors.navyBlue),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: isHorizontal ? 4 : AppSpacing.sm),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹${price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryGreen,
                                fontSize: isHorizontal ? 14 : 15,
                              ),
                            ),
                            if (discountPct != null)
                              Text(
                                '₹${base.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.textGrey,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (quantity > 0 && onIncrement != null && onDecrement != null)
                        QuantityStepper(
                          quantity: quantity,
                          onDecrement: onDecrement!,
                          onIncrement: onIncrement!,
                          compact: true,
                        )
                      else if (inStock && onAddToCart != null)
                        AddToCartButton(onTap: onAddToCart!),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

enum PremiumProductLayout { horizontal, grid }
