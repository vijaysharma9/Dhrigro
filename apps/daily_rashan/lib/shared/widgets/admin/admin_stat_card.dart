import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/admin/admin_theme.dart';
import '../../../core/constants/app_colors.dart';

class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap,
    this.trendPercent,
    this.trendUp,
    this.sparkline,
    this.compact = true,
    this.live = false,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;
  final double? trendPercent;
  final bool? trendUp;
  final List<double>? sparkline;
  final bool compact;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primaryGreen;

    return Material(
      color: AdminSemanticColors.surfaceCard,
      elevation: 0,
      borderRadius: BorderRadius.circular(AdminRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AdminRadius.md),
        hoverColor: accent.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AdminRadius.md),
            border: Border.all(color: AdminSemanticColors.border),
            boxShadow: AdminShadows.card,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(AdminRadius.md),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(compact ? AdminSpacing.md : AdminSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            if (icon != null)
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(icon, color: accent, size: 16),
                              ),
                            if (live) ...[
                              const SizedBox(width: AdminSpacing.sm),
                              _LiveDot(color: accent),
                            ],
                            const Spacer(),
                            if (trendPercent != null) _TrendBadge(
                              percent: trendPercent!,
                              up: trendUp ?? true,
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? AdminSpacing.sm : AdminSpacing.md),
                        Text(title, style: AdminTypography.kpiLabel),
                        const SizedBox(height: 2),
                        _AnimatedKpiValue(value: value),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 11,
                              color: accent,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (sparkline != null && sparkline!.length > 1) ...[
                          const SizedBox(height: AdminSpacing.sm),
                          SizedBox(
                            height: 28,
                            child: _MiniSparkline(data: sparkline!, color: accent),
                          ),
                        ],
                      ],
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
}

class _AnimatedKpiValue extends StatelessWidget {
  const _AnimatedKpiValue({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(value),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: 0.4 + (0.6 * t),
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 4),
          child: child,
        ),
      ),
      child: Text(value, style: AdminTypography.kpiValue),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot({required this.color});
  final Color color;

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.4, end: 1.0).animate(_ctrl),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.percent, required this.up});

  final double percent;
  final bool up;

  @override
  Widget build(BuildContext context) {
    final color = up ? AppColors.primaryGreen : AppColors.errorRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AdminRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward : Icons.arrow_downward,
            size: 10,
            color: color,
          ),
          Text(
            '${percent.abs().toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

class _MiniSparkline extends StatelessWidget {
  const _MiniSparkline({required this.data, required this.color});

  final List<double> data;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final max = data.reduce((a, b) => a > b ? a : b);
    final min = data.reduce((a, b) => a < b ? a : b);
    final range = (max - min).clamp(1, double.infinity);

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: min - range * 0.1,
        maxY: max + range * 0.1,
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < data.length; i++)
                FlSpot(i.toDouble(), data[i]),
            ],
            isCurved: true,
            color: color,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 400),
    );
  }
}
