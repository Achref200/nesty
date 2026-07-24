import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/branding/app_icons.dart';
import '../../../../core/branding/nestly_logo.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/motion/fade_slide_in.dart';
import '../../../../core/widgets/motion/shimmer.dart';
import '../../../../core/widgets/neu/neu_button.dart';
import '../../../../core/widgets/neu/neu_tappable.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../subscription/presentation/pages/paywall_page.dart';
import '../widgets/feature_mocks.dart';
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

  // Two intro beats + a features/roles showcase + the final role page.
  static const int _lastIndex = 3;

  static const _roleIcons = {
    UserRole.seeker: AppIcons.seeker,
    UserRole.host: AppIcons.agency,
    UserRole.partner: AppIcons.partner,
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

  /// Routes a chosen role into sign-up. The Partner role is paid, so it goes
  /// through the subscription paywall first; only on confirmation does it
  /// continue to account creation (where the chosen plan is committed).
  Future<void> _chooseRole(UserRole role) async {
    if (role == UserRole.partner) {
      final proceed = await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute(builder: (_) => const PaywallPage()));
      if (proceed == true && mounted) {
        context.push(AppRoutes.auth, extra: role);
      }
      return;
    }
    context.push(AppRoutes.auth, extra: role);
  }

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
                  const NestlyLogo(
                    size: 24,
                    color: AppColors.accent,
                    progress: 1,
                  ),
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
                      child: Text(
                        context.copy('Skip', 'Passer'),
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
                  _ShowcaseSlide(delta: _page - 2),
                  _RolePage(
                    roleIcons: _roleIcons,
                    delta: _page - _lastIndex,
                    onRole: (role) => _chooseRole(role),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpinningCube(
                      size: 150,
                      interactive: true,
                      child: const NestlyLogo(
                        size: 62,
                        color: AppColors.white,
                        progress: 1,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _DragHint(),
                  ],
                ),
              ),
            ),
            const Spacer(flex: 1),
            Transform.translate(
              offset: Offset(delta * -40, 0),
              child: Text(
                context.copy('Tour before you', 'Visitez avant de'),
                style: display,
              ),
            ),
            SizedBox(
              height: display.fontSize! * (display.height ?? 1.1) + 6,
              child: Transform.translate(
                offset: Offset(delta * -40, 0),
                child: _TypewriterCycle(
                  words: context.isFrench
                      ? const ['visiter.', 'choisir.', 'décider.']
                      : const ['visit.', 'commit.', 'decide.'],
                  style: display,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Transform.translate(
              offset: Offset(delta * -22, 0),
              child: Text(
                context.copy(
                  'Nesty rebuilds every home as an immersive 3D model. Grab it, '
                      'turn it, and walk through it before you ever step inside.',
                  'Nesty reconstruit chaque logement en modèle 3D immersif. '
                      'Faites-le tourner et explorez-le avant même votre visite.',
                ),
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

/// A subtle, pulsing "drag me" affordance shown under the interactive cube.
class _DragHint extends StatefulWidget {
  const _DragHint();

  @override
  State<_DragHint> createState() => _DragHintState();
}

class _DragHintState extends State<_DragHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(_c),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.fill,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.touch_app_outlined, size: 15, color: AppColors.ink),
            SizedBox(width: 6),
            Text(
              'Drag to spin the model',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A clean, Airbnb-style typewriter: types a word, holds, deletes, and moves to
/// the next — with a soft blinking caret. Pure ink, no coloured shadow.
class _TypewriterCycle extends StatefulWidget {
  const _TypewriterCycle({required this.words, required this.style});
  final List<String> words;
  final TextStyle style;

  @override
  State<_TypewriterCycle> createState() => _TypewriterCycleState();
}

class _TypewriterCycleState extends State<_TypewriterCycle> {
  int _word = 0;
  int _chars = 0;
  bool _deleting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule(const Duration(milliseconds: 600));
  }

  void _schedule(Duration d) => _timer = Timer(d, _tick);

  void _tick() {
    if (!mounted) return;
    final full = widget.words[_word];
    if (!_deleting) {
      _chars++;
      if (_chars >= full.length) {
        _deleting = true;
        setState(() {});
        _schedule(const Duration(milliseconds: 1100)); // hold, then delete
        return;
      }
      setState(() {});
      _schedule(const Duration(milliseconds: 90));
    } else {
      _chars--;
      if (_chars <= 0) {
        _deleting = false;
        _word = (_word + 1) % widget.words.length;
        setState(() {});
        _schedule(const Duration(milliseconds: 260));
        return;
      }
      setState(() {});
      _schedule(const Duration(milliseconds: 45));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final full = widget.words[_word];
    final shown = full.substring(0, _chars.clamp(0, full.length));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(shown, style: widget.style, maxLines: 1)),
        _Caret(height: (widget.style.fontSize ?? 28) * 0.86),
      ],
    );
  }
}

/// A soft blinking caret bar for the typewriter.
class _Caret extends StatefulWidget {
  const _Caret({required this.height});
  final double height;

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.15, end: 1).animate(_c),
        child: Container(
          width: 3,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
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
      final granted =
          perm == LocationPermission.always ||
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
    final display = theme.textTheme.displayLarge!;
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
                      context.copy(
                        'We\'re so close to you!',
                        'On est tout près de vous !',
                      ),
                      style: theme.textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: Text(
                      context.copy(
                        '12 homes and 4 agencies right around your corner.',
                        '12 logements et 4 agences juste à côté de vous.',
                      ),
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
                  Center(child: _LocatingScene(active: _loading)),
                  const Spacer(flex: 1),
                  Text(
                    context.copy('Homes, right', 'Des logements,'),
                    style: display,
                  ),
                  SizedBox(
                    height: display.fontSize! * (display.height ?? 1.1) + 6,
                    child: _TypewriterCycle(
                      words: context.isFrench
                          ? const ['tout près.', 'à côté.', 'juste là.']
                          : const ['around you.', 'near you.', 'next door.'],
                      style: display,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.copy(
                      'Share your location and Nesty surfaces the places and '
                      'agencies closest to you first — in 3D.',
                      'Partagez votre position : Nesty fait remonter les '
                      'logements et agences les plus proches — en 3D.',
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  NeuButton(
                    label: context.copy(
                      'Show what\'s nearby',
                      'Voir ce qui est proche',
                    ),
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

/// A small 3D "locating" scene — a rotating cube pinned with a location marker,
/// haloed by pulsing rings that quicken while we actually resolve the position.
class _LocatingScene extends StatefulWidget {
  const _LocatingScene({required this.active});
  final bool active;

  @override
  State<_LocatingScene> createState() => _LocatingSceneState();
}

class _LocatingSceneState extends State<_LocatingScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  for (int i = 0; i < 3; i++) _ring((_c.value + i / 3) % 1.0),
                ],
              );
            },
          ),
          SpinningCube(size: 104, icon: AppIcons.location),
        ],
      ),
    );
  }

  Widget _ring(double t) {
    final size = 90 + t * 110;
    // Rings glow stronger and reach a touch further while we're resolving the
    // real position, so activating location feels alive.
    final base = widget.active ? 0.7 : 0.45;
    final opacity = (1 - t) * base;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.ink.withValues(alpha: opacity),
          width: widget.active ? 1.8 : 1.4,
        ),
      ),
    );
  }
}

