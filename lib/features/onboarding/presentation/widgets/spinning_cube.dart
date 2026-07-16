import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A floating 3D cube rendered with genuine perspective transforms. It turns
/// gently side-to-side (rather than a full spin) so faces never flip through
/// each other — giving a clean, premium "this is a 3D-first app" impression.
///
/// Fully monochrome: near-black faces, faux directional lighting via black/white
/// overlays, and hairline white edges.
class SpinningCube extends StatefulWidget {
  const SpinningCube({
    super.key,
    this.size = 120,
    this.icon = Icons.view_in_ar_rounded,
  });

  final double size;
  final IconData icon;

  @override
  State<SpinningCube> createState() => _SpinningCubeState();
}

class _SpinningCubeState extends State<SpinningCube>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * 2 * math.pi;
        final ay = math.sin(t) * 0.7; // yaw, ±40°
        final ax = -0.32 + math.cos(t) * 0.12; // slight downward pitch
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
            child: Icon(widget.icon, color: AppColors.white, size: s * 0.34),
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
