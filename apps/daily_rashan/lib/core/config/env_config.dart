import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment { development, staging, production }

class EnvConfig {
  EnvConfig._();

  static AppEnvironment _env = AppEnvironment.development;

  static AppEnvironment get environment => _env;

  static bool get isProduction => _env == AppEnvironment.production;

  static Future<void> load() async {
    const envName = String.fromEnvironment('ENV', defaultValue: 'development');
    _env = AppEnvironment.values.firstWhere(
      (e) => e.name == envName,
      orElse: () => AppEnvironment.development,
    );

    final candidates = [
      '.env.$envName',
      if (kReleaseMode) '.env.production' else '.env.development',
      '.env',
    ];

    for (final file in candidates) {
      try {
        await dotenv.load(fileName: file);
        return;
      } catch (_) {
        continue;
      }
    }
  }

  static void validate() {
    if (apiBaseUrl.isEmpty) {
      throw StateError('API_BASE_URL is required');
    }
  }

  static String get apiBaseUrl {
    final configured = dotenv.env['API_BASE_URL'] ??
        const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://localhost:3000/api/v1',
        );
    // Web admin/customer runs in the browser on the same machine as the API in dev.
    if (kIsWeb && configured.contains('192.168.')) {
      return configured.replaceFirst(
        RegExp(r'http://192\.168\.\d+\.\d+'),
        'http://localhost',
      );
    }
    if (kIsWeb) return configured;
    if (defaultTargetPlatform == TargetPlatform.android &&
        configured.contains('localhost')) {
      return configured.replaceAll('localhost', '10.0.2.2');
    }
    return configured;
  }

  static String get appName => dotenv.env['APP_NAME'] ?? 'Dhrigro';

  static String get razorpayKeyId => dotenv.env['RAZORPAY_KEY_ID'] ?? '';

  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';

  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';

  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';

  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';

  static bool get enableApiLogging =>
      !isProduction && dotenv.env['ENABLE_API_LOGGING'] != 'false';

  static String get realtimeBaseUrl {
    final configured = dotenv.env['REALTIME_URL'];
    if (configured != null && configured.isNotEmpty) return configured;
    return apiBaseUrl.replaceFirst(RegExp(r'/api/v\d+$'), '');
  }

  static bool get realtimeEnabled =>
      dotenv.env['REALTIME_ENABLED'] != 'false';
}
