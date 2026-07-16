import 'package:flutter/material.dart';

/// Nestly's visual identity: a strict black / white / grey monochrome system.
///
/// The canvas is a soft, warm-white paper. Ink carries every action and accent
/// — there is no colour to distract from the homes themselves. Greys do all the
/// hierarchy work, hairlines separate, and a single restrained red is kept only
/// for genuine error states (never for decoration). The result reads calm,
/// architectural and quietly premium.
abstract final class AppColors {
  // ---- Backgrounds ----
  static const Color background = Color(0xFFFCFCFB); // soft paper white
  static const Color groupedBackground = Color(0xFFF4F4F3); // grouped bg
  static const Color card = Color(0xFFFFFFFF);
  static const Color fill = Color(0xFFF1F1F0); // search / segmented fills

  // Legacy aliases kept so existing widgets keep compiling.
  static const Color surface = background;
  static const Color surfaceElevated = Color(0xFFF1F1F0);

  // ---- Hairlines & shadows ----
  static const Color separator = Color(0xFFE6E6E4);
  static const Color shadow = Color(0x0F000000); // ~6% black, realistic
  static const Color shadowDark = Color(0x0F000000);
  static const Color shadowLight = Color(0xFFFFFFFF);

  // ---- Labels ----
  static const Color label = Color(0xFF121212); // near-black ink
  static const Color secondaryLabel = Color(0xFF7A7A78);
  static const Color tertiaryLabel = Color(0xFFB4B4B1);

  // Legacy text aliases.
  static const Color ink = Color(0xFF121212);
  static const Color inkSoft = Color(0xFF3C3C3B);
  static const Color textPrimary = label;
  static const Color textSecondary = secondaryLabel;
  static const Color textTertiary = tertiaryLabel;

  // ---- Brand & semantics (monochrome) ----
  // The "accent" is ink itself — every primary action is black on paper.
  static const Color accent = Color(0xFF141414);
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color accentSoft = Color(0xFFEDEDEB); // tinted (grey) surface
  static const Color accentDark = Color(0xFF000000);

  static const Color divider = separator;

  // Trends and status stay monochrome: up = ink, down = mid-grey. Only true
  // failures use the restrained red below.
  static const Color success = Color(0xFF1B1B1B);
  static const Color warning = Color(0xFF8A8A88);
  static const Color danger = Color(0xFFB23A34); // muted brick — errors only
  static const Color star = Color(0xFF141414); // ratings render in ink

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}
