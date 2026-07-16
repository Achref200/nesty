import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_image.dart';

/// A 360°-style orbit viewer built from a room's photos.
///
/// Inspiration: 360° product spinners (Sketchfab, car configurators) and
/// Matterport room views. Dragging horizontally rotates through the frames with
/// a crossfade + parallax so a handful of photos feel like one continuous
/// space. When left alone it slowly auto-orbits so the view always feels alive.
class Room360Viewer extends StatefulWidget {
  const Room360Viewer({super.key, required this.images, this.autoOrbit = true});

  final List<String> images;
  final bool autoOrbit;

  @override
  State<Room360Viewer> createState() => _Room360ViewerState();
}

class _Room360ViewerState extends State<Room360Viewer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _frame = 0;
  Duration _last = Duration.zero;
  bool _interacting = false;
  bool _showHint = true;
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final url in widget.images) {
      precacheImage(appImageProvider(url), context);
    }
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (!_interacting && widget.autoOrbit && widget.images.length > 1) {
      setState(() => _frame += dt * 0.45); // slow idle rotation
      _emitHapticOnFrame();
    }
  }

  void _emitHapticOnFrame() {
    final n = widget.images.length;
    if (n == 0) return;
    final idx = (_frame % n).floor();
    if (idx != _lastIndex) {
      _lastIndex = idx;
      HapticFeedback.selectionClick();
    }
  }

  void _onDragStart(DragStartDetails _) {
    _interacting = true;
    if (_showHint) setState(() => _showHint = false);
  }

  void _onDragUpdate(DragUpdateDetails d) {
    setState(() => _frame -= (d.primaryDelta ?? 0) / 42);
    _emitHapticOnFrame();
  }

  void _onDragEnd(DragEndDetails _) {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _interacting = false;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    if (images.isEmpty) {
      return const ColoredBox(
        color: AppColors.black,
        child: Center(
          child: Icon(
            Icons.view_in_ar_rounded,
            color: AppColors.white,
            size: 40,
          ),
        ),
      );
    }

    final n = images.length;
    var pf = _frame % n;
    if (pf < 0) pf += n;
    final i0 = pf.floor() % n;
    final frac = pf - pf.floorToDouble();
    final i1 = (i0 + 1) % n;
    final parallax = (frac - 0.5) * 18;

    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _frame3d(images[i0], 1 - frac, parallax),
          _frame3d(images[i1], frac, parallax - 18),
          // Cinematic vignette so overlays stay legible.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x33000000),
                  Color(0x00000000),
                  Color(0x55000000),
                ],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
          Positioned(top: 16, left: 16, child: _OrbitBadge(progress: pf / n)),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _showHint ? 1 : 0,
                duration: const Duration(milliseconds: 400),
                child: const _DragHint(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _frame3d(String url, double opacity, double dx) {
    return Opacity(
      opacity: opacity.clamp(0, 1),
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: Transform.scale(
          scale: 1.12,
          child: AppImage(url, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class _OrbitBadge extends StatelessWidget {
  const _OrbitBadge({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: progress * 6.28318,
            child: const Icon(
              Icons.threesixty_rounded,
              size: 14,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            '360°',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DragHint extends StatelessWidget {
  const _DragHint();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.swipe_rounded, size: 15, color: AppColors.white),
            SizedBox(width: 7),
            Text(
              'Drag to look around',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
