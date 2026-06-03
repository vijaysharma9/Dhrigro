import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/delivery_repository.dart';

final deliveryProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(deliveryRepositoryProvider).getProfile();
});

final deliveryAssignedProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(deliveryRepositoryProvider).listAssigned();
});

final deliveryHistoryProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(deliveryRepositoryProvider).listHistory();
});

final deliveryEarningsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(deliveryRepositoryProvider).getEarnings();
});
