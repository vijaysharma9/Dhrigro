import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/storage_provider.dart';

const _kAdminThemeMode = 'admin_theme_mode';

final adminThemeModeProvider =
    AsyncNotifierProvider<AdminThemeModeNotifier, ThemeMode>(
  AdminThemeModeNotifier.new,
);

class AdminThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final prefs = await ref.watch(sharedPrefsProvider.future);
    final stored = prefs.getString(_kAdminThemeMode);
    return stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final next = state.valueOrNull == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = AsyncData(next);
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.setString(_kAdminThemeMode, next == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> set(ThemeMode mode) async {
    state = AsyncData(mode);
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.setString(_kAdminThemeMode, mode == ThemeMode.dark ? 'dark' : 'light');
  }
}

extension AdminThemeContext on BuildContext {
  bool get isAdminDark =>
      Theme.of(this).brightness == Brightness.dark;
}
