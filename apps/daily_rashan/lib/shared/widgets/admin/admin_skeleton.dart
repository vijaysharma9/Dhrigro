import 'package:flutter/material.dart';
import '../../../core/admin/admin_theme.dart';
import '../shimmer_box.dart';

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AdminSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ShimmerBox(width: 280, height: 28, borderRadius: 8),
          const SizedBox(height: AdminSpacing.sm),
          const ShimmerBox(width: 200, height: 14),
          const SizedBox(height: AdminSpacing.xxl),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 1200 ? 4 : (c.maxWidth > 700 ? 3 : 2);
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cols,
                crossAxisSpacing: AdminSpacing.md,
                mainAxisSpacing: AdminSpacing.md,
                childAspectRatio: 2.4,
                children: List.generate(
                  8,
                  (_) => const ShimmerBox(height: 72, borderRadius: 12),
                ),
              );
            },
          ),
          const SizedBox(height: AdminSpacing.section),
          const ShimmerBox(height: 120, borderRadius: 12),
          const SizedBox(height: AdminSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Expanded(flex: 2, child: ShimmerBox(height: 280, borderRadius: 12)),
              SizedBox(width: AdminSpacing.lg),
              Expanded(child: ShimmerBox(height: 280, borderRadius: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class AdminTableSkeleton extends StatelessWidget {
  const AdminTableSkeleton({super.key, this.rows = 6});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        rows,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AdminSpacing.sm),
          child: Row(
            children: const [
              ShimmerBox(width: 40, height: 40, borderRadius: 20),
              SizedBox(width: AdminSpacing.md),
              Expanded(child: ShimmerBox(height: 14)),
              SizedBox(width: AdminSpacing.lg),
              ShimmerBox(width: 80, height: 14),
            ],
          ),
        ),
      ),
    );
  }
}
