import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../admin/admin_theme.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme =>
      _build(Brightness.light, AdminThemeExtension.light, adminSurface: false);

  /// Admin panel theme — includes [AdminThemeExtension] for future dark mode.
  static ThemeData get adminLightTheme =>
      _build(Brightness.light, AdminThemeExtension.light, adminSurface: true);

  static ThemeData get adminDarkTheme =>
      _build(Brightness.dark, AdminThemeExtension.dark, adminSurface: true);

  static ThemeData _build(
    Brightness brightness,
    AdminThemeExtension adminExt, {
    required bool adminSurface,
  }) {
    final isDark = brightness == Brightness.dark;
    final base = ThemeData(brightness: brightness).textTheme;
    final textTheme = kIsWeb
        ? base
        : GoogleFonts.interTextTheme(base);
    final onSurface = adminExt.textPrimary;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: adminSurface ? adminExt.surface : AppColors.backgroundWhite,
      primaryColor: AppColors.primaryGreen,
      extensions: [adminExt],
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: AppColors.primaryGreen,
              secondary: AppColors.orangeAccent,
              tertiary: AppColors.navyBlue,
              surface: adminExt.surfaceCard,
              error: AppColors.errorRed,
              onPrimary: Colors.white,
              onSurface: onSurface,
            )
          : const ColorScheme.light(
              primary: AppColors.primaryGreen,
              secondary: AppColors.orangeAccent,
              tertiary: AppColors.navyBlue,
              surface: AppColors.backgroundWhite,
              error: AppColors.errorRed,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
      textTheme: textTheme.apply(bodyColor: onSurface, displayColor: onSurface),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: adminExt.surfaceCard,
        foregroundColor: onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: adminExt.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: adminExt.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? adminExt.surface : const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: adminExt.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: adminExt.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerColor: adminExt.border,
      iconTheme: IconThemeData(color: adminExt.textSecondary),
      bottomNavigationBarTheme: adminSurface
          ? null
          : const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: AppColors.primaryGreen,
              unselectedItemColor: AppColors.textGrey,
              type: BottomNavigationBarType.fixed,
              elevation: 8,
            ),
    );
  }
}
