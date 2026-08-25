import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    this.height = 16,
    this.radius = AppRadii.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Wraps children in a shimmer effect using the current theme's muted colours.
class AppShimmer extends StatelessWidget {
  const AppShimmer({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    return Shimmer.fromColors(
      baseColor: palette.surfaceMuted,
      highlightColor: palette.border,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

class RouteCardSkeleton extends StatelessWidget {
  const RouteCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.rLg,
        border: Border.all(color: palette.border),
      ),
      child: const AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SkeletonBlock(width: 120, height: 14),
                Spacer(),
                SkeletonBlock(width: 60, height: 20, radius: AppRadii.pill),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            SkeletonBlock(width: double.infinity, height: 52),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                SkeletonBlock(width: 80, height: 14),
                Spacer(),
                SkeletonBlock(width: 90, height: 14),
                Spacer(),
                SkeletonBlock(width: 70, height: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
