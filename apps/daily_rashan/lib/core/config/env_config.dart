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

  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ??
      const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'http://localhost:3000/api/v1',
      );

  static String get appName => dotenv.env['APP_NAME'] ?? 'Daily Rashan';

  static String get razorpayKeyId => dotenv.env['RAZORPAY_KEY_ID'] ?? '';

  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';

  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';

  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';

  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';

  static bool get enableApiLogging =>
      !isProduction && dotenv.env['ENABLE_API_LOGGING'] != 'false';
}
