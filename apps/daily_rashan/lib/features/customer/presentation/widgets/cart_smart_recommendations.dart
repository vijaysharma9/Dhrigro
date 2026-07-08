import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/customer/personalization_engine.dart';
import '../../../../shared/widgets/premium_product_card.dart';
import '../../../../shared/widgets/app_success_snackbar.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../home/presentation/providers/home_provider.dart';

/// Smart cart upsell — frequently bought together / free delivery helpers.
class CartSmartRecommendations extends ConsumerWidget {
  const CartSmartRecommendations({
    super.key,
    required this.cart,
  });

  final Map<String, dynamic> cart;

  static const _staples = ['milk', 'bread', 'egg', 'atta', 'banana', 'tomato'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeDataProvider);
    final cartItems = (cart['items'] as List?) ?? [];
    final cartNames = cartItems
        .map((i) =>
            (((i as Map)['product'] as Map?)?['name'] as String? ?? '').toLowerCase())
        .toSet();
    final subtotal = _num(cart['subtotal']);
    final freeDeliveryGap = (499 - subtotal).clamp(0, 499);

    return homeAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (homeData) {
        final catalog = PersonalizationEngine.allCatalogProducts(homeData);
        final inCartIds = cartItems
            .map((i) => ((i as Map)['product'] as Map?)?['id'] as String?)
            .whereType<String>()
            .toSet();

        final suggestions = catalog.where((p) {
          final id = p['id'] as String?;
          if (id == null || inCartIds.contains(id)) return false;
          final name = (p['name'] as String? ?? '').toLowerCase();
          if (_staples.any(name.contains)) return true;
          if (freeDeliveryGap > 0 && _num(p['basePrice']) <= freeDeliveryGap + 50) {
            return true;
          }
          return cartNames.any((cn) => name.contains(cn.split(' ').first));
        }).take(6).toList();

        if (suggestions.isEmpty) return const SizedBox.shrink();

        final title = freeDeliveryGap > 0
            ? 'Add for free delivery (₹${freeDeliveryGap.toStringAsFixed(0)} more)'
            : 'Frequently bought together';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            SizedBox(
              height: PremiumProductCard.horizontalListHeight,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: suggestions.length,
                itemBuilder: (_, i) {
                  final product = suggestions[i];
                  final id = product['id'] as String;
                  return SizedBox(
                    width: 140,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: PremiumProductCard(
                        product: product,
                        width: 140,
                        onAddToCart: () {
                          ref.read(cartProvider.notifier).addItem(id);
                          showSuccessSnackBar(
                            context,
                            '${product['name']} added',
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  double _num(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? 0;
  }
}

/// Trust badges row for checkout.
class CheckoutTrustRow extends StatelessWidget {
  const CheckoutTrustRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: const [
          _TrustBadge(icon: Icons.lock, label: 'Secure checkout'),
          _TrustBadge(icon: Icons.eco, label: 'Freshness guarantee'),
          _TrustBadge(icon: Icons.verified_user, label: 'Money-back placeholder'),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primaryGreen),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
