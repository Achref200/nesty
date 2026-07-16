import 'package:flutter/material.dart';

/// A lightweight entrance animation: the child fades in while sliding up a few
/// points. Use [delay] to stagger a group of these for a cascading reveal.
///
/// Deliberately monochrome-friendly — it only animates opacity and offset, so
/// it never introduces colour and preserves the black/white/grey identity.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.offset = const Offset(0, 24),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Starting translation (in logical pixels) relative to the resting position.
  final Offset offset;
  final Curve curve;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: widget.offset,
    end: Offset.zero,
  ).animate(_fade);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fade,
      builder: (context, child) => Opacity(
        opacity: _fade.value.clamp(0.0, 1.0),
        child: Transform.translate(offset: _slide.value, child: child),
      ),
      child: widget.child,
    );
  }
}

/// Convenience helper to stagger a list of children with a fixed step delay.
class StaggeredColumn extends StatelessWidget {
  const StaggeredColumn({
    super.key,
    required this.children,
    this.step = const Duration(milliseconds: 70),
    this.initialDelay = Duration.zero,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.offset = const Offset(0, 24),
  });

  final List<Widget> children;
  final Duration step;
  final Duration initialDelay;
  final CrossAxisAlignment crossAxisAlignment;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (int i = 0; i < children.length; i++)
          FadeSlideIn(
            delay: initialDelay + step * i,
            offset: offset,
            child: children[i],
          ),
      ],
    );
  }
}
