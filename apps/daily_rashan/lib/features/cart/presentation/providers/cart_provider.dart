import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/network/dio_client.dart';

final cartProvider =
    AsyncNotifierProvider<CartNotifier, Map<String, dynamic>?>(CartNotifier.new);

/// Product id → quantity in cart (for steppers on home/search).
final cartQuantitiesProvider = Provider<Map<String, int>>((ref) {
  final cart = ref.watch(cartProvider).valueOrNull;
  if (cart == null) return {};
  final items = (cart['items'] as List?) ?? [];
  final map = <String, int>{};
  for (final raw in items) {
    final item = raw as Map<String, dynamic>;
    final product = item['product'] as Map<String, dynamic>?;
    final productId = product?['id'] as String?;
    if (productId != null) {
      map[productId] = item['quantity'] as int? ?? 0;
    }
  }
  return map;
});

final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider).valueOrNull;
  if (cart == null) return 0;
  final items = (cart['items'] as List?) ?? [];
  return items.fold<int>(
    0,
    (sum, item) => sum + ((item as Map)['quantity'] as int? ?? 0),
  );
});

class CartNotifier extends AsyncNotifier<Map<String, dynamic>?> {
  @override
  Future<Map<String, dynamic>?> build() async {
    return _fetchCart();
  }

  Future<Map<String, dynamic>?> _fetchCart() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/cart');
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      rethrow;
    }
  }

  Future<void> addItem(String productId, {int quantity = 1, String? variantId}) async {
    final dio = ref.read(dioProvider);
    await dio.post('/cart/items', data: {
      'productId': productId,
      'quantity': quantity,
      if (variantId != null) 'variantId': variantId,
    });
    ref.read(analyticsServiceProvider).track(AnalyticsEvents.addToCart, {
      'product_id': productId,
      'quantity': quantity,
    });
    ref.invalidateSelf();
  }

  Future<void> addOrIncrement(String productId) async {
    final cart = state.valueOrNull;
    final items = (cart?['items'] as List?) ?? [];
    for (final raw in items) {
      final item = raw as Map<String, dynamic>;
      final product = item['product'] as Map<String, dynamic>?;
      if (product?['id'] == productId) {
        await updateQuantity(
          item['id'] as String,
          (item['quantity'] as int) + 1,
        );
        return;
      }
    }
    await addItem(productId);
  }

  Future<void> decrementProduct(String productId) async {
    final cart = state.valueOrNull;
    final items = (cart?['items'] as List?) ?? [];
    for (final raw in items) {
      final item = raw as Map<String, dynamic>;
      final product = item['product'] as Map<String, dynamic>?;
      if (product?['id'] == productId) {
        final q = (item['quantity'] as int) - 1;
        await updateQuantity(item['id'] as String, q < 1 ? 0 : q);
        return;
      }
    }
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    final dio = ref.read(dioProvider);
    await dio.patch('/cart/items/$itemId', data: {'quantity': quantity});
    ref.invalidateSelf();
  }

  Future<void> removeItem(String itemId) async {
    final dio = ref.read(dioProvider);
    await dio.delete('/cart/items/$itemId');
    ref.invalidateSelf();
  }

  Future<void> applyCoupon(String code) async {
    final dio = ref.read(dioProvider);
    await dio.post('/cart/coupon', data: {'code': code});
    ref.invalidateSelf();
  }
}
