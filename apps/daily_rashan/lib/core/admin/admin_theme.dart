import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Admin design tokens — dark-mode ready via [AdminThemeExtension].
class AdminSpacing {
  AdminSpacing._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double section = 32;
}

class AdminRadius {
  AdminRadius._();
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

class AdminShadows {
  AdminShadows._();
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

/// Semantic admin colors for alerts / ops states.
class AdminSemanticColors {
  AdminSemanticColors._();
  static const Color critical = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF0EA5E9);
  static const Color success = AppColors.primaryGreen;
  static const Color surface = Color(0xFFF5F7FA);
  static const Color surfaceCard = Colors.white;
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderSubtle = Color(0xFFF3F4F6);
}

/// Theme extension for future dark mode — swap values in [AdminTheme.dark].
@immutable
class AdminThemeExtension extends ThemeExtension<AdminThemeExtension> {
  const AdminThemeExtension({
    required this.surface,
    required this.surfaceCard,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.sidebarBg,
  });

  final Color surface;
  final Color surfaceCard;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color sidebarBg;

  static const light = AdminThemeExtension(
    surface: AdminSemanticColors.surface,
    surfaceCard: AdminSemanticColors.surfaceCard,
    textPrimary: AdminSemanticColors.textPrimary,
    textSecondary: AdminSemanticColors.textSecondary,
    border: AdminSemanticColors.border,
    sidebarBg: AppColors.navyBlue,
  );

  static const dark = AdminThemeExtension(
    surface: Color(0xFF0F172A),
    surfaceCard: Color(0xFF1E293B),
    textPrimary: Color(0xFFF8FAFC),
    textSecondary: Color(0xFF94A3B8),
    border: Color(0xFF334155),
    sidebarBg: Color(0xFF0B1220),
  );

  @override
  AdminThemeExtension copyWith({
    Color? surface,
    Color? surfaceCard,
    Color? textPrimary,
    Color? textSecondary,
    Color? border,
    Color? sidebarBg,
  }) {
    return AdminThemeExtension(
      surface: surface ?? this.surface,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      border: border ?? this.border,
      sidebarBg: sidebarBg ?? this.sidebarBg,
    );
  }

  @override
  AdminThemeExtension lerp(ThemeExtension<AdminThemeExtension>? other, double t) {
    if (other is! AdminThemeExtension) return this;
    return AdminThemeExtension(
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceCard: Color.lerp(surfaceCard, other.surfaceCard, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      border: Color.lerp(border, other.border, t)!,
      sidebarBg: Color.lerp(sidebarBg, other.sidebarBg, t)!,
    );
  }
}

extension AdminThemeContext on BuildContext {
  AdminThemeExtension get adminTheme =>
      Theme.of(this).extension<AdminThemeExtension>() ?? AdminThemeExtension.light;
}

class AdminTypography {
  AdminTypography._();

  static TextStyle pageTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.w700,
            color: AdminSemanticColors.textPrimary,
            letterSpacing: -0.3,
          );

  static TextStyle sectionTitle(BuildContext context) =>
      Theme.of(context).textTheme.titleMedium!.copyWith(
            fontWeight: FontWeight.w600,
            color: AdminSemanticColors.textPrimary,
          );

  static const TextStyle kpiValue = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AdminSemanticColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.1,
  );

  static const TextStyle kpiLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AdminSemanticColors.textSecondary,
  );

  static const TextStyle tableHeader = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AdminSemanticColors.textSecondary,
    letterSpacing: 0.3,
  );
}
