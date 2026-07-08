import 'package:flutter/material.dart';
import '../../../core/admin/admin_theme.dart';
import '../../../core/constants/app_colors.dart';

/// Sticky bulk-action bar for ops tables.
class AdminBulkToolbar extends StatelessWidget {
  const AdminBulkToolbar({
    super.key,
    required this.count,
    required this.onClear,
    required this.actions,
  });

  final int count;
  final VoidCallback onClear;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      color: AppColors.navyBlue,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AdminSpacing.lg,
            vertical: AdminSpacing.sm,
          ),
          child: Row(
            children: [
              Text(
                '$count selected',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: AdminSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: actions),
                ),
              ),
              TextButton(
                onPressed: onClear,
                child: const Text('Clear', style: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
