import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../booking_controller.dart';

/// Two-dot progress indicator for booking flow: passenger →
/// payment. Stays compact so it's comfortable above an app bar.
class BookingStepper extends StatelessWidget {
  const BookingStepper({super.key, required this.current});
  final BookingStage current;

  static const _stages = [
    (BookingStage.passenger, 'Passenger'),
    (BookingStage.payment, 'Payment'),
  ];

  int get _currentIndex => switch (current) {
        BookingStage.passenger => 0,
        BookingStage.payment => 1,
        BookingStage.success => 2,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.extension<AppPalette>()!.surfaces;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          for (var i = 0; i < _stages.length; i++) ...[
            _Dot(
              index: i + 1,
              label: _stages[i].$2,
              active: i == _currentIndex,
              done: i < _currentIndex,
              theme: theme,
              palette: palette,
            ),
            if (i < _stages.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: i < _currentIndex
                        ? AppColors.teal
                        : palette.border,
                    borderRadius: AppRadii.rPill,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({
    required this.index,
    required this.label,
    required this.active,
    required this.done,
    required this.theme,
    required this.palette,
  });

  final int index;
  final String label;
  final bool active;
  final bool done;
  final ThemeData theme;
  final AppSurfaces palette;

  @override
  Widget build(BuildContext context) {
    final bg = done || active ? AppColors.teal : palette.surfaceMuted;
    final fg = done || active ? Colors.white : palette.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
            border: Border.all(
              color: done || active ? AppColors.tealStrong : palette.border,
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: done
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
              : Text(
                  '$index',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: active ? AppColors.tealStrong : palette.textMuted,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
