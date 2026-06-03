import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import '../../features/auth/data/auth_repository.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isNotEmpty) return;
  final options = DefaultFirebaseOptions.currentPlatform;
  if (options != null) {
    await Firebase.initializeApp(options: options);
  }
}

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(ref);
});

class PushNotificationService {
  PushNotificationService(this._ref);

  final Ref _ref;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    final options = DefaultFirebaseOptions.currentPlatform;
    if (options == null) {
      debugPrint('Firebase options missing — push notifications disabled');
      return;
    }

    await Firebase.initializeApp(options: options);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    if (!kIsWeb) {
      await _setupLocalNotifications();
      await _requestPermission();
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleNotificationData(initial.data);
    }

    _initialized = true;
    await syncFcmToken();
  }

  Future<void> _setupLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          _handleNotificationData({'orderId': details.payload});
        }
      },
    );

    const channel = AndroidNotificationChannel(
      'daily_rashan_orders',
      'Order Updates',
      description: 'Order status and delivery notifications',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _requestPermission() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> syncFcmToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      final isLoggedIn = await _ref.read(authRepositoryProvider).isLoggedIn();
      if (isLoggedIn) {
        await _ref.read(authRepositoryProvider).updateFcmToken(token);
      }
    } catch (e) {
      debugPrint('FCM token sync failed: $e');
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null || kIsWeb) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_rashan_orders',
          'Order Updates',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF1FA54A),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['orderId'],
    );
  }

  void _onNotificationTap(RemoteMessage message) {
    _handleNotificationData(message.data);
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    final orderId = data['orderId'] as String?;
    if (orderId != null) {
      _ref.read(notificationTapProvider.notifier).state = orderId;
    }
  }
}

/// Set by push handler; router listens to navigate to order detail
final notificationTapProvider = StateProvider<String?>((ref) => null);
