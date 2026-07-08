import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/admin/admin_live_ops.dart';
import '../../../core/admin/admin_theme.dart';
import '../../../core/constants/app_colors.dart';

/// Connection health badge for admin top bar.
class AdminConnectionIndicator extends ConsumerWidget {
  const AdminConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(adminConnectionProvider);

    final (color, label, icon) = switch (conn.status) {
      AdminConnectionStatus.connected => (
          AppColors.primaryGreen,
          conn.latencyMs != null ? '${conn.latencyMs}ms' : 'Connected',
          Icons.cloud_done_outlined,
        ),
      AdminConnectionStatus.degraded => (
          AdminSemanticColors.warning,
          'Degraded',
          Icons.cloud_queue_outlined,
        ),
      AdminConnectionStatus.disconnected => (
          AppColors.errorRed,
          'Offline',
          Icons.cloud_off_outlined,
        ),
    };

    return Tooltip(
      message: conn.message ?? 'Backend health',
      child: InkWell(
        onTap: conn.status == AdminConnectionStatus.disconnected
            ? () => ref.read(adminConnectionProvider.notifier).checkHealth()
            : null,
        borderRadius: BorderRadius.circular(AdminRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
              ),
              if (conn.status == AdminConnectionStatus.disconnected) ...[
                const SizedBox(width: 4),
                Text(
                  'Retry',
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
