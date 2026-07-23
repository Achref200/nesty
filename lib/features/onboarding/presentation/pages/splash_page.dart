import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/branding/nestly_logo.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/motion/shimmer.dart';
import '../../../../core/widgets/neu/neu_surface.dart';

/// Minimal splash shown while the auth session is being restored. The mark
/// scales and fades in, breathes gently, and the wordmark catches a soft
/// monochrome shimmer — a premium first impression.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);

  late final Animation<double> _scale = CurvedAnimation(
    parent: _intro,
    curve: Curves.easeOutBack,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.1, 1, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _intro.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scale,
                child: AnimatedBuilder(
                  animation: _breath,
                  builder: (context, child) => Transform.scale(
                    scale: 1 + _breath.value * 0.04,
                    child: child,
                  ),
                  child: NeuSurface(
                    borderRadius: 28,
                    depth: 12,
                    padding: const EdgeInsets.all(22),
                    child: AnimatedBuilder(
                      animation: _intro,
                      builder: (context, _) => NestlyLogo(
                        size: 52,
                        color: AppColors.accent,
                        progress: _intro.value,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Shimmer(
                child: Text(
                  AppConfig.appName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(letterSpacing: 1.5),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppConfig.tagline,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
