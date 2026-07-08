import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/customer/customer_prefs_provider.dart';

class SearchParams {
  const SearchParams({
    this.query = '',
    this.categoryId,
    this.sortBy,
    this.page = 1,
  });

  final String query;
  final String? categoryId;
  final String? sortBy;
  final int page;

  @override
  bool operator ==(Object other) =>
      other is SearchParams &&
      other.query == query &&
      other.categoryId == categoryId &&
      other.sortBy == sortBy &&
      other.page == page;

  @override
  int get hashCode => Object.hash(query, categoryId, sortBy, page);
}

final searchResultsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>, SearchParams>((ref, params) async {
  final dio = ref.read(dioProvider);
  final res = await dio.get('/products', queryParameters: {
    if (params.query.isNotEmpty) 'search': params.query,
    if (params.categoryId != null) 'categoryId': params.categoryId,
    if (params.sortBy != null) 'sortBy': params.sortBy,
    'page': params.page,
    'limit': 20,
  });

  if (params.query.isNotEmpty) {
    await ref.read(customerPrefsProvider.notifier).addSearchTerm(params.query);
  }

  return res.data as Map<String, dynamic>;
});

const trendingSearches = [
  'Milk',
  'Tomatoes',
  'Atta',
  'Bread',
  'Eggs',
  'Banana',
  'Rice',
  'Paneer',
];
