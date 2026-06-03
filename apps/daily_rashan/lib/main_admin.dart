import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/presentation/screens/admin_auth_gate.dart';

/// Admin panel entry point (Flutter Web)
/// Run: flutter run -d chrome -t lib/main_admin.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();
  EnvConfig.validate();
  runApp(const ProviderScope(child: AdminApp()));
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Rashan Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AdminAuthGate(),
    );
  }
}
