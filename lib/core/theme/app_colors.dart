import 'package:flutter/material.dart';

/// Original, transport-grade palette.
///
/// The brand is built around a deep midnight navy base, an electric teal
/// accent for interactive elements, and a warm amber for high-energy CTAs and
/// highlights. Neutrals carry a soft blue undertone to keep the product
/// feeling urban and premium rather than generic.
class AppColors {
  const AppColors._();

  // Brand
  static const Color midnight = Color(0xFF0B1530);
  static const Color midnightSoft = Color(0xFF121C3A);
  static const Color midnightDeep = Color(0xFF070D22);

  static const Color teal = Color(0xFF14D5C6);
  static const Color tealStrong = Color(0xFF0FBEB0);
  static const Color tealSoft = Color(0xFFDFFBF7);

  static const Color amber = Color(0xFFFFB648);
  static const Color amberStrong = Color(0xFFF59A3C);
  static const Color amberSoft = Color(0xFFFFF2D9);

  static const Color coral = Color(0xFFFF6B6B);

  // Neutrals (cool)
  static const Color n0 = Color(0xFFFFFFFF);
  static const Color n50 = Color(0xFFF5F7FC);
  static const Color n100 = Color(0xFFEAEEF5);
  static const Color n200 = Color(0xFFD6DDEB);
  static const Color n300 = Color(0xFFCBD2E0);
  static const Color n400 = Color(0xFF8892A6);
  static const Color n500 = Color(0xFF6A7489);
  static const Color n600 = Color(0xFF4A5670);
  static const Color n700 = Color(0xFF2F3A55);
  static const Color n800 = Color(0xFF1A2440);
  static const Color n900 = Color(0xFF0B1530);

  // Semantics
  static const Color success = Color(0xFF2FC48B);
  static const Color successSoft = Color(0xFFE1F7EC);
  static const Color warning = Color(0xFFFFB648);
  static const Color warningSoft = Color(0xFFFFF2D9);
  static const Color error = Color(0xFFEF4B5E);
  static const Color errorSoft = Color(0xFFFCE3E7);
  static const Color info = Color(0xFF3DA5F5);
  static const Color infoSoft = Color(0xFFE1F0FD);
}

/// Surface tokens resolved per brightness. Centralising these keeps widgets
/// free of `Theme.of(context).brightness` checks.
class AppSurfaces {
  const AppSurfaces({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceMuted,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.inverse,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceMuted;
  final Color border;
  final Color borderStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color inverse;

  static const AppSurfaces light = AppSurfaces(
    background: AppColors.n50,
    surface: AppColors.n0,
    surfaceElevated: AppColors.n0,
    surfaceMuted: AppColors.n100,
    border: AppColors.n100,
    borderStrong: AppColors.n200,
    textPrimary: AppColors.n900,
    textSecondary: AppColors.n600,
    textMuted: AppColors.n400,
    inverse: AppColors.n0,
  );

  static const AppSurfaces dark = AppSurfaces(
    background: AppColors.midnightDeep,
    surface: AppColors.midnight,
    surfaceElevated: AppColors.midnightSoft,
    surfaceMuted: Color(0xFF18234A),
    border: Color(0xFF1F2A4C),
    borderStrong: Color(0xFF2B3766),
    textPrimary: AppColors.n0,
    textSecondary: AppColors.n200,
    textMuted: AppColors.n400,
    inverse: AppColors.n900,
  );
}

/// Theme extension so widgets can read `Theme.of(context).extension<AppPalette>()`.
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({required this.surfaces});

  final AppSurfaces surfaces;

  @override
  AppPalette copyWith({AppSurfaces? surfaces}) =>
      AppPalette(surfaces: surfaces ?? this.surfaces);

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return t < 0.5 ? this : other;
  }
}
