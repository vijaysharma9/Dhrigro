import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../../core/admin/admin_theme.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../shared/widgets/admin/admin_section_header.dart';

class DashboardChartContainer extends StatelessWidget {
  const DashboardChartContainer({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.height = 200,
    this.legend,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final double height;
  final List<Widget>? legend;

  @override
  Widget build(BuildContext context) {
    return AdminPanelCard(
      padding: const EdgeInsets.fromLTRB(
        AdminSpacing.lg,
        AdminSpacing.sm,
        AdminSpacing.lg,
        AdminSpacing.lg,
      ),
      header: AdminSectionHeader(
        title: title,
        subtitle: subtitle,
        trailing: legend != null
            ? Row(mainAxisSize: MainAxisSize.min, children: legend!)
            : null,
      ),
      child: SizedBox(height: height, child: child),
    );
  }
}

class RevenueBarChart extends StatelessWidget {
  const RevenueBarChart({super.key, required this.data});

  final List<dynamic> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const _ChartEmpty(message: 'No revenue data for this period');
    }

    final groups = <BarChartGroupData>[];
    double maxY = 1;

    for (var i = 0; i < data.length; i++) {
      final d = data[i] as Map<String, dynamic>;
      final revenue = (d['revenue'] as num?)?.toDouble() ?? 0;
      if (revenue > maxY) maxY = revenue;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: revenue,
              width: 14,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  AppColors.primaryGreen.withValues(alpha: 0.7),
                  AppColors.primaryGreen,
                ],
              ),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: maxY * 1.15,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AdminSemanticColors.borderSubtle,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v >= 1000 ? '${(v / 1000).toStringAsFixed(0)}k' : v.toInt().toString(),
                style: const TextStyle(fontSize: 10, color: AdminSemanticColors.textMuted),
              ),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                final date = (data[i] as Map)['date'] as String? ?? '';
                final label = date.length >= 5 ? date.substring(5) : date;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 10, color: AdminSemanticColors.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: groups,
      ),
      duration: const Duration(milliseconds: 600),
    );
  }
}

class OrdersLineChart extends StatelessWidget {
  const OrdersLineChart({super.key, required this.data});

  final List<dynamic> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const _ChartEmpty(message: 'No order trend data');
    }

    final spots = <FlSpot>[];
    double maxY = 1;

    for (var i = 0; i < data.length; i++) {
      final d = data[i] as Map<String, dynamic>;
      final orders = (d['orders'] as num?)?.toDouble() ?? 0;
      if (orders > maxY) maxY = orders;
      spots.add(FlSpot(i.toDouble(), orders));
    }

    return LineChart(
      LineChartData(
        maxY: maxY * 1.2,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AdminSemanticColors.borderSubtle,
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.orangeAccent,
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.orangeAccent,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.orangeAccent.withValues(alpha: 0.2),
                  AppColors.orangeAccent.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 600),
    );
  }
}

class RevenueTrendChart extends StatelessWidget {
  const RevenueTrendChart({super.key, required this.data});

  final List<dynamic> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const _ChartEmpty(message: 'No 30-day revenue data');
    }

    final spots = <FlSpot>[];
    double maxY = 1;

    for (var i = 0; i < data.length; i++) {
      final d = data[i] as Map<String, dynamic>;
      final revenue = (d['revenue'] as num?)?.toDouble() ?? 0;
      if (revenue > maxY) maxY = revenue;
      spots.add(FlSpot(i.toDouble(), revenue));
    }

    return LineChart(
      LineChartData(
        maxY: maxY * 1.15,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 3,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AdminSemanticColors.borderSubtle,
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.navyBlue,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.navyBlue.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 600),
    );
  }
}

class ChartLegendDot extends StatelessWidget {
  const ChartLegendDot({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AdminSemanticColors.textSecondary)),
      ],
    );
  }
}

class _ChartEmpty extends StatelessWidget {
  const _ChartEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 32, color: AdminSemanticColors.textMuted),
          const SizedBox(height: AdminSpacing.sm),
          Text(message, style: const TextStyle(color: AdminSemanticColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

class DeliveryPerformancePlaceholder extends StatelessWidget {
  const DeliveryPerformancePlaceholder({super.key, required this.deliveryOps});

  final Map<String, dynamic> deliveryOps;

  @override
  Widget build(BuildContext context) {
    final delivered = deliveryOps['deliveriesToday'] as int? ?? 0;
    final active = deliveryOps['activeDeliveries'] as int? ?? 0;
    final avgMins = deliveryOps['avgDeliveryMinutes'] as int? ?? 28;

    return SizedBox(
      height: 100,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.navyBlue.withValues(alpha: 0.08),
                    AppColors.primaryGreen.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(AdminRadius.sm),
                border: Border.all(color: AdminSemanticColors.borderSubtle),
              ),
              child: Stack(
                children: [
                  ...List.generate(6, (i) {
                    final left = 20.0 + (i * 28) % 120;
                    final top = 15.0 + (i * 17) % 60;
                    return Positioned(
                      left: left,
                      top: top,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primaryGreen.withValues(alpha: 0.5 + (i % 3) * 0.15),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_outlined, size: 22, color: AdminSemanticColors.textMuted),
                        const SizedBox(height: 4),
                        const Text(
                          'Heatmap · coming soon',
                          style: TextStyle(fontSize: 10, color: AdminSemanticColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AdminSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniStat(label: 'Delivered today', value: '$delivered'),
                const SizedBox(height: 6),
                _MiniStat(label: 'In progress', value: '$active', accent: AppColors.orangeAccent),
                const SizedBox(height: 6),
                _MiniStat(label: 'Avg time', value: '${avgMins}m', accent: AppColors.navyBlue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AdminSemanticColors.borderSubtle,
        borderRadius: BorderRadius.circular(AdminRadius.sm),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AdminSemanticColors.textMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent ?? AdminSemanticColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
