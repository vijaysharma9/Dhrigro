import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

final cartProvider =
    AsyncNotifierProvider<CartNotifier, Map<String, dynamic>?>(CartNotifier.new);

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
    ref.invalidateSelf();
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
