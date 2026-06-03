import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepository(ref.watch(dioProvider));
});

class DeliveryRepository {
  DeliveryRepository(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getProfile() async {
    final res = await _dio.get('/delivery/profile');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final res = await _dio.patch('/delivery/profile', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAvailability({
    bool? isOnline,
    bool? isAvailable,
  }) async {
    final res = await _dio.patch(
      '/delivery/availability',
      data: {
        if (isOnline != null) 'isOnline': isOnline,
        if (isAvailable != null) 'isAvailable': isAvailable,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> listAssigned({int page = 1}) async {
    final res = await _dio.get(
      '/delivery/orders/assigned',
      queryParameters: {'page': page, 'limit': 20},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> listHistory({int page = 1}) async {
    final res = await _dio.get(
      '/delivery/orders/history',
      queryParameters: {'page': page, 'limit': 20},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getOrder(String orderId) async {
    final res = await _dio.get('/delivery/orders/$orderId');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> acceptOrder(String orderId) async {
    final res = await _dio.patch('/delivery/orders/$orderId/accept');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> pickOrder(String orderId) async {
    final res = await _dio.patch('/delivery/orders/$orderId/pick');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> startOrder(String orderId) async {
    final res = await _dio.patch('/delivery/orders/$orderId/start');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deliverOrder(String orderId, String otp) async {
    final res = await _dio.patch(
      '/delivery/orders/$orderId/deliver',
      data: {'otp': otp},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<void> resendOtp(String orderId) async {
    await _dio.post('/delivery/orders/$orderId/resend-otp');
  }

  Future<Map<String, dynamic>> getEarnings() async {
    final res = await _dio.get('/delivery/earnings');
    return res.data as Map<String, dynamic>;
  }
}
