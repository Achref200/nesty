import 'package:flutter/widgets.dart';

import '../theme/app_colors.dart';

/// The Nesty brand mark: three nested arcs, open at the top — a stylised
/// "nest". Drawn as a vector so it stays crisp at any size.
class NestlyLogo extends StatelessWidget {
  const NestlyLogo({
    super.key,
    this.size = 64,
    this.color,
    this.progress = 1.0,
  });

  final double size;
  final Color? color;

  /// 0 → nothing drawn, 1 → fully drawn. Animate this for the draw-on effect.
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _NestlyMarkPainter(color ?? AppColors.accent, progress),
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
  const _NestlyMarkPainter(this.color, this.progress);

  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200.0;
    canvas.save();
    // Centre the 200×140 mark vertically within the (square) box.
    canvas.translate(0, (size.height - 140 * scale) / 2);
    canvas.scale(scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    // Three nested arcs, open at the top — the "nest". Each draws in turn as
    // [progress] animates 0 → 1 (staggered), or shows whole at progress 1.
    void arc(double width, double start, double end, Path full) {
      final t = ((progress - start) / (end - start)).clamp(0.0, 1.0);
      if (t <= 0) return;
      paint.strokeWidth = width;
      if (t >= 1) {
        canvas.drawPath(full, paint);
        return;
      }
      final drawn = Path();
      for (final m in full.computeMetrics()) {
        drawn.addPath(m.extractPath(0, m.length * t), Offset.zero);
      }
      canvas.drawPath(drawn, paint);
    }

    arc(
      10,
      0.0,
      0.55,
      Path()
        ..moveTo(20, 120)
        ..cubicTo(20, 45, 55, 20, 100, 20)
        ..cubicTo(145, 20, 180, 45, 180, 120),
    );
    arc(
      8.5,
      0.2,
      0.75,
      Path()
        ..moveTo(42, 125)
        ..cubicTo(42, 62, 65, 42, 100, 42)
        ..cubicTo(135, 42, 158, 62, 158, 125),
    );
    arc(
      7,
      0.4,
      0.95,
      Path()
        ..moveTo(62, 130)
        ..cubicTo(62, 80, 78, 62, 100, 62)
        ..cubicTo(122, 62, 138, 80, 138, 130),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_NestlyMarkPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.progress != progress;
}
