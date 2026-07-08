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
      friendlyDioMessage(e),
      statusCode: e.response?.statusCode,
    );
  }

  /// User-facing message for any caught error (API, network, or unknown).
  static String friendlyMessage(Object error) {
    if (error is ApiException) return error.message;
    if (error is DioException) {
      final inner = error.error;
      if (inner is ApiException) return inner.message;
      return friendlyDioMessage(error);
    }
    final text = error.toString();
    if (text.startsWith('Exception: ')) {
      final trimmed = text.replaceFirst('Exception: ', '');
      if (trimmed.isNotEmpty) return trimmed;
    }
    if (text.contains('XMLHttpRequest') || text.contains('NetworkError')) {
      return 'Cannot reach the API server. Check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  static String friendlyDioMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Check your connection and try again.';
      case DioExceptionType.connectionError:
        return 'Cannot reach the API server. Start the backend on port 3000 and retry.';
      case DioExceptionType.badResponse:
        return 'Server error (${e.response?.statusCode ?? 'unknown'})';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed.';
      case DioExceptionType.unknown:
        final raw = e.message ?? '';
        if (raw.contains('XMLHttpRequest') ||
            raw.contains('NetworkError') ||
            raw.contains('Failed host lookup')) {
          return 'Cannot reach the API server. Ensure the backend is running at ${e.requestOptions.baseUrl}';
        }
        return raw.isNotEmpty ? raw : 'Network request failed';
    }
  }
}
