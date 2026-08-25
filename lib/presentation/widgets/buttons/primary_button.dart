import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

enum AppButtonSize { sm, md, lg }

/// Primary CTA. Solid fill, branded hue.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expanded = true,
    this.size = AppButtonSize.md,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final bool expanded;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !loading;
    final child = _ButtonContent(
      label: label,
      icon: icon,
      loading: loading,
      onColor: scheme.onPrimary,
      size: size,
    );
    final btn = FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        disabledBackgroundColor: scheme.primary.withValues(alpha: 0.4),
        disabledForegroundColor: scheme.onPrimary.withValues(alpha: 0.9),
        elevation: 0,
        padding: _padFor(size),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rMd),
        textStyle: _textFor(context, size),
        minimumSize: Size(0, _heightFor(size)),
      ),
      child: child,
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.size = AppButtonSize.md,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  final AppButtonSize size;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    final btn = OutlinedButton(
      onPressed: loading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: palette.borderStrong),
        backgroundColor: palette.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rMd),
        padding: _padFor(size),
        textStyle: _textFor(context, size),
        minimumSize: Size(0, _heightFor(size)),
      ),
      child: _ButtonContent(
        label: label,
        icon: icon,
        loading: loading,
        onColor: scheme.onSurface,
        size: size,
      ),
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = AppButtonSize.md,
    this.tone,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonSize size;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: tone ?? scheme.primary,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rSm),
        padding: _padFor(size),
        textStyle: _textFor(context, size),
        minimumSize: Size(0, _heightFor(size)),
      ),
      child: _ButtonContent(
        label: label,
        icon: icon,
        loading: false,
        onColor: tone ?? scheme.primary,
        size: size,
      ),
    );
  }
}

EdgeInsets _padFor(AppButtonSize size) => switch (size) {
      AppButtonSize.sm =>
        const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
      AppButtonSize.md =>
        const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 12),
      AppButtonSize.lg => const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
    };

TextStyle? _textFor(BuildContext context, AppButtonSize size) =>
    switch (size) {
      AppButtonSize.sm => Theme.of(context).textTheme.labelMedium,
      AppButtonSize.md => Theme.of(context).textTheme.labelLarge,
      AppButtonSize.lg => Theme.of(context).textTheme.titleMedium,
    };

double _heightFor(AppButtonSize size) => switch (size) {
      AppButtonSize.sm => 36,
      AppButtonSize.md => 46,
      AppButtonSize.lg => 54,
    };

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.loading,
    required this.onColor,
    required this.size,
  });

  final String label;
  final IconData? icon;
  final bool loading;
  final Color onColor;
  final AppButtonSize size;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return SizedBox(
        height: size == AppButtonSize.lg ? 22 : 18,
        width: size == AppButtonSize.lg ? 22 : 18,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation(onColor),
        ),
      );
    }
    final iconSize = size == AppButtonSize.lg ? 20.0 : 18.0;
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: iconSize),
        const SizedBox(width: AppSpacing.sm),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
