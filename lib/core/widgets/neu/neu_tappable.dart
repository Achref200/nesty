import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'neu_surface.dart';

/// A tappable iOS-style card/row. On press it dims and scales down very
/// slightly for tactile feedback (like a native `UITableViewCell` highlight),
/// with selection haptics.
class NeuTappable extends StatefulWidget {
  const NeuTappable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = 16,
    this.padding,
    this.depth = 8,
    this.color,
    this.border = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double depth;
  final Color? color;
  final bool border;

  @override
  State<NeuTappable> createState() => _NeuTappableState();
}

class _NeuTappableState extends State<NeuTappable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null) return;
    if (value) HapticFeedback.selectionClick();
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.72 : 1,
        duration: const Duration(milliseconds: 100),
        child: AnimatedScale(
          scale: _pressed ? 0.985 : 1,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          child: NeuSurface(
            borderRadius: widget.borderRadius,
            padding: widget.padding,
            depth: widget.depth,
            color: widget.color,
            border: widget.border,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
