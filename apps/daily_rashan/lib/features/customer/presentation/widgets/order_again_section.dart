import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/customer/reorder_engine.dart';
import '../../../../shared/widgets/premium_product_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/app_success_snackbar.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

/// Smart reorder — last order + frequent products + reorder all.
class OrderAgainSection extends ConsumerWidget {
  const OrderAgainSection({
    super.key,
    required this.orders,
    required this.quantities,
  });

  final List<dynamic> orders;
  final Map<String, int> quantities;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final frequent = ReorderEngine.extractFrequentProducts(orders);
    final lastOrder = ReorderEngine.lastOrderBundle(orders);
    if (frequent.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Order again',
          onSeeAll: lastOrder != null
              ? () => _showReorderSheet(context, ref, lastOrder)
              : null,
        ),
        if (lastOrder != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.orangeAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.orangeAccent.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.replay, color: AppColors.orangeAccent),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last order · ${lastOrder.orderNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${lastOrder.items.length} items',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: () => _reorderAll(ref, context, lastOrder),
                    child: const Text('Reorder all'),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(
          height: PremiumProductCard.horizontalListHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: frequent.length,
            itemBuilder: (_, i) {
              final item = frequent[i];
              final product = item.toProductMap();
              final id = item.productId;
              final qty = quantities[id] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: PremiumProductCard(
                  product: product,
                  quantity: qty,
                  showOrderCount: item.quantity,
                  onAddToCart: () {
                    ref.read(cartProvider.notifier).addItem(id);
                    ref.trackEvent(AnalyticsEvents.reorderItem, {'product_id': id});
                    showSuccessSnackBar(context, '${item.productName} added');
                  },
                  onIncrement: () =>
                      ref.read(cartProvider.notifier).addOrIncrement(id),
                  onDecrement: () =>
                      ref.read(cartProvider.notifier).decrementProduct(id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _reorderAll(
    WidgetRef ref,
    BuildContext context,
    ReorderBundle bundle,
  ) async {
    final notifier = ref.read(cartProvider.notifier);
    for (final item in bundle.items) {
      await notifier.addItem(item.productId, quantity: item.quantity);
    }
    ref.trackEvent(AnalyticsEvents.reorderAll, {'order_id': bundle.orderId});
    if (context.mounted) {
      showSuccessSnackBar(context, 'Added ${bundle.items.length} items to cart');
    }
  }

  void _showReorderSheet(
    BuildContext context,
    WidgetRef ref,
    ReorderBundle bundle,
  ) {
    final selected = bundle.items.map((e) => e.productId).toSet();

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Reorder from ${bundle.orderNumber}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: AppSpacing.md),
                ...bundle.items.map((item) {
                  final checked = selected.contains(item.productId);
                  return CheckboxListTile(
                    value: checked,
                    onChanged: (v) {
                      setModalState(() {
                        if (v == true) {
                          selected.add(item.productId);
                        } else {
                          selected.remove(item.productId);
                        }
                      });
                    },
                    title: Text(item.productName),
                    subtitle: Text('Qty: ${item.quantity}'),
                  );
                }),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () async {
                          final notifier = ref.read(cartProvider.notifier);
                          for (final item in bundle.items) {
                            if (selected.contains(item.productId)) {
                              await notifier.addItem(
                                item.productId,
                                quantity: item.quantity,
                              );
                            }
                          }
                          ref.trackEvent(AnalyticsEvents.reorderAll, {
                            'order_id': bundle.orderId,
                            'selected_count': selected.length,
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            showSuccessSnackBar(
                              context,
                              'Added ${selected.length} items to cart',
                            );
                          }
                        },
                  child: Text('Add ${selected.length} items to cart'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
