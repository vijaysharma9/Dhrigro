import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/admin/admin_theme.dart';
import '../../../core/constants/app_colors.dart';

/// Avatar with optional image and initial fallback.
class AdminAvatar extends StatelessWidget {
  const AdminAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 32,
    this.color,
  });

  final String? name;
  final String? imageUrl;
  final double size;
  final Color? color;

  String get _initial {
    final n = name?.trim();
    if (n == null || n.isEmpty) return '?';
    return n[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primaryGreen;
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    if (hasImage) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => _initials(accent),
            errorWidget: (_, __, ___) => _initials(accent),
          ),
        ),
      );
    }

    return _initials(accent);
  }

  Widget _initials(Color accent) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: accent.withValues(alpha: 0.12),
      child: Text(
        _initial,
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }
}

/// Compact metadata chip for tables.
class AdminMetaChip extends StatelessWidget {
  const AdminMetaChip({
    super.key,
    required this.label,
    this.color,
    this.icon,
    this.compact = true,
  });

  final String label;
  final Color? color;
  final IconData? icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AdminSemanticColors.textSecondary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AdminRadius.pill),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: c),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(fontSize: compact ? 10 : 11, fontWeight: FontWeight.w600, color: c),
          ),
        ],
      ),
    );
  }
}

enum CustomerTier { bronze, silver, gold, vip }

class CustomerTierBadge extends StatelessWidget {
  const CustomerTierBadge({super.key, required this.tier});

  final CustomerTier tier;

  static CustomerTier fromSpend(num spend, int orders) {
    if (spend >= 10000 || orders >= 20) return CustomerTier.vip;
    if (spend >= 5000 || orders >= 10) return CustomerTier.gold;
    if (spend >= 1500 || orders >= 4) return CustomerTier.silver;
    return CustomerTier.bronze;
  }

  (String, Color) get _props => switch (tier) {
        CustomerTier.bronze => ('Bronze', const Color(0xFF92400E)),
        CustomerTier.silver => ('Silver', const Color(0xFF64748B)),
        CustomerTier.gold => ('Gold', const Color(0xFFD97706)),
        CustomerTier.vip => ('VIP', AppColors.navyBlue),
      };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _props;
    return AdminMetaChip(label: label, color: color, icon: Icons.workspace_premium_outlined);
  }
}

enum CustomerHealth { active, loyal, atRisk, inactive }

class CustomerHealthBadge extends StatelessWidget {
  const CustomerHealthBadge({super.key, required this.health});

  final CustomerHealth health;

  static CustomerHealth compute({
    required bool isActive,
    required int orders,
    required num spend,
    DateTime? lastOrderAt,
  }) {
    if (!isActive) return CustomerHealth.inactive;
    final daysSince = lastOrderAt != null
        ? DateTime.now().difference(lastOrderAt).inDays
        : 999;
    if (orders >= 5 && spend >= 2000) return CustomerHealth.loyal;
    if (daysSince > 30) return CustomerHealth.atRisk;
    if (daysSince <= 14) return CustomerHealth.active;
    return CustomerHealth.atRisk;
  }

  (String, Color) get _props => switch (health) {
        CustomerHealth.active => ('Active', AppColors.primaryGreen),
        CustomerHealth.loyal => ('Loyal', AppColors.navyBlue),
        CustomerHealth.atRisk => ('At risk', AdminSemanticColors.warning),
        CustomerHealth.inactive => ('Inactive', AppColors.errorRed),
      };

  @override
  Widget build(BuildContext context) {
    final (label, color) = _props;
    return AdminMetaChip(label: label, color: color);
  }
}

class AdminIconActionBtn extends StatelessWidget {
  const AdminIconActionBtn({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AdminRadius.sm),
          hoverColor: AppColors.primaryGreen.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 16, color: AdminSemanticColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class AdminSectionCard extends StatelessWidget {
  const AdminSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AdminSpacing.md),
      padding: const EdgeInsets.all(AdminSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AdminSemanticColors.border),
        borderRadius: BorderRadius.circular(AdminRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: AdminTypography.sectionTitle(context)),
              if (trailing != null) ...[const Spacer(), trailing!],
            ],
          ),
          const SizedBox(height: AdminSpacing.sm),
          child,
        ],
      ),
    );
  }
}
