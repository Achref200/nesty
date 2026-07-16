import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Nestly's type system. A modern geometric display face — Outfit — carries
/// titles and headings (a clean, architectural fit for a spatial PropTech
/// product), while Plus Jakarta Sans handles body and UI copy for a warm,
/// highly legible read. Applied through the Material [TextTheme] so every
/// `Text` reads from one source of truth.
abstract final class AppTypography {
  /// Display face used for large titles and headings.
  static TextStyle display({
    required double size,
    double height = 1.05,
    FontWeight weight = FontWeight.w600,
    double spacing = -0.5,
    Color color = AppColors.label,
  }) => GoogleFonts.outfit(
    fontSize: size,
    height: height,
    fontWeight: weight,
    letterSpacing: spacing,
    color: color,
  );

  /// Sans used for body, labels and controls.
  static TextStyle sans({
    required double size,
    double height = 1.3,
    FontWeight weight = FontWeight.w400,
    double spacing = -0.1,
    Color color = AppColors.label,
  }) => GoogleFonts.plusJakartaSans(
    fontSize: size,
    height: height,
    fontWeight: weight,
    letterSpacing: spacing,
    color: color,
  );

  static TextTheme textTheme(TextTheme base) {
    return base.copyWith(
      // Large Title
      displayLarge: display(size: 34, height: 1.04, weight: FontWeight.w700),
      // Title 1
      headlineMedium: display(size: 27, height: 1.1, weight: FontWeight.w700),
      // Title 3
      titleLarge: display(size: 21, height: 1.18, weight: FontWeight.w600),
      // Headline — Inter (semibold)
      titleMedium: sans(size: 17, height: 1.29, weight: FontWeight.w600),
      // Body — Inter
      bodyLarge: sans(size: 16, height: 1.45, weight: FontWeight.w400),
      // Subhead — Inter
      bodyMedium: sans(
        size: 15,
        height: 1.33,
        weight: FontWeight.w400,
        spacing: -0.1,
        color: AppColors.secondaryLabel,
      ),
      // Button / emphasised label — Inter
      labelLarge: sans(size: 16, weight: FontWeight.w600),
    );
  }
}
