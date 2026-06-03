import 'package:dio/dio.dart';
import 'api_exception.dart';

/// Maps API errors to [ApiException] with optional error codes from backend.
class ApiErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(
      err.copyWith(error: ApiException.fromDio(err)),
    );
  }
}
