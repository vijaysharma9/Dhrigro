import 'package:dio/dio.dart';

import '../network/api_exception.dart';

/// Safe JSON parsing helpers for admin API responses.
class AdminApiUtils {
  AdminApiUtils._();

  static Map<String, dynamic> asMap(dynamic data, {String context = 'response'}) {
    if (data is! Map) {
      throw FormatException('Expected map for $context, got ${data.runtimeType}');
    }
    return Map<String, dynamic>.fromEntries(
      data.entries.map(
        (e) => MapEntry(e.key.toString(), _deepConvert(e.value)),
      ),
    );
  }

  static Map<String, dynamic>? asMapOrNull(dynamic data) {
    if (data == null) return null;
    return asMap(data);
  }

  static dynamic _deepConvert(dynamic value) {
    if (value is Map) return asMap(value);
    if (value is List) return value.map(_deepConvert).toList();
    return value;
  }

  static List<Map<String, dynamic>> asMapList(dynamic data) {
    if (data == null) return [];
    if (data is! List) return [];
    return data.whereType<Map>().map(asMap).toList();
  }

  /// Normalizes paginated API envelopes: `{ data: [...], meta: {...} }`.
  static Map<String, dynamic> parsePaginatedEnvelope(dynamic data) {
    final envelope = asMap(data);
    return {
      if (envelope.containsKey('success')) 'success': envelope['success'],
      'data': asMapList(envelope['data']),
      'meta': asMapOrNull(envelope['meta']) ?? <String, dynamic>{},
    };
  }

  static List<dynamic> asList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data;
    return [];
  }

  static int asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double asDouble(dynamic value, {double fallback = 0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static String asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  static PaginatedResponse parsePaginated(dynamic data) {
    final map = asMap(data);
    return PaginatedResponse(
      data: asMapList(map['data']),
      total: asInt(map['meta']?['total']),
      page: asInt(map['meta']?['page'], fallback: 1),
      limit: asInt(map['meta']?['limit'], fallback: 20),
      totalPages: asInt(map['meta']?['totalPages'], fallback: 1),
    );
  }

  static String dioMessage(Object error) {
    if (error is ApiException) return error.message;
    if (error is DioException) {
      final inner = error.error;
      if (inner is ApiException) return inner.message;

      final data = error.response?.data;
      if (data is Map) {
        final msg = data['message'];
        if (msg is String && msg.isNotEmpty) return msg;
        if (msg is List && msg.isNotEmpty) return msg.join(', ');
      }
      return ApiException.friendlyDioMessage(error);
    }
    final text = error.toString().replaceFirst('Exception: ', '');
    if (text.contains('XMLHttpRequest') || text.contains('NetworkError')) {
      return 'Cannot reach the API server. Start the backend and retry.';
    }
    return text;
  }
}

class PaginatedResponse {
  const PaginatedResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final List<Map<String, dynamic>> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
}

class OrdersReport {
  const OrdersReport({required this.totalOrders, required this.totalRevenue});

  final int totalOrders;
  final double totalRevenue;

  factory OrdersReport.fromJson(Map<String, dynamic> json) => OrdersReport(
        totalOrders: AdminApiUtils.asInt(json['totalOrders']),
        totalRevenue: AdminApiUtils.asDouble(json['totalRevenue']),
      );
}

class RevenueReport {
  const RevenueReport({
    required this.totalRevenue,
    required this.totalOrders,
    required this.byDay,
  });

  final double totalRevenue;
  final int totalOrders;
  final List<RevenueDayPoint> byDay;

  factory RevenueReport.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'];
    final summaryMap = summary is Map ? Map<String, dynamic>.from(summary) : <String, dynamic>{};
    return RevenueReport(
      totalRevenue: AdminApiUtils.asDouble(summaryMap['totalRevenue']),
      totalOrders: AdminApiUtils.asInt(summaryMap['totalOrders']),
      byDay: AdminApiUtils.asMapList(json['byDay'])
          .map(RevenueDayPoint.fromJson)
          .toList(),
    );
  }
}

class RevenueDayPoint {
  const RevenueDayPoint({
    required this.date,
    required this.revenue,
    required this.orders,
  });

  final String date;
  final double revenue;
  final int orders;

  factory RevenueDayPoint.fromJson(Map<String, dynamic> json) => RevenueDayPoint(
        date: AdminApiUtils.asString(json['date']),
        revenue: AdminApiUtils.asDouble(json['revenue']),
        orders: AdminApiUtils.asInt(json['orders']),
      );
}

class TopProductReport {
  const TopProductReport({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.revenue,
  });

  final String productId;
  final String productName;
  final int quantitySold;
  final double revenue;

  factory TopProductReport.fromJson(Map<String, dynamic> json) => TopProductReport(
        productId: AdminApiUtils.asString(json['productId']),
        productName: AdminApiUtils.asString(json['productName']),
        quantitySold: AdminApiUtils.asInt(
          json['quantitySold'] ?? json['_sum']?['quantity'],
        ),
        revenue: AdminApiUtils.asDouble(
          json['revenue'] ?? json['_sum']?['totalPrice'],
        ),
      );
}
