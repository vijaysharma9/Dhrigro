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
    if (!await repo.isLoggedIn()) return null;
    return repo.getProfile();
  }

  Future<void> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final auth = await ref.read(authRepositoryProvider).login(
            email: email,
            phone: phone,
            password: password,
          );
      final user = auth.user;
      await ref.read(pushNotificationServiceProvider).syncFcmToken();
      return user;
    });
  }

  Future<void> register({
    required String phone,
    required String password,
    required String name,
    String? email,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final auth = await ref.read(authRepositoryProvider).register(
            phone: phone,
            password: password,
            name: name,
            email: email,
          );
      final user = auth.user;
      await ref.read(pushNotificationServiceProvider).syncFcmToken();
      return user;
    });
  }

  Future<void> verifyOtp(String phone, String otp) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final auth =
          await ref.read(authRepositoryProvider).verifyOtp(phone, otp);
      final user = auth.user;
      await ref.read(pushNotificationServiceProvider).syncFcmToken();
      return user;
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
