import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(dioProvider));
});

class AdminRepository {
  AdminRepository(this._dio);

  final Dio _dio;

  // --- Dashboard ---
  Future<Map<String, dynamic>> getDashboard() async {
    final res = await _dio.get('/admin/dashboard');
    return res.data as Map<String, dynamic>;
  }

  // --- Orders ---
  Future<Map<String, dynamic>> listOrders({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
    String? paymentMethod,
    String? fromDate,
    String? toDate,
    String? sortBy,
    String? sortOrder,
  }) async {
    final res = await _dio.get(
      '/admin/orders',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
        if (paymentMethod != null && paymentMethod.isNotEmpty)
          'paymentMethod': paymentMethod,
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
        if (sortBy != null) 'sortBy': sortBy,
        if (sortOrder != null) 'sortOrder': sortOrder,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getOrder(String id) async {
    final res = await _dio.get('/admin/orders/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateOrderStatus(
    String id, {
    required String status,
    String? note,
    String? cancelledReason,
  }) async {
    final res = await _dio.patch(
      '/admin/orders/$id/status',
      data: {
        'status': status,
        if (note != null) 'note': note,
        if (cancelledReason != null) 'cancelledReason': cancelledReason,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> assignDeliverySlot(
    String orderId,
    String deliverySlotId,
  ) async {
    final res = await _dio.patch(
      '/admin/orders/$orderId/delivery-slot',
      data: {'deliverySlotId': deliverySlotId},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<String> exportOrdersCsv({
    String? search,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    final res = await _dio.get<String>(
      '/admin/orders/export',
      queryParameters: {
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status,
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
      },
      options: Options(responseType: ResponseType.plain),
    );
    return res.data ?? '';
  }

  // --- Users ---
  Future<Map<String, dynamic>> listUsers({
    int page = 1,
    int limit = 20,
    String? search,
    bool? isActive,
  }) async {
    final res = await _dio.get(
      '/admin/users',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (isActive != null) 'isActive': isActive,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getUser(String id) async {
    final res = await _dio.get('/admin/users/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<void> setUserActive(String id, bool isActive) async {
    await _dio.patch('/admin/users/$id/status', data: {'isActive': isActive});
  }

  Future<String> exportUsersCsv({String? search}) async {
    final res = await _dio.get<String>(
      '/admin/users/export',
      queryParameters: {if (search != null) 'search': search},
      options: Options(responseType: ResponseType.plain),
    );
    return res.data ?? '';
  }

  // --- Coupons ---
  Future<List<dynamic>> listCoupons() async {
    final res = await _dio.get('/admin/coupons');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createCoupon(Map<String, dynamic> data) async {
    final res = await _dio.post('/admin/coupons', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateCoupon(
    String id,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.patch('/admin/coupons/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteCoupon(String id) async {
    await _dio.delete('/admin/coupons/$id');
  }

  // --- Banners ---
  Future<List<dynamic>> getBanners() async {
    final res = await _dio.get('/admin/banners');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createBanner(Map<String, dynamic> data) async {
    final res = await _dio.post('/admin/banners', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBanner(
    String id,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.patch('/admin/banners/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteBanner(String id) async {
    await _dio.delete('/admin/banners/$id');
  }

  // --- Inventory ---
  Future<Map<String, dynamic>> listInventory({
    int page = 1,
    int limit = 20,
    String? search,
    bool? lowStock,
  }) async {
    final res = await _dio.get(
      '/admin/inventory',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (lowStock == true) 'lowStock': true,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateStock(
    String productId, {
    required int stock,
    bool? isActive,
  }) async {
    final res = await _dio.patch(
      '/admin/inventory/$productId',
      data: {
        'stock': stock,
        if (isActive != null) 'isActive': isActive,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> bulkUpdateStock(
    List<Map<String, dynamic>> updates,
  ) async {
    final res = await _dio.post(
      '/admin/inventory/bulk',
      data: {'updates': updates},
    );
    return res.data as Map<String, dynamic>;
  }

  // --- Delivery ---
  Future<Map<String, dynamic>> getDeliverySettings() async {
    final res = await _dio.get('/admin/delivery/settings');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateDeliverySettings(
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.patch('/admin/delivery/settings', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> listDeliverySlots() async {
    final res = await _dio.get('/admin/delivery/slots');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createDeliverySlot(
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.post('/admin/delivery/slots', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateDeliverySlot(
    String id,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.patch('/admin/delivery/slots/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteDeliverySlot(String id) async {
    await _dio.delete('/admin/delivery/slots/$id');
  }

  Future<List<dynamic>> listPincodes() async {
    final res = await _dio.get('/admin/delivery/pincodes');
    return res.data as List<dynamic>;
  }

  Future<void> addPincode(String pincode, {String? city}) async {
    await _dio.post(
      '/admin/delivery/pincodes',
      data: {'pincode': pincode, if (city != null) 'city': city},
    );
  }

  Future<void> removePincode(String id) async {
    await _dio.delete('/admin/delivery/pincodes/$id');
  }

  Future<Map<String, dynamic>> deliveryAnalytics() async {
    final res = await _dio.get('/admin/delivery/analytics');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deliveryOperationsAnalytics() async {
    final res = await _dio.get('/admin/delivery/operations-analytics');
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> listDeliveryPartners() async {
    final res = await _dio.get('/admin/delivery/partners');
    return res.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> assignDeliveryPartner({
    required String orderId,
    required String deliveryPartnerId,
    String? notes,
  }) async {
    final res = await _dio.post(
      '/admin/delivery/assign',
      data: {
        'orderId': orderId,
        'deliveryPartnerId': deliveryPartnerId,
        if (notes != null) 'notes': notes,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> reassignDeliveryPartner({
    required String orderId,
    required String deliveryPartnerId,
    String? notes,
  }) async {
    final res = await _dio.patch(
      '/admin/delivery/reassign',
      data: {
        'orderId': orderId,
        'deliveryPartnerId': deliveryPartnerId,
        if (notes != null) 'notes': notes,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  // --- Reports ---
  Future<Map<String, dynamic>> ordersReport({
    String? fromDate,
    String? toDate,
  }) async {
    final res = await _dio.get(
      '/admin/reports/orders',
      queryParameters: {
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> revenueReport({
    String? fromDate,
    String? toDate,
  }) async {
    final res = await _dio.get(
      '/admin/reports/revenue',
      queryParameters: {
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<List<dynamic>> topProductsReport({
    String? fromDate,
    String? toDate,
  }) async {
    final res = await _dio.get(
      '/admin/reports/top-products',
      queryParameters: {
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
      },
    );
    return res.data as List<dynamic>;
  }

  Future<String> exportReport(String type, {String? fromDate, String? toDate}) async {
    final res = await _dio.get<String>(
      '/admin/reports/export/$type',
      queryParameters: {
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
      },
      options: Options(responseType: ResponseType.plain),
    );
    return res.data ?? '';
  }

  // --- Products (existing) ---
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    String? search,
  }) async {
    final res = await _dio.get(
      '/products/admin/all',
      queryParameters: {
        'page': page,
        'limit': 50,
        if (search != null) 'search': search,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getProduct(String id) async {
    final res = await _dio.get('/products/$id');
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    final res = await _dio.post('/products/admin', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProduct(
    String id,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.patch('/products/admin/$id', data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<void> deleteProduct(String id) async {
    await _dio.delete('/products/admin/$id');
  }

  Future<List<dynamic>> getCategories() async {
    final res = await _dio.get('/categories');
    return res.data as List<dynamic>;
  }
}
