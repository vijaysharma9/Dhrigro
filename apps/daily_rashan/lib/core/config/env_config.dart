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

    // Vercel/production builds inject config via --dart-define, not asset bundles.
    if (kReleaseMode || _env == AppEnvironment.production) {
      dotenv.testLoad(mergeWith: _compileTimeDefaults);
      return;
    }

    final candidates = ['.env.$envName', '.env.development', '.env'];

    for (final file in candidates) {
      try {
        await dotenv.load(fileName: file, isOptional: true);
        if (dotenv.env.isNotEmpty) return;
      } catch (_) {
        continue;
      }
    }

    dotenv.testLoad(mergeWith: _compileTimeDefaults);
  }

  static Map<String, String> get _compileTimeDefaults => {
        'API_BASE_URL': const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://localhost:3000/api/v1',
        ),
        'APP_NAME': const String.fromEnvironment('APP_NAME', defaultValue: 'Dhrigro'),
        'RAZORPAY_KEY_ID': const String.fromEnvironment('RAZORPAY_KEY_ID'),
        'FIREBASE_API_KEY': const String.fromEnvironment('FIREBASE_API_KEY'),
        'FIREBASE_APP_ID': const String.fromEnvironment('FIREBASE_APP_ID'),
        'FIREBASE_PROJECT_ID': const String.fromEnvironment('FIREBASE_PROJECT_ID'),
        'FIREBASE_MESSAGING_SENDER_ID':
            const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
        'ENABLE_API_LOGGING': kReleaseMode ? 'false' : 'true',
      };

  static void validate() {
    if (apiBaseUrl.isEmpty) {
      throw StateError('API_BASE_URL is required');
    }
    if (isProduction &&
        (apiBaseUrl.contains('localhost') || apiBaseUrl.contains('127.0.0.1'))) {
      throw StateError(
        'API_BASE_URL must be a production URL when ENV=production',
      );
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

  static String get appName =>
      dotenv.env['APP_NAME'] ??
      const String.fromEnvironment('APP_NAME', defaultValue: 'Dhrigro');

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
