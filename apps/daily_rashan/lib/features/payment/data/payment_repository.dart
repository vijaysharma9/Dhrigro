import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(dioProvider));
});

class PaymentRepository {
  PaymentRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> createRazorpayOrder(String orderId) async {
    try {
      final res = await _dio.post(
        '/payments/razorpay/create-order',
        data: {'orderId': orderId},
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> verifyRazorpayPayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final res = await _dio.post(
        '/payments/razorpay/verify',
        data: {
          'orderId': orderId,
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
        },
      );
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> reportPaymentFailed(String orderId, {String? reason}) async {
    try {
      await _dio.post(
        '/payments/razorpay/failed',
        data: {'orderId': orderId, if (reason != null) 'reason': reason},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> placeOrder({
    required String addressId,
    required String deliveryType,
    required String paymentMethod,
    String? deliveryInstructions,
    String? deliverySlotId,
  }) async {
    try {
      final res = await _dio.post('/orders', data: {
        'addressId': addressId,
        'deliveryType': deliveryType,
        'paymentMethod': paymentMethod,
        if (deliveryInstructions != null && deliveryInstructions.isNotEmpty)
          'deliveryInstructions': deliveryInstructions,
        if (deliverySlotId != null) 'deliverySlotId': deliverySlotId,
      });
      return res.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
