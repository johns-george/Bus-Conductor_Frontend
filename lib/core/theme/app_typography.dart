import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography ramp built on Plus Jakarta Sans — a modern humanist sans that
/// reads well at small sizes and has strong display personality at large ones.
class AppTypography {
  const AppTypography._();

  static TextTheme textTheme(Color onSurface, Color onSurfaceMuted) {
    final base = GoogleFonts.plusJakartaSansTextTheme();

    TextStyle s(double size, FontWeight weight,
            {double? height, double? letter, Color? color,}) =>
        GoogleFonts.plusJakartaSans(
          fontSize: size,
          fontWeight: weight,
          height: height,
          letterSpacing: letter,
          color: color ?? onSurface,
        );

    return base.copyWith(
      displayLarge: s(40, FontWeight.w700, height: 1.1, letter: -0.6),
      displayMedium: s(32, FontWeight.w700, height: 1.15, letter: -0.4),
      displaySmall: s(28, FontWeight.w700, height: 1.2, letter: -0.3),
      headlineLarge: s(24, FontWeight.w700, height: 1.25, letter: -0.2),
      headlineMedium: s(20, FontWeight.w700, height: 1.3),
      headlineSmall: s(18, FontWeight.w700, height: 1.3),
      titleLarge: s(17, FontWeight.w600, height: 1.35),
      titleMedium: s(15, FontWeight.w600, height: 1.4),
      titleSmall: s(13, FontWeight.w600, height: 1.4, letter: 0.1),
      bodyLarge: s(16, FontWeight.w500, height: 1.45),
      bodyMedium: s(14, FontWeight.w500, height: 1.5, color: onSurface),
      bodySmall: s(12.5, FontWeight.w500, height: 1.45, color: onSurfaceMuted),
      labelLarge: s(14, FontWeight.w600, height: 1.2, letter: 0.1),
      labelMedium: s(12, FontWeight.w600, height: 1.2, letter: 0.2),
      labelSmall:
          s(11, FontWeight.w600, height: 1.2, letter: 0.4, color: onSurfaceMuted),
    );
  }
}
