import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/admin/admin_live_ops.dart';
import '../../../core/admin/admin_realtime.dart';
import '../../../core/admin/admin_theme.dart';
import '../../../core/constants/app_colors.dart';

/// Offline / degraded connectivity banner for admin shell.
class AdminOfflineBanner extends ConsumerWidget {
  const AdminOfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(adminConnectionProvider);
    final realtime = ref.watch(adminRealtimeProvider);

    final offline = conn.status == AdminConnectionStatus.disconnected;
    final degraded = conn.status == AdminConnectionStatus.degraded;
    final pollingOnly = realtime.usePollingFallback &&
        realtime.connection == RealtimeConnectionState.disconnected;

    if (!offline && !degraded && !pollingOnly) return const SizedBox.shrink();

    final (color, message, icon) = offline
        ? (AppColors.errorRed, 'Backend unreachable — showing cached data', Icons.cloud_off)
        : degraded
            ? (AdminSemanticColors.warning, 'High latency detected (${conn.latencyMs}ms)', Icons.speed)
            : (AdminSemanticColors.info, 'Live stream offline — using polling refresh', Icons.sync);

    return Material(
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AdminSpacing.lg, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
              ),
            ),
            if (offline)
              TextButton(
                onPressed: () => ref.read(adminConnectionProvider.notifier).checkHealth(),
                child: Text('Retry', style: TextStyle(fontSize: 11, color: color)),
              ),
            if (pollingOnly && !offline)
              TextButton(
                onPressed: () => ref.read(adminRealtimeProvider.notifier).reconnect(),
                child: Text('Reconnect', style: TextStyle(fontSize: 11, color: color)),
              ),
          ],
        ),
      ),
    );
  }
}
