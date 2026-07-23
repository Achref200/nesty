import 'package:flutter/material.dart';

import '../../branding/nestly_logo.dart';
import '../../config/app_config.dart';
import '../../theme/app_colors.dart';

/// Shared branded loading indicator — the nested-curves mark drawing itself on
/// a loop. Kept visually identical to the web `NestyLoader` (same three arcs,
/// same ~2s draw → hold → retract rhythm) so a page refresh or a wait for a
/// backend response feels the same on web and mobile.
class NestyLoader extends StatefulWidget {
  const NestyLoader({
    super.key,
    this.size = 72,
    this.color,
    this.showWordmark = false,
  });

  final double size;
  final Color? color;
  final bool showWordmark;

  @override
  State<NestyLoader> createState() => _NestyLoaderState();
}

class _NestyLoaderState extends State<NestyLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Maps the loop position to a draw fraction, mirroring the web keyframes:
  /// draw on over the first 35%, hold until 85%, then retract.
  double _drawFraction(double v) {
    if (v < 0.35) return v / 0.35;
    if (v < 0.85) return 1;
    return 1 - (v - 0.85) / 0.15;
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.accent;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress =
            Curves.easeInOut.transform(_drawFraction(_controller.value).clamp(0.0, 1.0));
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NestlyLogo(size: widget.size, color: color, progress: progress),
            if (widget.showWordmark) ...[
              const SizedBox(height: 12),
              Text(
                '${AppConfig.appName.toLowerCase()}.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ],
        );
      },
    );
  }
}
