import 'package:flutter/material.dart';
import '../../../core/admin/admin_api_utils.dart';
import '../../../core/admin/admin_theme.dart';
import '../../../core/constants/app_colors.dart';

enum AdminToastType { success, error, info }

/// Compact floating admin feedback toasts.
class AdminToast {
  AdminToast._();

  static void show(
    BuildContext context, {
    required String message,
    AdminToastType type = AdminToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final (color, icon) = switch (type) {
      AdminToastType.success => (AppColors.primaryGreen, Icons.check_circle_outline),
      AdminToastType.error => (AdminSemanticColors.critical, Icons.error_outline),
      AdminToastType.info => (AdminSemanticColors.info, Icons.info_outline),
    };

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: duration,
        content: Material(
          elevation: 4,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(AdminRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AdminSpacing.lg,
              vertical: AdminSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AdminSemanticColors.surfaceCard,
              borderRadius: BorderRadius.circular(AdminRadius.md),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: AdminSpacing.md),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: AdminSemanticColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: AdminToastType.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: AdminToastType.error);

  static void errorFrom(BuildContext context, Object err) =>
      AdminToast.error(context, AdminApiUtils.dioMessage(err));

  static void info(BuildContext context, String message) =>
      show(context, message: message, type: AdminToastType.info);
}