/// Beat 3 — a features/roles showcase. An auto-playing, monochrome "preview"
/// (our GIF stand-in) that cycles the three ways to use Nesty and the standout
/// feature of each, so newcomers grasp the product — and the new Partner role —
/// before they choose.
class _ShowcaseSlide extends StatefulWidget {
  const _ShowcaseSlide({required this.delta});
  final double delta;

  @override
  State<_ShowcaseSlide> createState() => _ShowcaseSlideState();
}

class _ShowcaseSlideState extends State<_ShowcaseSlide> {
  int _i = 0;
  Timer? _timer;
  static const _count = 4;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 3200), (_) {
      if (!mounted) return;
      setState(() => _i = (_i + 1) % _count);
    });
  }

  String _label(BuildContext context, int i) => switch (i) {
    0 => context.copy('Reserve a stay', 'Réservez un séjour'),
    1 => context.copy('Prepare your trip', 'Préparez votre voyage'),
    2 => context.copy('Tour in 3D', 'Visitez en 3D'),
    _ => context.copy('Discover nearby', 'Explorez autour'),
  };

  Widget _mock(int i) => switch (i) {
    0 => const ReserveMock(),
    1 => const TripPrepMock(),
    2 => const Tour3dMock(),
    _ => const NearbyMock(),
  };

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opacity = (1 - widget.delta.abs()).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.copy('One app,', 'Une seule app,'),
              style: theme.textTheme.displayLarge,
            ),
            Text(
              context.copy(
                'everything you need.',
                'tout ce qu\'il vous faut.',
              ),
              style: theme.textTheme.displayLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.copy(
                'Reserve, prepare, tour in 3D and discover what\'s near you.',
                'Réservez, préparez, visitez en 3D et explorez autour de vous.',
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: PhoneFrame(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 480),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.06),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_i),
                        child: _mock(_i),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _label(context, _i),
                  key: ValueKey(_i),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < _count; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _i ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _i ? AppColors.accent : AppColors.separator,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

