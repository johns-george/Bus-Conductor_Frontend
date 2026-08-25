import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatting.dart';

/// Horizontally scrollable "Today / Tomorrow / +2 / +3 / Pick date" chips.
class DateChipRow extends StatelessWidget {
  const DateChipRow({
    super.key,
    required this.selected,
    required this.onSelected,
    required this.onPickCustom,
  });

  final DateTime? selected;
  final ValueChanged<DateTime?> onSelected;
  final Future<void> Function() onPickCustom;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);

    final presets = <_ChipPreset>[
      const _ChipPreset(label: 'Flexible', value: null),
      _ChipPreset(label: 'Today', value: base),
      _ChipPreset(label: 'Tomorrow', value: base.add(const Duration(days: 1))),
      _ChipPreset(
        label: DateFormatting.travelDate(base.add(const Duration(days: 2))),
        value: base.add(const Duration(days: 2)),
      ),
      _ChipPreset(
        label: DateFormatting.travelDate(base.add(const Duration(days: 3))),
        value: base.add(const Duration(days: 3)),
      ),
    ];

    final customActive = selected != null &&
        !presets.any((p) => _sameDay(p.value, selected));

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: presets.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          if (i < presets.length) {
            final p = presets[i];
            final active = _sameDay(p.value, selected);
            return _Chip(
              label: p.label,
              active: active,
              onTap: () => onSelected(p.value),
            );
          }
          return _Chip(
            label: customActive
                ? DateFormatting.shortDate(selected!)
                : 'Pick date',
            active: customActive,
            icon: AppIcons.calendar,
            onTap: onPickCustom,
          );
        },
      ),
    );
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _ChipPreset {
  const _ChipPreset({required this.label, required this.value});
  final String label;
  final DateTime? value;
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final scheme = Theme.of(context).colorScheme;
    final bg = active ? scheme.primary : palette.surface;
    final fg = active ? scheme.onPrimary : palette.textPrimary;
    final border = active ? scheme.primary : palette.border;
    return Material(
      color: bg,
      borderRadius: AppRadii.rPill,
      child: InkWell(
        borderRadius: AppRadii.rPill,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadii.rPill,
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
