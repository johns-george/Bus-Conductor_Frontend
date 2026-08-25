import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/stop.dart';

/// Tappable pseudo-field used on the search page. Tapping opens a stop
/// picker bottom sheet instead of focusing a keyboard — keeps the home
/// experience visual and fast, matches the RedBus-style interaction.
class StopPickerField extends StatelessWidget {
  const StopPickerField({
    super.key,
    required this.kind,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final StopFieldKind kind;
  final Stop? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final scheme = Theme.of(context).colorScheme;

    final label = switch (kind) {
      StopFieldKind.from => 'From',
      StopFieldKind.to => 'To',
    };
    final icon = switch (kind) {
      StopFieldKind.from => AppIcons.pinSource,
      StopFieldKind.to => AppIcons.pinDestination,
    };
    final iconColor = switch (kind) {
      StopFieldKind.from => scheme.primary,
      StopFieldKind.to => scheme.tertiary,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.rMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: palette.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value?.name ?? 'Select a stop',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: value == null
                              ? palette.textMuted
                              : palette.textPrimary,
                        ),
                  ),
                  if (value != null)
                    Text(
                      value!.city,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: palette.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (value != null && onClear != null)
              IconButton(
                onPressed: onClear,
                icon: const Icon(AppIcons.close, size: 18),
                color: palette.textMuted,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              )
            else
              Icon(AppIcons.chevronRight, size: 18, color: palette.textMuted),
          ],
        ),
      ),
    );
  }
}

enum StopFieldKind { from, to }
