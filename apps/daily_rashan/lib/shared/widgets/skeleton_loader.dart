import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SkeletonBox(height: 48, borderRadius: 12),
        SizedBox(height: 16),
        SkeletonBox(height: 160, borderRadius: 16),
        SizedBox(height: 24),
        SkeletonBox(height: 24, width: 120),
        SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: Row(
            children: [
              Expanded(child: SkeletonBox(height: 100, borderRadius: 12)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 100, borderRadius: 12)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 100, borderRadius: 12)),
            ],
          ),
        ),
      ],
    );
  }
}
