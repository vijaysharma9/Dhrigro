import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configure via `.env` or run `flutterfire configure` and replace this file.
class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    final apiKey = dotenv.env['FIREBASE_API_KEY'] ?? '';
    final appId = dotenv.env['FIREBASE_APP_ID'] ?? '';
    final messagingSenderId =
        dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';

    if (apiKey.isEmpty || appId.isEmpty || projectId.isEmpty) {
      return null;
    }

    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'],
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'],
        );
      case TargetPlatform.iOS:
        return FirebaseOptions(
          apiKey: apiKey,
          appId: appId,
          messagingSenderId: messagingSenderId,
          projectId: projectId,
          iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID'],
        );
      default:
        return null;
    }
  }
}
