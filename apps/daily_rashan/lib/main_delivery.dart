import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'features/delivery/presentation/screens/delivery_auth_gate.dart';

/// Delivery partner app entry point
/// Run: flutter run -t lib/main_delivery.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();
  EnvConfig.validate();
  runApp(const ProviderScope(child: DeliveryApp()));
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dhrigro Delivery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const DeliveryAuthGate(),
    );
  }
}
