import 'package:flutter/material.dart';
import '../../../core/admin/admin_theme.dart';
import '../../../core/constants/app_colors.dart';
import '../../../features/admin/presentation/widgets/admin_shell.dart';

typedef AdminQuickAction = void Function(AdminSection section);

class AdminQuickActionsFab extends StatefulWidget {
  const AdminQuickActionsFab({
    super.key,
    required this.onAction,
    required this.canAccess,
  });

  final AdminQuickAction onAction;
  final bool Function(AdminSection section) canAccess;

  @override
  State<AdminQuickActionsFab> createState() => _AdminQuickActionsFabState();
}

class _AdminQuickActionsFabState extends State<AdminQuickActionsFab> {
  bool _open = false;

  void _toggle() => setState(() => _open = !_open);

  void _pick(AdminSection section) {
    setState(() => _open = false);
    widget.onAction(section);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return const SizedBox.shrink();

    final actions = [
      if (widget.canAccess(AdminSection.products))
        _QuickItem(Icons.add_box_outlined, 'Add product', AdminSection.products),
      if (widget.canAccess(AdminSection.coupons))
        _QuickItem(Icons.local_offer_outlined, 'Create coupon', AdminSection.coupons),
      if (widget.canAccess(AdminSection.banners))
        _QuickItem(Icons.image_outlined, 'Create banner', AdminSection.banners),
      if (widget.canAccess(AdminSection.delivery))
        _QuickItem(Icons.local_shipping_outlined, 'Assign delivery', AdminSection.delivery),
      if (widget.canAccess(AdminSection.reports))
        _QuickItem(Icons.download_outlined, 'Export report', AdminSection.reports),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_open)
          Container(
            margin: const EdgeInsets.only(bottom: AdminSpacing.sm),
            padding: const EdgeInsets.symmetric(vertical: AdminSpacing.sm),
            decoration: BoxDecoration(
              color: AdminSemanticColors.surfaceCard,
              borderRadius: BorderRadius.circular(AdminRadius.md),
              border: Border.all(color: AdminSemanticColors.border),
              boxShadow: AdminShadows.elevated,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: actions
                  .map(
                    (a) => InkWell(
                      onTap: () => _pick(a.section),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AdminSpacing.lg,
                          vertical: AdminSpacing.sm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(a.icon, size: 16, color: AppColors.primaryGreen),
                            const SizedBox(width: AdminSpacing.sm),
                            Text(a.label, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        FloatingActionButton.small(
          heroTag: 'admin_quick_actions',
          backgroundColor: AppColors.navyBlue,
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _open ? 0.125 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(_open ? Icons.close : Icons.bolt, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }
}

class _QuickItem {
  const _QuickItem(this.icon, this.label, this.section);
  final IconData icon;
  final String label;
  final AdminSection section;
}
