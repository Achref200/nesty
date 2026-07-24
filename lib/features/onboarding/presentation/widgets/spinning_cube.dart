import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A floating 3D cube rendered with genuine perspective transforms. It turns
/// gently side-to-side (rather than a full spin) so faces never flip through
/// each other — giving a clean, premium "this is a 3D-first app" impression.
///
/// When [interactive] is true the user can drag to spin it themselves — the
/// core promise of the product (turn any home in 3D) made tangible in the very
/// first seconds. Their drag adds a persistent offset over the gentle idle sway.
///
/// Fully monochrome: near-black faces, faux directional lighting via black/white
/// overlays, and hairline white edges.
class SpinningCube extends StatefulWidget {
  const SpinningCube({
    super.key,
    this.size = 120,
    this.icon = Icons.view_in_ar_rounded,
    this.interactive = false,
    this.child,
  });

  final double size;
  final IconData icon;

  /// Rendered on the cube's front face instead of [icon] when provided — e.g.
  /// the Nesty logo, so the brand itself turns in 3D.
  final Widget? child;

  /// Lets the user drag to rotate the cube.
  final bool interactive;

  @override
  State<SpinningCube> createState() => _SpinningCubeState();
}

class _SpinningCubeState extends State<SpinningCube>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  // Persistent rotation the user has added by dragging.
  double _offsetYaw = 0;
  double _offsetPitch = 0;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _onDrag(DragUpdateDetails d) {
    setState(() {
      _offsetYaw += d.delta.dx * 0.012;
      _offsetPitch = (_offsetPitch - d.delta.dy * 0.012).clamp(-1.1, 0.7);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cube = AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * 2 * math.pi;
        // The idle sway is calmer when the cube is interactive, so the user's
        // own turning reads as the main motion.
        final swayScale = widget.interactive ? 0.45 : 1.0;
        final ay = math.sin(t) * 0.7 * swayScale + _offsetYaw; // yaw
        final ax =
            -0.32 + math.cos(t) * 0.12 * swayScale + _offsetPitch; // pitch
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateX(ax)
            ..rotateY(ay),
          child: _cube(),
        );
      },
    );

    if (!widget.interactive) return cube;

    return GestureDetector(
      onPanUpdate: _onDrag,
      behavior: HitTestBehavior.opaque,
      child: cube,
    );
  }

  Widget _cube() {
    final s = widget.size;
    final h = s / 2;
    // Painted back-to-front so the icon face stays on top within the yaw range.
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _face(
            Matrix4.identity()..translateByDouble(0, 0, -h, 1),
            shade: 0.55,
          ),
          _face(
            Matrix4.identity()
              ..rotateX(-math.pi / 2)
              ..translateByDouble(0, 0, h, 1),
            shade: 0.45,
          ),
          _face(
            Matrix4.identity()
              ..rotateY(-math.pi / 2)
              ..translateByDouble(0, 0, h, 1),
            shade: 0.34,
          ),
          _face(
            Matrix4.identity()
              ..rotateY(math.pi / 2)
              ..translateByDouble(0, 0, h, 1),
            shade: 0.28,
          ),
          _face(
            Matrix4.identity()
              ..rotateX(math.pi / 2)
              ..translateByDouble(0, 0, h, 1),
            shade: -0.16, // top catches light
          ),
          _face(
            Matrix4.identity()..translateByDouble(0, 0, h, 1),
            shade: 0.0,
            child: widget.child ??
                Icon(widget.icon, color: AppColors.white, size: s * 0.34),
          ),
        ],
      ),
    );
  }

  Widget _face(Matrix4 transform, {required double shade, Widget? child}) {
    final overlay = shade >= 0
        ? AppColors.black.withValues(alpha: shade)
        : AppColors.white.withValues(alpha: -shade);
    return Transform(
      alignment: Alignment.center,
      transform: transform,
      child: Container(
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accent,
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(child: ColoredBox(color: overlay)),
            ?child,
          ],
        ),
      ),
    );
  }
}
