import 'package:flutter/material.dart';
import 'premium_product_card.dart';

/// Backward-compatible wrapper — delegates to [PremiumProductCard].
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.onAddToCart,
    this.width = 160,
  });

  final Map<String, dynamic> product;
  final VoidCallback? onAddToCart;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: PremiumProductCard(
        product: product,
        onAddToCart: onAddToCart,
        width: width,
      ),
    );
  }
}
