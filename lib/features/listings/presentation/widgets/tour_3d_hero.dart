import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_image.dart';
import '../../domain/entities/property.dart';
import '../pages/immersive_tour_page.dart';

/// The 3D tour entry point on the listing page — deliberately the boldest
/// element on screen. A slowly zooming cover with an animated "3D TOUR" badge
/// and a frosted "Enter" control that launches the full-screen experience.
class Tour3dHero extends StatefulWidget {
  const Tour3dHero({super.key, required this.property});

  final Property property;

  @override
  State<Tour3dHero> createState() => _Tour3dHeroState();
}

class _Tour3dHeroState extends State<Tour3dHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ken;

  @override
  void initState() {
    super.initState();
    _ken = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ken.dispose();
    super.dispose();
  }

  int get _roomCount =>
      widget.property.rooms.where((r) => r.images.isNotEmpty).length;

  void _open() {
    HapticFeedback.mediumImpact();
    ImmersiveTourPage.open(context, widget.property);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    return GestureDetector(
      onTap: _open,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AspectRatio(
          aspectRatio: 16 / 11,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Ken Burns cover.
              AnimatedBuilder(
                animation: _ken,
                builder: (context, child) => Transform.scale(
                  scale: 1.0 + _ken.value * 0.12,
                  child: child,
                ),
                child: Hero(
                  tag: 'property-image-${p.id}',
                  child: AppImage(p.coverImage, fit: BoxFit.cover),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x55000000),
                      Color(0x11000000),
                      Color(0x88000000),
                    ],
                    stops: [0, 0.4, 1],
                  ),
                ),
              ),

              // Animated 3D badge.
              Positioned(top: 14, left: 14, child: _Live3dBadge(anim: _ken)),

              // Center "Enter" control.
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Enter 3D tour',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom meta.
              Positioned(
                left: 16,
                bottom: 14,
                child: Row(
                  children: [
                    const Icon(
                      Icons.view_in_ar_rounded,
                      color: AppColors.white,
                      size: 15,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _roomCount > 0
                          ? '$_roomCount rooms · 360° views'
                          : 'Walkthrough video',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Live3dBadge extends StatelessWidget {
  const _Live3dBadge({required this.anim});
  final Animation<double> anim;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: anim,
            builder: (context, _) => Transform.rotate(
              angle: anim.value * 6.28318,
              child: const Icon(
                Icons.view_in_ar_rounded,
                size: 13,
                color: AppColors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            '3D TOUR',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
