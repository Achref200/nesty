import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/branding/app_icons.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/motion/page_transitions.dart';
import '../../../../core/widgets/motion/typing_text.dart';
import '../../../../core/widgets/neu/neu_button.dart';
import '../../../../core/widgets/neu/neu_field.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/profile_setup_store.dart';
import '../../domain/profile_setup.dart';

/// A light, one-time "tell us about you" flow shown right after a member's
/// first sign-up. Same calm paged design as the identity-verification step —
/// an intro, a few quick questions (where they're from, what they're after),
/// and a warm finish — so the app can tailor discovery from the first session.
///
/// Resolves to true once the answers are saved (or skipped).
Future<bool> startProfileSetupFlow(BuildContext context) async {
  final result = await Navigator.of(context).push<bool>(
    softPageRoute(const _ProfileSetupFlow(), fullscreenDialog: true),
  );
  return result ?? false;
}

class _ProfileSetupFlow extends StatefulWidget {
  const _ProfileSetupFlow();

  @override
  State<_ProfileSetupFlow> createState() => _ProfileSetupFlowState();
}

class _ProfileSetupFlowState extends State<_ProfileSetupFlow> {
  // 0 intro · 1 where · 2 purpose · 3 who · 4 budget · 5 areas · 6 done
  static const _lastStep = 6;

  int _step = 0;
  bool _forward = true;
  String? _error;
  bool _saving = false;

  String? _country;
  final _city = TextEditingController();
  String? _purpose;
  String? _household;
  String? _budget;
  final Set<String> _regions = {};

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  void _go(int next) {
    setState(() {
      _forward = next > _step;
      _error = null;
      _step = next;
    });
  }

  bool _validate() {
    switch (_step) {
      case 1:
        if (_country == null) {
          _fail(context.copy('Pick where you\'re joining from.',
              'Indiquez d\'où vous nous rejoignez.'));
          return false;
        }
        return true;
      case 2:
        if (_purpose == null) {
          _fail(context.copy('Tell us what brings you here.',
              'Dites-nous ce qui vous amène.'));
          return false;
        }
        return true;
      default:
        return true;
    }
  }

