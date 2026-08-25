import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';

/// Search-style input used inside the stop picker sheet.
class SearchTextField extends StatelessWidget {
  const SearchTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.autofocus = true,
    this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppPalette>()!.surfaces;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.titleMedium,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(AppIcons.search, color: palette.textMuted, size: 20),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (_, value, __) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Clear',
              onPressed: () {
                controller.clear();
                onChanged?.call('');
                onClear?.call();
              },
              icon: const Icon(AppIcons.close, size: 18),
              color: palette.textMuted,
            );
          },
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}
