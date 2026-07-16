import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ios/liquid_glass.dart';

/// A real, look-around 360° panorama — the closest thing to being in the room.
///
/// The equirectangular photo is mapped onto a sphere so you can pan in any
/// direction (up/down/left/right) with a drag. Toggle "Move" to hand control to
/// the gyroscope: turn your phone and the view turns with you, VR-style.
class PanoramaRoomView extends StatefulWidget {
  const PanoramaRoomView({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  State<PanoramaRoomView> createState() => _PanoramaRoomViewState();
}

class _PanoramaRoomViewState extends State<PanoramaRoomView> {
  bool _gyro = false;
  bool _showHint = true;

  void _toggleGyro() {
    HapticFeedback.mediumImpact();
    setState(() {
      _gyro = !_gyro;
      _showHint = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        PanoramaViewer(
          // A slow idle drift when hand-controlled; the gyroscope drives it in
          // motion mode.
          animSpeed: _gyro ? 0.0 : 0.35,
          sensorControl: _gyro ? SensorControl.orientation : SensorControl.none,
          sensitivity: 1.4,
          minZoom: 1.0,
          maxZoom: 2.4,
          onViewChanged: (_, _, _) => _dismissHint(),
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const ColoredBox(
                color: AppColors.black,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              );
            },
            errorBuilder: (_, _, _) => const ColoredBox(
              color: AppColors.black,
              child: Center(
                child: Icon(
                  Icons.view_in_ar_rounded,
                  color: AppColors.white,
                  size: 40,
                ),
              ),
            ),
          ),
        ),

        // 360 badge.
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.public_rounded, size: 14, color: AppColors.white),
                SizedBox(width: 6),
                Text(
                  '360° · Live',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Gyroscope / VR toggle.
        Positioned(
          right: 16,
          top: 16,
          child: GestureDetector(
            onTap: _toggleGyro,
            child: LiquidGlass.circle(
              dark: true,
              padding: const EdgeInsets.all(11),
              child: Icon(
                _gyro
                    ? Icons.open_with_rounded
                    : Icons.stay_current_portrait_rounded,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ),
        ),

        // Hint.
        Positioned(
          left: 0,
          right: 0,
          bottom: 26,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: _showHint ? 1 : 0,
              duration: const Duration(milliseconds: 400),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.swipe_rounded,
                        size: 15,
                        color: AppColors.white,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Drag to look around · tap ◎ for motion',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _dismissHint() {
    if (_showHint && mounted) setState(() => _showHint = false);
  }
}
