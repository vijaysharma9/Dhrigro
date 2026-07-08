import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/firebase/push_notification_service.dart';
import '../../data/auth_repository.dart';
import '../../data/models/user_model.dart';

final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      if (!await repo.isLoggedIn()) return null;
      try {
        return await repo.getProfile();
      } catch (_) {
        try {
          await repo.logout();
        } catch (_) {}
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _syncPushIfAvailable() async {
    if (kIsWeb) return;
    try {
      await ref.read(pushNotificationServiceProvider).syncFcmToken();
    } catch (_) {}
  }

  Future<void> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final auth = await ref.read(authRepositoryProvider).login(
            email: email,
            phone: phone,
            password: password,
          );
      await _syncPushIfAvailable();
      state = AsyncData(auth.user);
    } catch (e) {
      state = const AsyncData(null);
      rethrow;
    }
  }

  Future<void> register({
    required String phone,
    required String password,
    required String name,
    String? email,
  }) async {
    state = const AsyncLoading();
    try {
      final auth = await ref.read(authRepositoryProvider).register(
            phone: phone,
            password: password,
            name: name,
            email: email,
          );
      await _syncPushIfAvailable();
      state = AsyncData(auth.user);
    } catch (e) {
      state = const AsyncData(null);
      rethrow;
    }
  }

  Future<void> verifyOtp(String phone, String otp) async {
    state = const AsyncLoading();
    try {
      final auth =
          await ref.read(authRepositoryProvider).verifyOtp(phone, otp);
      await _syncPushIfAvailable();
      state = AsyncData(auth.user);
    } catch (e) {
      state = const AsyncData(null);
      rethrow;
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
