import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/home_repository.dart';

final homeDataProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(homeRepositoryProvider).getHomeData();
});

final recentOrdersProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(homeRepositoryProvider).getRecentOrders();
});
