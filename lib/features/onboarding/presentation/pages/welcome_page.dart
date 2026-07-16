import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/branding/app_icons.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/motion/fade_slide_in.dart';
import '../../../../core/widgets/motion/shadow_words.dart';
import '../../../../core/widgets/motion/shimmer.dart';
import '../../../../core/widgets/neu/neu_button.dart';
import '../../../../core/widgets/neu/neu_tappable.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../widgets/proximity_reveal.dart';
import '../widgets/spinning_cube.dart';

/// A cinematic three-beat onboarding: first the 3D vision that sets Nesty
/// apart, then a live "homes near you" moment powered by device location, then
/// an intent-first role choice that pre-fills sign-up.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final PageController _controller = PageController();
  double _page = 0;

  // Two intro beats + the final role page.
  static const int _lastIndex = 2;

  static const _roleIcons = {
    UserRole.seeker: AppIcons.seeker,
    UserRole.host: AppIcons.agency,
  };

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _page = _controller.page ?? 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skip() => _controller.animateToPage(
    _lastIndex,
    duration: const Duration(milliseconds: 600),
    curve: Curves.easeOutCubic,
  );

  void _next() => _controller.nextPage(
    duration: const Duration(milliseconds: 500),
    curve: Curves.easeOutCubic,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onRolePage = _page > _lastIndex - 0.5;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.lg,
                AppSpacing.gutter,
                0,
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.home, size: 20, color: AppColors.accent),
                  const SizedBox(width: AppSpacing.sm),
                  Text(AppConfig.appName, style: theme.textTheme.titleMedium),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: onRolePage ? 0 : 1,
                    duration: const Duration(milliseconds: 250),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: onRolePage ? null : _skip,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: AppColors.secondaryLabel,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const BouncingScrollPhysics(),
                children: [
                  _VisionSlide(delta: _page),
                  _ProximitySlide(delta: _page - 1),
                  _RolePage(
                    roleIcons: _roleIcons,
                    delta: _page - _lastIndex,
                    onRole: (role) => context.push(AppRoutes.auth, extra: role),
                    onSignIn: () => context.push(AppRoutes.auth),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                0,
                AppSpacing.gutter,
                AppSpacing.lg,
              ),
              child: Row(
                children: [
                  _Dots(count: _lastIndex + 1, page: _page),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: onRolePage ? 0 : 1,
                    duration: const Duration(milliseconds: 250),
                    child: IgnorePointer(
                      ignoring: onRolePage,
                      child: _NextButton(onTap: _next),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Beat 1 — the 3D vision. A rotating cube plus an Airbnb-style duotone word
/// that cycles, signalling a spatial, creative product from the first second.
class _VisionSlide extends StatelessWidget {
  const _VisionSlide({required this.delta});
  final double delta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opacity = (1 - delta.abs()).clamp(0.0, 1.0);
    final display = theme.textTheme.displayLarge!;

    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(flex: 2),
            Center(
              child: Transform.translate(
                offset: Offset(delta * -120, 0),
                child: SpinningCube(size: 132, icon: AppIcons.tour3d),
              ),
            ),
            const Spacer(flex: 1),
            Transform.translate(
              offset: Offset(delta * -40, 0),
              child: Text('Tour before you', style: display),
            ),
            SizedBox(
              height: display.fontSize! * (display.height ?? 1.1) + 6,
              child: Transform.translate(
                offset: Offset(delta * -40, 0),
                child: ShadowWords(
                  words: const ['visit.', 'commit.', 'decide.'],
                  style: display,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Transform.translate(
              offset: Offset(delta * -22, 0),
              child: Text(
                'Every home in immersive 3D — walk it before you ever step '
                'inside.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

/// Beat 2 — location. We ask for the device location and then reveal a radar of
/// nearby homes and agencies with a warm "we're so close to you" moment.
class _ProximitySlide extends StatefulWidget {
  const _ProximitySlide({required this.delta});
  final double delta;

  @override
  State<_ProximitySlide> createState() => _ProximitySlideState();
}

class _ProximitySlideState extends State<_ProximitySlide> {
  bool _loading = false;
  bool _revealed = false;

  Future<void> _locate() async {
    setState(() => _loading = true);
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      final granted = perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
      if (serviceOn && granted) {
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        ).timeout(const Duration(seconds: 6));
      }
    } catch (_) {
      // Location is a delight, never a gate — fall through to the reveal.
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      _revealed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opacity = (1 - widget.delta.abs()).clamp(0.0, 1.0);
    final width = MediaQuery.of(context).size.width;

    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: _revealed
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  ProximityReveal(size: (width - 48).clamp(240.0, 320.0)),
                  const Spacer(flex: 1),
                  FadeSlideIn(
                    child: Text(
                      'We\'re so close to you!',
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: Text(
                      '12 homes and 4 agencies right around your corner.',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Spacer(flex: 3),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.fill,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: const Icon(
                      AppIcons.location,
                      size: 34,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(flex: 1),
                  Text(
                    'Homes, right\naround you.',
                    style: theme.textTheme.displayLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Share your location and Nesty surfaces the places and '
                    'agencies closest to you first.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  NeuButton(
                    label: 'Show what\'s nearby',
                    icon: AppIcons.location,
                    loading: _loading,
                    onPressed: _locate,
                  ),
                  const Spacer(flex: 3),
                ],
              ),
      ),
    );
  }
}

/// Final onboarding page — intent-first role selection.
class _RolePage extends StatelessWidget {
  const _RolePage({
    required this.roleIcons,
    required this.delta,
    required this.onRole,
    required this.onSignIn,
  });

  final Map<UserRole, IconData> roleIcons;
  final double delta;
  final ValueChanged<UserRole> onRole;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opacity = (1 - delta.abs()).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(),
            Shimmer(
              child: Text('Let\'s begin.', style: theme.textTheme.displayLarge),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'How do you want to use Nesty?',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            for (int i = 0; i < UserRole.values.length; i++) ...[
              FadeSlideIn(
                delay: Duration(milliseconds: 90 * i),
                child: _RoleCard(
                  role: UserRole.values[i],
                  icon: roleIcons[UserRole.values[i]]!,
                  onTap: () => onRole(UserRole.values[i]),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            const Spacer(),
            Center(
              child: TextButton(
                onPressed: onSignIn,
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: const [
                      TextSpan(text: 'Already with us?  '),
                      TextSpan(
                        text: 'Sign in',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

/// Animated page indicator — the active dot stretches into a bar.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.page});
  final int count;
  final double page;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < count; i++) ...[
          _dot(i),
          if (i != count - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }

  Widget _dot(int i) {
    final proximity = (1 - (page - i).abs()).clamp(0.0, 1.0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 8 + proximity * 18,
      height: 8,
      decoration: BoxDecoration(
        color: Color.lerp(AppColors.separator, AppColors.accent, proximity),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _NextButton extends StatelessWidget {
  const _NextButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 54,
        height: 54,
        decoration: const BoxDecoration(
          color: AppColors.accent,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_forward_rounded,
          color: AppColors.onAccent,
          size: 24,
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.icon,
    required this.onTap,
  });

  final UserRole role;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NeuTappable(
      onTap: onTap,
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: AppColors.onAccent, size: 26),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(role.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(role.subtitle, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
