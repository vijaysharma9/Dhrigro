import 'package:dio/dio.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;

  static ApiException fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      final msg = data['message'];
      return ApiException(
        msg is List ? msg.join(', ') : msg.toString(),
        statusCode: e.response?.statusCode,
        code: data['code'] as String?,
      );
    }
    return ApiException(
      e.message ?? 'Network error',
      statusCode: e.response?.statusCode,
    );
  }
}
