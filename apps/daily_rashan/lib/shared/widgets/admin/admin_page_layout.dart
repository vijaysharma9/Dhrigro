import 'package:flutter/material.dart';
import '../../../core/admin/admin_theme.dart';

/// Consistent page wrapper for admin list/detail screens.
class AdminPageLayout extends StatelessWidget {
  const AdminPageLayout({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    required this.child,
    this.filters,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget child;
  final Widget? filters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AdminTypography.pageTitle(context)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AdminSemanticColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null)
                Flexible(
                  child: Wrap(
                    spacing: AdminSpacing.sm,
                    runSpacing: AdminSpacing.sm,
                    alignment: WrapAlignment.end,
                    children: actions!,
                  ),
                ),
            ],
          ),
          if (filters != null) ...[
            const SizedBox(height: AdminSpacing.lg),
            filters!,
          ],
          const SizedBox(height: AdminSpacing.lg),
          Expanded(child: child),
        ],
      ),
    );
  }
}
