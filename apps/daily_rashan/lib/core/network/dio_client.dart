import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../config/env_config.dart';
import 'api_error_interceptor.dart';
import 'api_exception.dart';
export 'api_exception.dart';
import '../../shared/providers/storage_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: EnvConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(ApiErrorInterceptor());

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await storage.read(key: StorageKeys.accessToken);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final refreshToken = await storage.read(key: StorageKeys.refreshToken);
          if (refreshToken != null) {
            try {
              final refreshDio = Dio(BaseOptions(baseUrl: EnvConfig.apiBaseUrl));
              final response = await refreshDio.post(
                '/auth/refresh',
                data: {'refreshToken': refreshToken},
              );
              final newAccess = response.data['accessToken'] as String?;
              final newRefresh = response.data['refreshToken'] as String?;
              if (newAccess != null) {
                await storage.write(
                  key: StorageKeys.accessToken,
                  value: newAccess,
                );
                if (newRefresh != null) {
                  await storage.write(
                    key: StorageKeys.refreshToken,
                    value: newRefresh,
                  );
                }
                error.requestOptions.headers['Authorization'] =
                    'Bearer $newAccess';
                final retry = await dio.fetch(error.requestOptions);
                return handler.resolve(retry);
              }
            } catch (_) {
              await storage.deleteAll();
            }
          }
        }
        handler.next(error);
      },
    ),
  );

  if (EnvConfig.enableApiLogging) {
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseBody: true,
        enabled: true,
      ),
    );
  }

  return dio;
});
