import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class LoadingShimmer extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;
  final int count;

  const LoadingShimmer({
    super.key,
    this.height = 80,
    this.width,
    this.borderRadius = 12,
    this.count = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: GarudaColors.surfaceLight,
      highlightColor: GarudaColors.surface.withValues(alpha: 0.8),
      child: Column(
        children: List.generate(count, (i) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Container(
            height: height,
            width: width ?? double.infinity,
            decoration: BoxDecoration(
              color: GarudaColors.surfaceLight,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
        )),
      ),
    );
  }
}

class ShimmerLine extends StatelessWidget {
  final double width;
  final double height;

  const ShimmerLine({super.key, this.width = 120, this.height = 14});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: GarudaColors.surfaceLight,
      highlightColor: GarudaColors.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: GarudaColors.surfaceLight,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
