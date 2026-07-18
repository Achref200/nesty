import 'package:flutter/material.dart';

/// A compact three-dot "typing" loader. Three dots gently rise and fade in
/// sequence to signal work in progress — used while a request is still in
/// flight (e.g. an OAuth round-trip that hasn't returned yet).
class ThreeDotLoader extends StatefulWidget {
  const ThreeDotLoader({
    super.key,
    this.color = const Color(0xFF121212),
    this.size = 8,
    this.spacing = 6,
  });

  /// Colour of the dots.
  final Color color;

  /// Diameter of each dot.
  final double size;

  /// Gap between the dots.
  final double spacing;

  @override
  State<ThreeDotLoader> createState() => _ThreeDotLoaderState();
}

class _ThreeDotLoaderState extends State<ThreeDotLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i != 0) SizedBox(width: widget.spacing),
              _Dot(
                color: widget.color,
                size: widget.size,
                t: _phase(_controller.value, i),
              ),
            ],
          ],
        );
      },
    );
  }

  /// A 0..1 wave for dot [i], staggered so the dots animate in sequence.
  double _phase(double v, int i) {
    final shifted = (v - i * 0.18) % 1.0;
    // Ease up for the first half, back down for the second half.
    final eased = shifted < 0.5 ? shifted / 0.5 : (1 - shifted) / 0.5;
    return Curves.easeInOut.transform(eased.clamp(0.0, 1.0));
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size, required this.t});

  final Color color;
  final double size;
  final double t; // 0..1 animation phase

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -t * size * 0.6),
      child: Opacity(
        opacity: 0.4 + t * 0.6,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
