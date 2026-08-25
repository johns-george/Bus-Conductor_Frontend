import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Surface card with restrained elevation and a consistent bordered look.
/// Use this instead of [Card] for app-specific content surfaces.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = AppSpacing.cardPadding,
    this.tone = AppCardTone.surface,
    this.emphasized = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final AppCardTone tone;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final scheme = Theme.of(context).colorScheme;

    final bg = switch (tone) {
      AppCardTone.surface => palette.surface,
      AppCardTone.muted => palette.surfaceMuted,
      AppCardTone.brand => scheme.primary.withValues(alpha: 0.06),
    };

    final border = switch (tone) {
      AppCardTone.surface => palette.border,
      AppCardTone.muted => palette.border,
      AppCardTone.brand => scheme.primary.withValues(alpha: 0.22),
    };

    final content = Padding(padding: padding, child: child);

    return Material(
      color: bg,
      borderRadius: AppRadii.rLg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: AppRadii.rLg,
            border: Border.all(color: border),
            boxShadow: emphasized
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: content,
        ),
      ),
    );
  }
}

enum AppCardTone { surface, muted, brand }
