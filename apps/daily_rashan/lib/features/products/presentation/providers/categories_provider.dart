import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

/// Top-level categories (with nested subcategories + product counts) for the
/// customer app. Backed by the public `GET /categories` endpoint.
final categoriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/categories');
  final list = (res.data as List?) ?? [];
  return list.cast<Map<String, dynamic>>();
});
