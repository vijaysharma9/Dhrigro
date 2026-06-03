import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/admin_repository.dart';

final adminDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(adminRepositoryProvider).getDashboard();
});

class AdminOrdersQuery {
  const AdminOrdersQuery({
    this.page = 1,
    this.search = '',
    this.status,
    this.paymentMethod,
    this.fromDate,
    this.toDate,
  });

  final int page;
  final String search;
  final String? status;
  final String? paymentMethod;
  final String? fromDate;
  final String? toDate;

  AdminOrdersQuery copyWith({
    int? page,
    String? search,
    String? status,
    String? paymentMethod,
    String? fromDate,
    String? toDate,
  }) {
    return AdminOrdersQuery(
      page: page ?? this.page,
      search: search ?? this.search,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
    );
  }
}

final adminOrdersQueryProvider =
    StateProvider<AdminOrdersQuery>((ref) => const AdminOrdersQuery());

final adminOrdersListProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final query = ref.watch(adminOrdersQueryProvider);
  return ref.read(adminRepositoryProvider).listOrders(
        page: query.page,
        search: query.search,
        status: query.status,
        paymentMethod: query.paymentMethod,
        fromDate: query.fromDate,
        toDate: query.toDate,
      );
});

class AdminUsersQuery {
  const AdminUsersQuery({
    this.page = 1,
    this.search = '',
    this.isActive,
  });

  final int page;
  final String search;
  final bool? isActive;

  AdminUsersQuery copyWith({int? page, String? search, bool? isActive}) {
    return AdminUsersQuery(
      page: page ?? this.page,
      search: search ?? this.search,
      isActive: isActive ?? this.isActive,
    );
  }
}

final adminUsersQueryProvider =
    StateProvider<AdminUsersQuery>((ref) => const AdminUsersQuery());

final adminUsersListProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final query = ref.watch(adminUsersQueryProvider);
  return ref.read(adminRepositoryProvider).listUsers(
        page: query.page,
        search: query.search,
        isActive: query.isActive,
      );
});

class AdminInventoryQuery {
  const AdminInventoryQuery({
    this.page = 1,
    this.search = '',
    this.lowStock = false,
  });

  final int page;
  final String search;
  final bool lowStock;

  AdminInventoryQuery copyWith({int? page, String? search, bool? lowStock}) {
    return AdminInventoryQuery(
      page: page ?? this.page,
      search: search ?? this.search,
      lowStock: lowStock ?? this.lowStock,
    );
  }
}

final adminInventoryQueryProvider =
    StateProvider<AdminInventoryQuery>((ref) => const AdminInventoryQuery());

final adminInventoryListProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final query = ref.watch(adminInventoryQueryProvider);
  return ref.read(adminRepositoryProvider).listInventory(
        page: query.page,
        search: query.search,
        lowStock: query.lowStock ? true : null,
      );
});

final adminCouponsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.read(adminRepositoryProvider).listCoupons();
});

final adminDeliverySlotsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.read(adminRepositoryProvider).listDeliverySlots();
});

final adminDeliverySettingsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(adminRepositoryProvider).getDeliverySettings();
});

final adminStaffRoleProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.role;
});

/// Debounced search notifier helper
class DebouncedSearch {
  DebouncedSearch(this.onChanged, {this.duration = const Duration(milliseconds: 400)});

  final void Function(String) onChanged;
  final Duration duration;
  Timer? _timer;

  void call(String value) {
    _timer?.cancel();
    _timer = Timer(duration, () => onChanged(value));
  }

  void dispose() => _timer?.cancel();
}
