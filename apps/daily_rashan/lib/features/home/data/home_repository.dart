import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(dioProvider));
});

class HomeRepository {
  HomeRepository(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> getHomeData() async {
    final response = await _dio.get('/home');
    return response.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> getRecentOrders() async {
    final response = await _dio.get('/home/recent-orders');
    return (response.data['recentOrders'] as List?) ?? [];
  }
}