  void _fail(String message) {
    HapticFeedback.mediumImpact();
    setState(() => _error = message);
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);
    await sl<ProfileSetupStore>().save(
      ProfileSetup(
        country: _country,
        city: _city.text.trim().isEmpty ? null : _city.text.trim(),
        purpose: _purpose,
        household: _household,
        budget: _budget,
        regions: _regions.toList(),
      ),
    );
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = false);
    _go(_lastStep);
  }

  Future<void> _skip() async {
    await sl<ProfileSetupStore>().skip();
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final onDone = _step == _lastStep;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              step: _step,
              lastStep: _lastStep,
              onBack: _step == 0 || onDone ? null : () => _go(_step - 1),
              onSkip: onDone ? null : _skip,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 340),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) {
                  final slide = Tween<Offset>(
                    begin: Offset(_forward ? 0.12 : -0.12, 0),
                    end: Offset.zero,
                  ).animate(anim);
                  return FadeTransition(
                    opacity: anim,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.lg,
                    AppSpacing.gutter,
                    AppSpacing.xl,
                  ),
                  child: _stepBody(),
                ),
              ),
            ),
            if (!onDone) _footer(),
          ],
        ),
      ),
    );
  }

  Widget _stepBody() => switch (_step) {
    0 => _introStep(),
    1 => _whereStep(),
    2 => _purposeStep(),
    3 => _householdStep(),
    4 => _budgetStep(),
    5 => _areasStep(),
    _ => _doneStep(),
  };

  // ---- Step 0: intro ----
  Widget _introStep() {
    final theme = Theme.of(context);
    final name = context.read<AuthCubit>().state.user?.displayName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.fill,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: const Icon(AppIcons.about, size: 28, color: AppColors.ink),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          name != null
              ? context.copy('Welcome, $name', 'Bienvenue, $name')
              : context.copy('Welcome to Nesty', 'Bienvenue sur Nesty'),
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.copy(
            'A few quick questions so we can tailor homes and areas to you. '
                'It takes about a minute.',
            'Quelques questions rapides pour adapter les logements et les '
                'régions à vous. Cela prend une minute.',
          ),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        _Benefit(
          icon: AppIcons.location,
          title: context.copy('Homes near you', 'Des logements près de vous'),
          subtitle: context.copy(
            'We surface the right cities and regions first.',
            'Nous mettons en avant les bonnes villes en premier.',
          ),
        ),
        _Benefit(
          icon: AppIcons.tour3d,
          title: context.copy('Made to fit', 'À votre mesure'),
          subtitle: context.copy(
            'Budget and household shape what you see.',
            'Budget et foyer façonnent vos résultats.',
          ),
        ),
        _Benefit(
          icon: AppIcons.lock,
          title: context.copy('Private', 'Confidentiel'),
          subtitle: context.copy(
            'Only used to personalise your experience.',
            'Utilisé uniquement pour personnaliser votre expérience.',
          ),
          last: true,
        ),
      ],
    );
  }

  // ---- Step 1: where ----
  Widget _whereStep() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.copy('Where are you from?', 'D\'où venez-vous ?'),
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.copy(
            'It helps us welcome locals, tourists and the diaspora right.',
            'Cela nous aide à bien accueillir locaux, touristes et diaspora.',
          ),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        _MiniLabel(context.copy('Country', 'Pays')),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final o in SetupCatalog.countries)
              _SelectPill(
                label: o.label(context.isFrench),
                selected: _country == o.id,
                onTap: () => setState(() {
                  _country = o.id;
                  _error = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _MiniLabel(context.copy('City', 'Ville')),
        const SizedBox(height: AppSpacing.sm),
        NeuField(
          controller: _city,
          placeholder: context.copy('e.g. Tunis, Paris…', 'ex. Tunis, Paris…'),
          icon: AppIcons.location,
          textCapitalization: TextCapitalization.words,
        ),
        if (_error != null) _errorRow(_error!),
      ],
    );
  }

  // ---- Step 2: purpose ----
  Widget _purposeStep() => _choiceStep(
    title: context.copy('What brings you to Nesty?', 'Qu\'est-ce qui vous amène ?'),
    subtitle: context.copy(
      'We\'ll shape your feed around it.',
      'Nous adapterons votre fil en conséquence.',
    ),
    options: SetupCatalog.purposes,
    selected: _purpose,
    onSelect: (id) => setState(() {
      _purpose = id;
      _error = null;
    }),
  );

  // ---- Step 3: household ----
  Widget _householdStep() => _choiceStep(
    title: context.copy('Who\'s usually with you?', 'Qui vous accompagne ?'),
    subtitle: context.copy(
      'So we can match the right size of home.',
      'Pour proposer la bonne taille de logement.',
    ),
    options: SetupCatalog.households,
    selected: _household,
    onSelect: (id) => setState(() => _household = id),
  );

  // ---- Step 4: budget ----
  Widget _budgetStep() => _choiceStep(
    title: context.copy('What\'s your budget?', 'Quel est votre budget ?'),
    subtitle: context.copy(
      'A rough band is enough — you can change it anytime.',
      'Une fourchette suffit — modifiable à tout moment.',
    ),
    options: SetupCatalog.budgets,
    selected: _budget,
    onSelect: (id) => setState(() => _budget = id),
  );

  // ---- Step 5: areas (multi) ----
  Widget _areasStep() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.copy('Where would you go?', 'Où aimeriez-vous aller ?'),
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.copy(
            'Pick any regions you\'re curious about (optional).',
            'Choisissez les régions qui vous intéressent (facultatif).',
          ),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final o in SetupCatalog.regions)
              _SelectPill(
                label: o.label(context.isFrench),
                selected: _regions.contains(o.id),
                onTap: () => setState(() {
                  if (!_regions.add(o.id)) _regions.remove(o.id);
                }),
              ),
          ],
        ),
      ],
    );
  }

  // ---- Step 6: done ----
  Widget _doneStep() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 620),
            curve: Curves.easeOutBack,
            builder: (context, t, child) =>
                Transform.scale(scale: t, child: child),
            child: Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.check,
                color: AppColors.onAccent,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          TypingText(
            context.copy('You\'re all set.', 'Tout est prêt.'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
            startDelay: const Duration(milliseconds: 260),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.copy(
              'Your Nesty is tailored to you. Let\'s find your next place.',
              'Votre Nesty est personnalisé. Trouvons votre prochain logement.',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xxl),
          NeuButton(
            label: context.copy('Start exploring', 'Commencer à explorer'),
            icon: AppIcons.forward,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  // ---- Shared single-choice step ----
  Widget _choiceStep({
    required String title,
    required String subtitle,
    required List<SetupOption> options,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(subtitle, style: theme.textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xl),
        for (final o in options) ...[
          _ChoiceCard(
            icon: o.icon ?? AppIcons.check,
            title: o.label(context.isFrench),
            selected: selected == o.id,
            onTap: () => onSelect(o.id),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (_error != null) _errorRow(_error!),
      ],
    );
  }

  Widget _footer() {
    final isLastQuestion = _step == _lastStep - 1;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.md,
        AppSpacing.gutter,
        MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.separator, width: 0.5)),
      ),
      child: NeuButton(
        label: _step == 0
            ? context.copy('Get started', 'Commencer')
            : (isLastQuestion
                  ? context.copy('Finish', 'Terminer')
                  : context.copy('Continue', 'Continuer')),
        icon: isLastQuestion ? AppIcons.check : AppIcons.forward,
        loading: isLastQuestion && _saving,
        onPressed: () {
          if (!_validate()) return;
          if (isLastQuestion) {
            _finish();
          } else {
            HapticFeedback.selectionClick();
            _go(_step + 1);
          }
        },
      ),
    );
  }

  Widget _errorRow(String text) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.lg),
    child: Row(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 16,
          color: AppColors.danger,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.danger, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.lastStep,
    required this.onBack,
    required this.onSkip,
  });

  final int step;
  final int lastStep;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final progress = (step / (lastStep - 1)).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: onBack == null
                ? null
                : IconButton(
                    icon: const Icon(AppIcons.back, size: 20),
                    onPressed: onBack,
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 5,
                  backgroundColor: AppColors.fill,
                  valueColor: const AlwaysStoppedAnimation(AppColors.ink),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: onSkip == null
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      context.copy('Skip', 'Passer'),
                      style: const TextStyle(
                        color: AppColors.secondaryLabel,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// A one-line benefit shown on the intro step.
class _Benefit extends StatelessWidget {
  const _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.fill,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 18, color: AppColors.ink),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.3,
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A selectable single-choice card — same look as the reservation/verification
/// flow cards.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.separator,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.onAccent.withValues(alpha: 0.14)
                    : AppColors.fill,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? AppColors.onAccent : AppColors.ink,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                  color: selected ? AppColors.onAccent : AppColors.label,
                ),
              ),
            ),
            if (selected)
              const Icon(AppIcons.check, size: 18, color: AppColors.onAccent),
          ],
        ),
      ),
    );
  }
}

/// A compact selectable pill used for countries and regions.
class _SelectPill extends StatelessWidget {
  const _SelectPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: selected ? AppColors.ink : AppColors.separator,
            width: selected ? 1.4 : 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: selected ? AppColors.onAccent : AppColors.label,
          ),
        ),
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.secondaryLabel,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.4,
      ),
    );
  }
}
