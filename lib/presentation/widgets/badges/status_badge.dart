import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

enum StatusTone { neutral, info, success, warning, error, brand }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.tone = StatusTone.neutral,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final StatusTone tone;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _colors(context, tone);
    final text = Theme.of(context)
        .textTheme
        .labelMedium
        ?.copyWith(color: fg, fontWeight: FontWeight.w600);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.rPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 12 : 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label, style: text),
        ],
      ),
    );
  }

  (Color, Color) _colors(BuildContext context, StatusTone tone) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return switch (tone) {
      StatusTone.neutral => (
          palette.surfaceMuted,
          palette.textSecondary,
        ),
      StatusTone.info => (
          isDark ? const Color(0x223DA5F5) : AppColors.infoSoft,
          AppColors.info,
        ),
      StatusTone.success => (
          isDark ? const Color(0x222FC48B) : AppColors.successSoft,
          isDark ? const Color(0xFF5EDDA9) : AppColors.success,
        ),
      StatusTone.warning => (
          isDark ? const Color(0x33FFB648) : AppColors.warningSoft,
          isDark ? AppColors.amber : AppColors.amberStrong,
        ),
      StatusTone.error => (
          isDark ? const Color(0x33EF4B5E) : AppColors.errorSoft,
          AppColors.error,
        ),
      StatusTone.brand => (
          isDark ? const Color(0x3314D5C6) : AppColors.tealSoft,
          isDark ? AppColors.teal : AppColors.tealStrong,
        ),
    };
  }
}
