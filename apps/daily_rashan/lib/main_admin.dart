import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/admin/admin_theme_mode_provider.dart';
import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/presentation/screens/admin_auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (details) {
    return Material(
      color: const Color(0xFFF5F7FA),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            details.exceptionAsString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
          ),
        ),
      ),
    );
  };

  await EnvConfig.load();
  EnvConfig.validate();
  runApp(const ProviderScope(child: AdminApp()));
}

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(adminThemeModeProvider);

    return MaterialApp(
      title: 'Dhrigro Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.adminLightTheme,
      darkTheme: AppTheme.adminDarkTheme,
      themeMode: themeMode.valueOrNull ?? ThemeMode.light,
      home: const AdminAuthGate(),
    );
  }
}
