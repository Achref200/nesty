import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'neu_tappable.dart';

/// A circular soft-morphism icon button used for back buttons, favorites, etc.
class NeuIconButton extends StatelessWidget {
  const NeuIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 48,
    this.iconColor,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color? iconColor;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return NeuTappable(
      onTap: onTap,
      borderRadius: size,
      depth: 6,
      color: active ? AppColors.accent : null,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          icon,
          size: size * 0.42,
          color: active
              ? AppColors.onAccent
              : (iconColor ?? AppColors.textPrimary),
        ),
      ),
    );
  }
}
