import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/admin/admin_api_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/admin_repository.dart';

final adminDashboardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(adminRepositoryProvider).getDashboard();
});

enum OrderOpsFilter {
  none,
  delayed,
  unassigned,
  codToday,
  failedPayments,
  highValue,
}

class AdminOrdersQuery {
  const AdminOrdersQuery({
    this.page = 1,
    this.search = '',
    this.status,
    this.paymentMethod,
    this.fromDate,
    this.toDate,
    this.opsFilter = OrderOpsFilter.none,
  });

  final int page;
  final String search;
  final String? status;
  final String? paymentMethod;
  final String? fromDate;
  final String? toDate;
  final OrderOpsFilter opsFilter;

  AdminOrdersQuery copyWith({
    int? page,
    String? search,
    String? status,
    String? paymentMethod,
    String? fromDate,
    String? toDate,
    OrderOpsFilter? opsFilter,
    bool clearStatus = false,
    bool clearPayment = false,
  }) {
    return AdminOrdersQuery(
      page: page ?? this.page,
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      paymentMethod: clearPayment ? null : (paymentMethod ?? this.paymentMethod),
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      opsFilter: opsFilter ?? this.opsFilter,
    );
  }

  static AdminOrdersQuery preset(OrderOpsFilter filter) {
    final today = DateTime.now().toIso8601String().split('T').first;
    return switch (filter) {
      OrderOpsFilter.codToday => AdminOrdersQuery(
          opsFilter: filter,
          paymentMethod: 'COD',
          fromDate: today,
          toDate: today,
        ),
      OrderOpsFilter.failedPayments => AdminOrdersQuery(
          opsFilter: filter,
        ),
      _ => AdminOrdersQuery(opsFilter: filter),
    };
  }
}

List<Map<String, dynamic>> applyOrderOpsFilter(
  List<Map<String, dynamic>> rows,
  OrderOpsFilter filter,
) {
  if (filter == OrderOpsFilter.none) return rows;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  return rows.where((o) {
    switch (filter) {
      case OrderOpsFilter.delayed:
        final status = o['status'] as String? ?? '';
        if (status != 'PENDING' && status != 'CONFIRMED') return false;
        final placed = DateTime.tryParse(o['placedAt'] as String? ?? '');
        return placed != null && now.difference(placed).inHours > 2;
      case OrderOpsFilter.unassigned:
        final status = o['status'] as String? ?? '';
        return o['assignment'] == null &&
            (status == 'CONFIRMED' || status == 'PACKED');
      case OrderOpsFilter.failedPayments:
        return o['paymentStatus'] == 'FAILED';
      case OrderOpsFilter.highValue:
        return ((o['totalAmount'] as num?) ?? 0) >= 1000;
      case OrderOpsFilter.codToday:
        final placed = DateTime.tryParse(o['placedAt'] as String? ?? '');
        if (placed == null) return false;
        final d = DateTime(placed.year, placed.month, placed.day);
        return o['paymentMethod'] == 'COD' && d == today;
      case OrderOpsFilter.none:
        return true;
    }
  }).toList();
}

final adminOrderSelectionProvider = StateProvider<Set<String>>((ref) => {});

final adminDeliveryBoardProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(adminRepositoryProvider).listOrders(page: 1, limit: 100);
});

final adminOrdersListProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final query = ref.watch(adminOrdersQueryProvider);
  final res = await ref.read(adminRepositoryProvider).listOrders(
        page: query.page,
        search: query.search,
        status: query.status,
        paymentMethod: query.paymentMethod,
        fromDate: query.fromDate,
        toDate: query.toDate,
      );
  final filtered = applyOrderOpsFilter(
    AdminApiUtils.asMapList(res['data']),
    query.opsFilter,
  );
  final meta = AdminApiUtils.asMapOrNull(res['meta']) ?? <String, dynamic>{};
  return {
    ...res,
    'data': filtered,
    'meta': {...meta, 'filteredCount': filtered.length},
  };
});

final adminOrdersQueryProvider =
    StateProvider<AdminOrdersQuery>((ref) => const AdminOrdersQuery());

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
    this.fastMoving = false,
  });

  final int page;
  final String search;
  final bool lowStock;
  final bool fastMoving;

  AdminInventoryQuery copyWith({
    int? page,
    String? search,
    bool? lowStock,
    bool? fastMoving,
  }) {
    return AdminInventoryQuery(
      page: page ?? this.page,
      search: search ?? this.search,
      lowStock: lowStock ?? this.lowStock,
      fastMoving: fastMoving ?? this.fastMoving,
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
      ).then((res) {
    if (!query.fastMoving) return res;
    final data = AdminApiUtils.asMapList(res['data']);
    final filtered = data.where((p) => (p['stock'] as int? ?? 0) <= 30).toList();
    return {...res, 'data': filtered};
  });
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

class AdminProductsQuery {
  const AdminProductsQuery({
    this.page = 1,
    this.limit = 50,
    this.search = '',
    this.categoryId,
    this.isFeatured,
  });

  final int page;
  final int limit;
  final String search;
  final String? categoryId;
  final bool? isFeatured;

  AdminProductsQuery copyWith({
    int? page,
    int? limit,
    String? search,
    String? categoryId,
    bool? isFeatured,
    bool clearFeatured = false,
  }) {
    return AdminProductsQuery(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      categoryId: categoryId ?? this.categoryId,
      isFeatured: clearFeatured ? null : (isFeatured ?? this.isFeatured),
    );
  }
}

final adminProductsQueryProvider =
    StateProvider<AdminProductsQuery>((ref) => const AdminProductsQuery());

final adminProductsProvider =
    FutureProvider.autoDispose<PaginatedResponse>((ref) async {
  final query = ref.watch(adminProductsQueryProvider);
  return ref.read(adminRepositoryProvider).getProducts(
        page: query.page,
        limit: query.limit,
        search: query.search,
        categoryId: query.categoryId,
        isFeatured: query.isFeatured,
      );
});

final adminCategoriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final list = await ref.read(adminRepositoryProvider).getCategories();
  return AdminApiUtils.asMapList(list);
});

final adminCategoryAnalyticsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  return ref.read(adminRepositoryProvider).getCategoryAnalytics();
});

final adminDeliveryOpsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  try {
    return await ref.read(adminRepositoryProvider).deliveryOperationsAnalytics();
  } catch (_) {
    return await ref.read(adminRepositoryProvider).deliveryAnalytics();
  }
});

final adminPartnersProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.read(adminRepositoryProvider).listDeliveryPartners();
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
