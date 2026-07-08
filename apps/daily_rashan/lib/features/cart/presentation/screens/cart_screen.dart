import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/product_formatters.dart';
import '../../../../shared/widgets/app_error_snackbar.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/quantity_stepper.dart';
import '../../../../shared/widgets/trust_section.dart';
import '../../../customer/presentation/widgets/cart_smart_recommendations.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Share'),
          ),
        ],
      ),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyStateWidget(
          icon: Icons.error_outline,
          title: 'Could not load cart',
          subtitle: 'Check your connection and try again',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(cartProvider),
        ),
        data: (cart) {
          if (cart == null) {
            return const EmptyStateWidget(
              icon: Icons.login,
              title: 'Sign in to view cart',
              subtitle: 'Your saved items will appear here',
            );
          }
          final items = (cart['items'] as List?) ?? [];
          if (items.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              subtitle: 'Add fresh groceries and essentials to get started',
              actionLabel: 'Start shopping',
              onAction: () => context.go('/home'),
            );
          }

          final discount = _num(cart['discountAmount']);
          final subtotal = _num(cart['subtotal']);
          final deliveryFee = _num(cart['deliveryFee']);
          final freeDeliveryAbove = 499.0;
          final remaining = freeDeliveryAbove - subtotal;

          return Column(
            children: [
              if (discount > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      const Icon(Icons.savings, color: AppColors.successGreen, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'You saved ₹${discount.toStringAsFixed(0)} on this order!',
                        style: const TextStyle(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              if (remaining > 0 && deliveryFee > 0)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: LinearProgressIndicator(
                    value: (subtotal / freeDeliveryAbove).clamp(0, 1),
                    backgroundColor: AppColors.borderLight,
                    color: AppColors.primaryGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              if (remaining > 0 && deliveryFee > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Text(
                    'Add ₹${remaining.toStringAsFixed(0)} more for free delivery',
                    style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    ...items.map((raw) {
                    final item = raw as Map<String, dynamic>;
                    final product = item['product'] as Map<String, dynamic>;
                    final imageUrl = ProductFormatters.imageUrl(product) ?? '';
                    final inStock = ProductFormatters.inStock(product);

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name'] as String? ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${item['unitPrice']} each',
                                  style: const TextStyle(
                                    color: AppColors.primaryGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  inStock ? 'In stock' : 'Low stock',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: inStock
                                        ? AppColors.successGreen
                                        : AppColors.orangeAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          QuantityStepper(
                            quantity: item['quantity'] as int,
                            onDecrement: () {
                              final q = (item['quantity'] as int) - 1;
                              ref.read(cartProvider.notifier).updateQuantity(
                                    item['id'] as String,
                                    q < 1 ? 0 : q,
                                  );
                            },
                            onIncrement: () {
                              ref.read(cartProvider.notifier).updateQuantity(
                                    item['id'] as String,
                                    (item['quantity'] as int) + 1,
                                  );
                            },
                          ),
                        ],
                      ),
                    );
                    }),
                    CartSmartRecommendations(cart: cart),
                  ],
                ),
              ),
              _CouponSection(cart: cart),
              _buildSummary(context, ref, cart),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummary(BuildContext context, WidgetRef ref, Map<String, dynamic> cart) {
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
      child: Column(
        children: [
          _row('Subtotal', cart['subtotal']),
          _row('Discount', cart['discountAmount'], isDiscount: true),
          _row('Delivery', cart['deliveryFee']),
          if ((_num(cart['sameDayFee'])) > 0)
            _row('Same day fee', cart['sameDayFee']),
          const Divider(),
          _row('Total', cart['total'], bold: true),
          const SizedBox(height: AppSpacing.sm),
          const TrustSection(),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                ref.trackEvent(AnalyticsEvents.checkoutStarted);
                context.push('/checkout');
              },
              child: Text('Proceed to checkout • ₹${cart['total']}'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, dynamic value, {bool bold = false, bool isDiscount = false}) {
    final v = _num(value);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
          Text(
            isDiscount && v > 0 ? '-₹${v.toStringAsFixed(0)}' : '₹${v.toStringAsFixed(0)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : null,
              color: bold
                  ? AppColors.primaryGreen
                  : (isDiscount ? AppColors.successGreen : null),
            ),
          ),
        ],
      ),
    );
  }

  double _num(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}

class _CouponSection extends ConsumerStatefulWidget {
  const _CouponSection({required this.cart});

  final Map<String, dynamic> cart;

  @override
  ConsumerState<_CouponSection> createState() => _CouponSectionState();
}

class _CouponSectionState extends ConsumerState<_CouponSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Coupon code (e.g. WELCOME50)',
                isDense: true,
                prefixIcon: Icon(Icons.local_offer_outlined, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: () async {
              if (_controller.text.trim().isEmpty) return;
              try {
                await ref
                    .read(cartProvider.notifier)
                    .applyCoupon(_controller.text.trim());
                ref.trackEvent(AnalyticsEvents.couponApplied, {
                  'code': _controller.text.trim(),
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coupon applied')),
                  );
                }
              } catch (e) {
                if (context.mounted) showAppErrorSnackBar(context, e);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
