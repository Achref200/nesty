import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../theme/app_colors.dart';

/// A reusable "Liquid Glass" material, matching the iOS 26 design language:
/// a translucent, blurred pane that refracts what's behind it, finished with a
/// bright top highlight, a hairline rim light and a soft ambient shadow. Use it
/// for floating chrome — tab bars, toolbars, pills and circular controls.
class LiquidGlass extends StatelessWidget {
  const LiquidGlass({
    super.key,
    required this.child,
    this.radius = 28,
    this.padding,
    this.blur = 30,
    this.dark = false,
    this.tintOpacity = 0.62,
    this.shadow = true,
  });

  /// Circular glass — for floating action circles.
  const LiquidGlass.circle({
    super.key,
    required this.child,
    this.padding,
    this.blur = 30,
    this.dark = false,
    this.tintOpacity = 0.62,
    this.shadow = true,
  }) : radius = 999;

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final bool dark;
  final double tintOpacity;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final tint = (dark ? AppColors.black : AppColors.white).withValues(
      alpha: tintOpacity,
    );
    final rim = (dark ? AppColors.white : AppColors.white).withValues(
      alpha: dark ? 0.14 : 0.7,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: dark ? 0.35 : 0.14),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                  spreadRadius: -6,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: tint,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.white.withValues(alpha: dark ? 0.16 : 0.4),
                  AppColors.white.withValues(alpha: 0.0),
                ],
                stops: const [0, 0.55],
              ),
              border: Border.all(color: rim, width: 0.8),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
