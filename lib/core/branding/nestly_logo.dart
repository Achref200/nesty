import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';

/// The Nestly brand mark: a soft geometric house with a circular "nest"
/// aperture cut out of it. Drawn as a vector so it stays crisp at any size and
/// matches the launcher icon pixel-for-pixel.
class NestlyLogo extends StatelessWidget {
  const NestlyLogo({super.key, this.size = 64, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _NestlyMarkPainter(color ?? AppColors.accent),
      ),
    );
  }
}

/// A rounded "app tile" version of the mark — a squircle background with the
/// mark reversed out of it. Used for the splash and in branding contexts.
class NestlyTile extends StatelessWidget {
  const NestlyTile({
    super.key,
    this.size = 96,
    this.background,
    this.foreground,
  });

  final double size;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? AppColors.accent,
        borderRadius: BorderRadius.circular(size * 0.235), // iOS squircle-ish
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            offset: Offset(0, size * 0.08),
            blurRadius: size * 0.2,
            spreadRadius: -size * 0.05,
          ),
        ],
      ),
      child: Center(
        child: NestlyLogo(
          size: size * 0.56,
          color: foreground ?? AppColors.onAccent,
        ),
      ),
    );
  }
}

class _NestlyMarkPainter extends CustomPainter {
  const _NestlyMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100.0;
    canvas.save();
    canvas.scale(s);

    // House silhouette (pentagon) with softly rounded corners.
    final house = Path()
      ..moveTo(24, 80)
      ..lineTo(24, 47)
      ..quadraticBezierTo(24, 43, 27, 40)
      ..lineTo(46, 24)
      ..quadraticBezierTo(50, 20.5, 54, 24)
      ..lineTo(73, 40)
      ..quadraticBezierTo(76, 43, 76, 47)
      ..lineTo(76, 80)
      ..quadraticBezierTo(76, 82, 74, 82)
      ..lineTo(26, 82)
      ..quadraticBezierTo(24, 82, 24, 80)
      ..close();

    // Circular "nest" aperture.
    final aperture = Path()
      ..addOval(Rect.fromCircle(center: const Offset(50, 54), radius: 11.5));

    final mark = Path.combine(PathOperation.difference, house, aperture);
    canvas.drawPath(
      mark,
      Paint()
        ..color = color
        ..isAntiAlias = true,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_NestlyMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
