import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/branding/app_icons.dart';
import '../../../../core/theme/app_colors.dart';

/// A radar-style "homes near you" reveal. Concentric rings pulse out from an
/// ink centre (you), and nearby home/agency pins pop in around you, staggered.
/// Purely a delight moment for onboarding — wire it to real nearby results
/// (agency lat/lng within a radius) once that data exists.
class ProximityReveal extends StatefulWidget {
  const ProximityReveal({super.key, this.size = 300});

  final double size;

  // (angle°, radiusFactor 0..1, icon, isAgency)
  static const _pins = <(double, double, IconData, bool)>[
    (8, 0.44, AppIcons.home, false),
    (54, 0.68, AppIcons.agency, true),
    (108, 0.5, AppIcons.home, false),
    (158, 0.72, AppIcons.home, false),
    (206, 0.46, AppIcons.agency, false),
    (256, 0.66, AppIcons.home, false),
    (302, 0.54, AppIcons.agency, true),
    (342, 0.74, AppIcons.home, false),
  ];

  @override
  State<ProximityReveal> createState() => _ProximityRevealState();
}

class _ProximityRevealState extends State<ProximityReveal>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..forward();

  @override
  void dispose() {
    _pulse.dispose();
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final c = s / 2;
    return SizedBox(
      width: s,
      height: s,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, _) =>
                CustomPaint(size: Size(s, s), painter: _RadarPainter(_pulse.value)),
          ),
          ScaleTransition(
            scale: CurvedAnimation(
              parent: _reveal,
              curve: const Interval(0, 0.4, curve: Curves.easeOutBack),
            ),
            child: Container(
              width: 66,
              height: 66,
              decoration: BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.22),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.onAccent,
                size: 30,
              ),
            ),
          ),
          for (int i = 0; i < ProximityReveal._pins.length; i++)
            _pin(i, c, s),
        ],
      ),
    );
  }

  Widget _pin(int i, double c, double s) {
    final (angle, rf, icon, isAgency) = ProximityReveal._pins[i];
    final rad = angle * math.pi / 180;
    final radius = rf * (s * 0.44);
    final dx = radius * math.cos(rad);
    final dy = radius * math.sin(rad);

    final start = (0.28 + (i / ProximityReveal._pins.length) * 0.55)
        .clamp(0.0, 0.9);
    final end = (start + 0.3).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _reveal,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );

    const pinSize = 40.0;
    return Positioned(
      left: c + dx - pinSize / 2,
      top: c + dy - pinSize / 2,
      child: ScaleTransition(
        scale: anim,
        child: FadeTransition(
          opacity: anim,
          child: Container(
            width: pinSize,
            height: pinSize,
            decoration: BoxDecoration(
              color: isAgency ? AppColors.ink : AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.separator, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 17,
              color: isAgency ? AppColors.onAccent : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.width * 0.46;

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.separator;
    for (final f in const [0.34, 0.62, 0.9]) {
      canvas.drawCircle(center, maxR * f, ring);
    }

    final pr = maxR * (0.18 + t * 0.82);
    final pulse = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.ink.withValues(alpha: (1 - t) * 0.32);
    canvas.drawCircle(center, pr, pulse);
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) => oldDelegate.t != t;
}
