import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// The base surface for the app. Rather than heavy soft-morphism, this now
/// renders as a clean iOS card: a white panel with a true hairline border and
/// a single, realistic soft shadow. When [pressed] it becomes a recessed grey
/// fill (like an iOS grouped text field).
class NeuSurface extends StatelessWidget {
  const NeuSurface({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding,
    this.color,
    this.depth = 8,
    this.pressed = false,
    this.intensity = 1,
    this.border = true,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  /// Controls how pronounced the drop shadow is.
  final double depth;

  /// When true, the surface looks recessed (an inset grey fill).
  final bool pressed;

  /// Multiplier for shadow strength.
  final double intensity;

  /// Whether to draw the hairline border.
  final bool border;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    if (pressed) {
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: color ?? AppColors.fill,
        ),
        child: child,
      );
    }

    final base = color ?? AppColors.card;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: base,
        borderRadius: radius,
        border: border
            ? Border.all(color: AppColors.separator, width: 0.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(
              alpha: AppColors.shadow.a * intensity.clamp(0, 1.4),
            ),
            offset: Offset(0, depth * 0.5),
            blurRadius: depth * 2.2,
            spreadRadius: -depth * 0.5,
          ),
        ],
      ),
      child: child,
    );
  }
}
