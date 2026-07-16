import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Primary call-to-action. Two variants:
/// * filled (near-black ink) for the main action on a screen
/// * soft (grey fill) for secondary actions
class NeuButton extends StatelessWidget {
  const NeuButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.filled = true,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(
                filled ? AppColors.onAccent : AppColors.label,
              ),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(
              icon,
              size: 19,
              color: filled ? AppColors.onAccent : AppColors.label,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              letterSpacing: -0.41,
              color: filled ? AppColors.onAccent : AppColors.label,
            ),
          ),
        ],
      ],
    );

    if (filled) {
      return _PressFeedback(
        enabled: enabled,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                onPressed!();
              }
            : null,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: content,
        ),
      );
    }

    return _PressFeedback(
      enabled: enabled,
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              onPressed!();
            }
          : null,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.fill,
          borderRadius: BorderRadius.circular(14),
        ),
        child: content,
      ),
    );
  }
}

/// Wraps a control with the iOS press feel: a quick dim + subtle scale-down
/// while held. Disabled controls render at 40% and ignore taps.
class _PressFeedback extends StatefulWidget {
  const _PressFeedback({
    required this.child,
    required this.enabled,
    this.onTap,
  });

  final Widget child;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  State<_PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<_PressFeedback> {
  bool _down = false;

  void _set(bool v) {
    if (!widget.enabled) return;
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: !widget.enabled ? 0.4 : (_down ? 0.85 : 1),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          scale: _down ? 0.97 : 1,
          child: widget.child,
        ),
      ),
    );
  }
}
