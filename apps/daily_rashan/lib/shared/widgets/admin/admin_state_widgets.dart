import 'package:flutter/material.dart';
import '../../../core/admin/admin_api_utils.dart';
import '../../../core/admin/admin_theme.dart';
import '../../../core/constants/app_colors.dart';

/// Consistent loading state for admin modules.
class AdminLoadingState extends StatelessWidget {
  const AdminLoadingState({
    super.key,
    this.message = 'Loading…',
    this.compact = false,
  });

  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AdminSpacing.xxl),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primaryGreen.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AdminSpacing.lg),
          Text(
            message,
            style: const TextStyle(
              color: AdminSemanticColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Graceful error state with retry — never shows raw stack traces.
class AdminErrorState extends StatelessWidget {
  const AdminErrorState({
    super.key,
    required this.error,
    this.onRetry,
    this.title = 'Something went wrong',
    this.compact = false,
  });

  final Object error;
  final VoidCallback? onRetry;
  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final message = AdminApiUtils.dioMessage(error);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? AdminSpacing.lg : AdminSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AdminSpacing.lg),
                decoration: BoxDecoration(
                  color: AdminSemanticColors.critical.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_off_outlined,
                  size: compact ? 32 : 40,
                  color: AdminSemanticColors.critical,
                ),
              ),
              SizedBox(height: compact ? AdminSpacing.md : AdminSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AdminTypography.sectionTitle(context),
              ),
              const SizedBox(height: AdminSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AdminSemanticColors.textSecondary,
                  height: 1.4,
                ),
              ),
              if (onRetry != null) ...[
                SizedBox(height: compact ? AdminSpacing.lg : AdminSpacing.xxl),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Try again'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Friendly empty state with optional CTA.
class AdminEmptyState extends StatelessWidget {
  const AdminEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.xxl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AdminSpacing.xl),
                decoration: BoxDecoration(
                  border: Border.all(color: AdminSemanticColors.border),
                  borderRadius: BorderRadius.circular(AdminRadius.lg),
                ),
                child: Icon(icon, size: 40, color: AdminSemanticColors.textMuted),
              ),
              const SizedBox(height: AdminSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AdminTypography.sectionTitle(context),
              ),
              if (message != null) ...[
                const SizedBox(height: AdminSpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AdminSemanticColors.textSecondary,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AdminSpacing.lg),
                OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
