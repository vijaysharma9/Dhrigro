import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/admin/admin_live_ops.dart';
import '../../../../core/admin/admin_theme.dart';
import '../../../../core/constants/app_colors.dart';

/// Animated live ops timeline for dashboard and ops panels.
class LiveOpsTimeline extends StatelessWidget {
  const LiveOpsTimeline({
    super.key,
    required this.events,
    this.maxHeight = 280,
    this.compact = false,
  });

  final List<LiveOpsEvent> events;
  final double maxHeight;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AdminSpacing.lg),
        child: Center(
          child: Text(
            'No live activity yet',
            style: TextStyle(color: AdminSemanticColors.textMuted, fontSize: 12),
          ),
        ),
      );
    }

    final fmt = DateFormat('HH:mm:ss');

    return SizedBox(
      height: maxHeight,
      child: ListView.builder(
        itemCount: events.length,
        itemBuilder: (_, i) {
          final e = events[i];
          return TweenAnimationBuilder<double>(
            key: ValueKey(e.id),
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 300 + (i * 40).clamp(0, 200)),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => Opacity(
              opacity: t,
              child: Transform.translate(offset: Offset(0, (1 - t) * 8), child: child),
            ),
            child: _LiveOpsRow(event: e, timeFmt: fmt, compact: compact),
          );
        },
      ),
    );
  }
}

class _LiveOpsRow extends StatelessWidget {
  const _LiveOpsRow({
    required this.event,
    required this.timeFmt,
    required this.compact,
  });

  final LiveOpsEvent event;
  final DateFormat timeFmt;
  final bool compact;

  Color get _color => switch (event.severity) {
        LiveOpsSeverity.critical => AppColors.errorRed,
        LiveOpsSeverity.warning => AdminSemanticColors.warning,
        LiveOpsSeverity.success => AppColors.primaryGreen,
        LiveOpsSeverity.live => AppColors.navyBlue,
        LiveOpsSeverity.info => AdminSemanticColors.info,
      };

  IconData get _icon => switch (event.type) {
        LiveOpsEventType.orderCreated => Icons.shopping_bag_outlined,
        LiveOpsEventType.orderAssigned => Icons.local_shipping_outlined,
        LiveOpsEventType.orderDelayed => Icons.schedule,
        LiveOpsEventType.paymentFailed => Icons.payment_outlined,
        LiveOpsEventType.inventoryLow => Icons.warning_amber_rounded,
        LiveOpsEventType.userSignup => Icons.person_add_outlined,
        LiveOpsEventType.partnerOffline => Icons.two_wheeler,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 4 : 6),
      padding: EdgeInsets.symmetric(
        horizontal: AdminSpacing.md,
        vertical: compact ? 6 : AdminSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: _color, width: 3),
        ),
        color: _color.withValues(alpha: 0.04),
      ),
      child: Row(
        children: [
          Icon(_icon, size: compact ? 14 : 16, color: _color),
          SizedBox(width: compact ? AdminSpacing.sm : AdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: compact ? 11 : 12,
                  ),
                ),
                Text(
                  event.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AdminSemanticColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeFmt.format(event.timestamp),
            style: const TextStyle(fontSize: 9, color: AdminSemanticColors.textMuted),
          ),
        ],
      ),
    );
  }
}