/// Final onboarding page — intent-first role selection.
class _RolePage extends StatefulWidget {
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
  State<_RolePage> createState() => _RolePageState();
}

class _RolePageState extends State<_RolePage> {
  static const _order = [UserRole.seeker, UserRole.partner, UserRole.host];

  late final PageController _controller = PageController(
    viewportFraction: 0.78,
  );
  double _page = 0;

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

  UserRole get _current => _order[_page.round().clamp(0, _order.length - 1)];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opacity = (1 - widget.delta.abs()).clamp(0.0, 1.0);

    return Opacity(
      opacity: opacity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer(
                  child: Text(
                    'Choose your\nspace.',
                    style: theme.textTheme.displayLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Swipe the cards — each role opens a different Nesty.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 340,
            child: PageView.builder(
              controller: _controller,
              itemCount: _order.length,
              padEnds: true,
              itemBuilder: (context, i) {
                final role = _order[i];
                // A "card-game" feel: the focused card sits upright and full,
                // neighbours shrink and tilt away.
                final diff = (_page - i);
                final scale = (1 - diff.abs() * 0.14).clamp(0.82, 1.0);
                return Transform.rotate(
                  angle: diff * -0.05,
                  child: Transform.scale(
                    scale: scale,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      child: _RoleBigCard(
                        role: role,
                        icon: widget.roleIcons[role]!,
                        onTap: () => widget.onRole(role),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < _order.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _page.round() == i ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page.round() == i
                          ? AppColors.accent
                          : AppColors.separator,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: NeuButton(
              label: 'Continue as ${_current.shortLabel}',
              icon: AppIcons.forward,
              onPressed: () => widget.onRole(_current),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: widget.onSignIn,
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

/// A large, tappable role card for the swipeable chooser — icon, title, a short
/// pitch and a "select" affordance. The Partner card carries a subtle paid hint.
class _RoleBigCard extends StatelessWidget {
  const _RoleBigCard({
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
      borderRadius: AppRadius.xl,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, color: AppColors.onAccent, size: 32),
          ),
          const Spacer(),
          Row(
            children: [
              Text(role.shortLabel, style: theme.textTheme.headlineMedium),
              if (role == UserRole.partner) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.fill,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    'PLAN',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            role.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Text(
                'Choose ${role.shortLabel}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
