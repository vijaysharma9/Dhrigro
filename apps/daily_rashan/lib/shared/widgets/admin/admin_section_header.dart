import 'package:flutter/material.dart';
import '../../../core/admin/admin_theme.dart';

class AdminSectionHeader extends StatelessWidget {
  const AdminSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(AdminSpacing.sm),
            decoration: BoxDecoration(
              color: AdminSemanticColors.borderSubtle,
              borderRadius: BorderRadius.circular(AdminRadius.sm),
            ),
            child: Icon(icon, size: 18, color: AdminSemanticColors.textSecondary),
          ),
          const SizedBox(width: AdminSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AdminTypography.sectionTitle(context)),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AdminSemanticColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class AdminPanelCard extends StatelessWidget {
  const AdminPanelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AdminSpacing.lg),
    this.header,
  });

  final Widget child;
  final EdgeInsets padding;
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminSemanticColors.surfaceCard,
        borderRadius: BorderRadius.circular(AdminRadius.lg),
        border: Border.all(color: AdminSemanticColors.border),
        boxShadow: AdminShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Container(
              padding: const EdgeInsets.fromLTRB(
                AdminSpacing.lg,
                AdminSpacing.lg,
                AdminSpacing.lg,
                AdminSpacing.sm,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AdminSemanticColors.borderSubtle),
                ),
              ),
              child: header,
            ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}
