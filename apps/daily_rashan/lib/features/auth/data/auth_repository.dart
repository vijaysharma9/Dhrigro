import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/dio_client.dart';
import '../../../shared/providers/storage_provider.dart';
import 'models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
  );
});

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<AuthResponse> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        'password': password,
      });
      final auth = AuthResponse.fromJson(response.data as Map<String, dynamic>);
      await _saveTokens(auth);
      return auth;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AuthResponse> register({
    required String phone,
    required String password,
    required String name,
    String? email,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'phone': phone,
        'password': password,
        'name': name,
        if (email != null) 'email': email,
      });
      final auth = AuthResponse.fromJson(response.data as Map<String, dynamic>);
      await _saveTokens(auth);
      return auth;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> requestOtp(String phone) async {
    try {
      await _dio.post('/auth/otp/request', data: {'phone': phone});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<AuthResponse> verifyOtp(String phone, String otp) async {
    try {
      final response = await _dio.post('/auth/otp/verify', data: {
        'phone': phone,
        'otp': otp,
      });
      final auth = AuthResponse.fromJson(response.data as Map<String, dynamic>);
      await _saveTokens(auth);
      return auth;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> forgotPassword({String? email, String? phone}) async {
    try {
      await _dio.post('/auth/forgot-password', data: {
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    try {
      await _dio.post('/auth/reset-password', data: {
        'phone': phone,
        'otp': otp,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<UserModel?> getProfile() async {
    try {
      final response = await _dio.get('/auth/profile');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return null;
      throw ApiException.fromDio(e);
    }
  }

  Future<void> logout() async {
    try {
      final refresh = await _storage.read(key: StorageKeys.refreshToken);
      await _dio.post('/auth/logout', data: {'refreshToken': refresh});
    } catch (_) {}
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: StorageKeys.accessToken);
    return token != null && token.isNotEmpty;
  }

  Future<void> updateFcmToken(String fcmToken) async {
    try {
      await _dio.post('/auth/fcm-token', data: {'fcmToken': fcmToken});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> _saveTokens(AuthResponse auth) async {
    await _storage.write(
      key: StorageKeys.accessToken,
      value: auth.accessToken,
    );
    await _storage.write(
      key: StorageKeys.refreshToken,
      value: auth.refreshToken,
    );
    await _storage.write(key: StorageKeys.userId, value: auth.user.id);
    await _storage.write(key: StorageKeys.userRole, value: auth.user.role);
  }
}
