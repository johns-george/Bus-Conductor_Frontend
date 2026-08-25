import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surfaces = isDark ? AppSurfaces.dark : AppSurfaces.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppColors.teal : AppColors.tealStrong,
      onPrimary: isDark ? AppColors.midnightDeep : Colors.white,
      primaryContainer: AppColors.tealSoft,
      onPrimaryContainer: AppColors.midnightDeep,
      secondary: isDark ? AppColors.amber : AppColors.amberStrong,
      onSecondary: AppColors.midnightDeep,
      secondaryContainer: AppColors.amberSoft,
      onSecondaryContainer: AppColors.midnightDeep,
      tertiary: AppColors.coral,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      errorContainer: AppColors.errorSoft,
      onErrorContainer: AppColors.error,
      surface: surfaces.surface,
      onSurface: surfaces.textPrimary,
      surfaceContainerHighest: surfaces.surfaceMuted,
      onSurfaceVariant: surfaces.textSecondary,
      outline: surfaces.border,
      outlineVariant: surfaces.borderStrong,
      shadow: Colors.black,
      scrim: Colors.black54,
      inverseSurface: surfaces.inverse,
      onInverseSurface: isDark ? AppColors.midnightDeep : AppColors.n0,
      inversePrimary: AppColors.teal,
      surfaceTint: Colors.transparent,
    );

    final textTheme =
        AppTypography.textTheme(surfaces.textPrimary, surfaces.textMuted);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: surfaces.background,
      canvasColor: surfaces.surface,
      dividerColor: surfaces.border,
      splashFactory: InkSparkle.splashFactory,
      textTheme: textTheme,
      extensions: [AppPalette(surfaces: surfaces)],
      appBarTheme: AppBarTheme(
        backgroundColor: surfaces.background,
        foregroundColor: surfaces.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: surfaces.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: surfaces.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.rLg,
          side: BorderSide(color: surfaces.border),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: surfaces.border,
        space: 1,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaces.surfaceMuted,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: surfaces.textMuted),
        prefixIconColor: surfaces.textSecondary,
        suffixIconColor: surfaces.textSecondary,
        border: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(color: surfaces.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(color: surfaces.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: const OutlineInputBorder(
          borderRadius: AppRadii.rMd,
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaces.surfaceMuted,
        selectedColor: colorScheme.primary,
        labelStyle: textTheme.labelMedium!.copyWith(color: surfaces.textPrimary),
        secondaryLabelStyle:
            textTheme.labelMedium!.copyWith(color: colorScheme.onPrimary),
        side: BorderSide(color: surfaces.border),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rPill),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaces.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surfaces.surface,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: surfaces.borderStrong,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaces.inverse,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: isDark ? AppColors.n900 : AppColors.n0),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.rMd),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: colorScheme.primary,
        unselectedLabelColor: surfaces.textSecondary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: textTheme.titleSmall,
        unselectedLabelStyle: textTheme.titleSmall,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: surfaces.surfaceMuted,
      ),
      iconTheme: IconThemeData(color: surfaces.textPrimary, size: 22),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaces.surface,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.14),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: surfaces.textSecondary)),
        height: 68,
      ),
    );
  }
}
