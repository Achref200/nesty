import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/branding/app_icons.dart';
import '../../../../core/format/money.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/motion/page_transitions.dart';
import '../../../../core/widgets/motion/typing_text.dart';
import '../../../../core/widgets/neu/neu_button.dart';
import '../../../../core/widgets/neu/neu_field.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../listings/domain/entities/property.dart';
import '../../data/reservations_store.dart';
import '../../domain/entities/reservation.dart';

/// Starts the full reservation process for a listing and resolves to true if a
/// request was created. A calm, paged flow: pick a purpose, choose when, add
/// details, review, and land on a warm confirmation.
Future<bool> startReservationFlow(
  BuildContext context,
  Property property,
) async {
  final result = await Navigator.of(context).push<bool>(
    softPageRoute(_ReservationFlow(property: property), fullscreenDialog: true),
  );
  return result ?? false;
}

class _ReservationFlow extends StatefulWidget {
  const _ReservationFlow({required this.property});
  final Property property;

  @override
  State<_ReservationFlow> createState() => _ReservationFlowState();
}

class _ReservationFlowState extends State<_ReservationFlow> {
  static const _lastStep = 4; // 0 type · 1 when · 2 details · 3 review · 4 done

  int _step = 0;
  bool _forward = true;
  ReservationType _type = ReservationType.visit;
  DateTime? _visitDay;
  String _slot = '11:00';
  DateTimeRange? _range;
  int _guests = 1;
  final _note = TextEditingController();
  String? _error;
  bool _submitting = false;

  static const _slots = ['09:00', '11:00', '14:00', '16:00', '18:00'];

  double get _nightly => widget.property.pricePerMonth / 30;
  int get _nights => _range == null ? 0 : _range!.duration.inDays;
  double get _total => _nights * _nightly;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _go(int next) {
    setState(() {
      _forward = next > _step;
      _error = null;
      _step = next;
    });
  }

  bool _validateWhen() {
    if (_type == ReservationType.visit && _visitDay == null) {
      setState(() => _error = 'Pick a day for your visit.');
      return false;
    }
    if (_type == ReservationType.stay && _range == null) {
      setState(() => _error = 'Pick your check-in and check-out.');
      return false;
    }
    return true;
  }

  Future<void> _pickVisitDay() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _visitDay ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _visitDay = picked);
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _range = picked);
  }

  void _confirm() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final user = context.read<AuthCubit>().state.user;
    late DateTime start;
    DateTime? end;
    if (_type == ReservationType.visit) {
      final parts = _slot.split(':');
      start = DateTime(
        _visitDay!.year,
        _visitDay!.month,
        _visitDay!.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } else {
      start = _range!.start;
      end = _range!.end;
    }

    final error = await sl<ReservationsStore>().add(
      Reservation(
        id: 'res-${DateTime.now().millisecondsSinceEpoch}',
        propertyId: widget.property.id,
        propertyTitle: widget.property.title,
        propertyCity: widget.property.city,
        guestId: user?.id ?? 'guest',
        guestName: user?.displayName ?? 'Guest',
        type: _type,
        start: start,
        end: end,
        guests: _guests,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        estimatedTotal: _type == ReservationType.stay ? _total : null,
        createdAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    if (error != null) {
      HapticFeedback.mediumImpact();
      setState(() {
        _submitting = false;
        _error = error;
      });
      return;
    }
    Analytics.reservation(widget.property.id);
    HapticFeedback.mediumImpact();
    setState(() => _submitting = false);
    _go(_lastStep);
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
              onBack: _step == 0
                  ? () => Navigator.of(context).pop(false)
                  : (onDone ? null : () => _go(_step - 1)),
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
    0 => _typeStep(),
    1 => _whenStep(),
    2 => _detailsStep(),
    3 => _reviewStep(),
    _ => _doneStep(),
  };

  // ---- Step 0: purpose ----
  Widget _typeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.copy('What would you like to do?', 'Que souhaitez-vous faire ?'),
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xs),
        Text(widget.property.title,
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.xl),
        _TypeCard(
          icon: AppIcons.visit,
          title: context.copy('Book a visit', 'Réserver une visite'),
          subtitle: context.copy(
            'Schedule a viewing with the agency on a day that suits you.',
            'Planifiez une visite avec l\'agence au jour qui vous convient.',
          ),
          selected: _type == ReservationType.visit,
          onTap: () => setState(() => _type = ReservationType.visit),
        ),
        const SizedBox(height: AppSpacing.md),
        _TypeCard(
          icon: AppIcons.stay,
          title: context.copy('Reserve dates', 'Réserver des dates'),
          subtitle: context.copy(
            'Hold your summer dates with a check-in and check-out.',
            'Bloquez vos dates avec une arrivée et un départ.',
          ),
          selected: _type == ReservationType.stay,
          onTap: () => setState(() => _type = ReservationType.stay),
        ),
      ],
    );
  }

  // ---- Step 1: when ----
  Widget _whenStep() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _type == ReservationType.visit
              ? context.copy('When suits you?', 'Quand vous convient ?')
              : context.copy('Which dates?', 'Quelles dates ?'),
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_type == ReservationType.visit) ...[
          _PickerRow(
            icon: AppIcons.calendar,
            label: _visitDay == null
                ? context.copy('Choose a day', 'Choisir un jour')
                : _formatDate(_visitDay!),
            onTap: _pickVisitDay,
          ),
          const SizedBox(height: AppSpacing.lg),
          _MiniLabel(context.copy('Preferred time', 'Heure préférée')),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final s in _slots)
                _Chip(
                  label: s,
                  selected: _slot == s,
                  onTap: () => setState(() => _slot = s),
                ),
            ],
          ),
        ] else ...[
          _PickerRow(
            icon: AppIcons.stay,
            label: _range == null
                ? context.copy('Choose your dates', 'Choisir vos dates')
                : '${_formatDate(_range!.start)} → ${_formatDate(_range!.end)}',
            onTap: _pickRange,
          ),
          if (_range != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _TotalRow(nights: _nights, nightly: _nightly, total: _total),
          ],
        ],
        if (_error != null) _errorRow(_error!),
      ],
    );
  }

  // ---- Step 2: details ----
  Widget _detailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.copy('A few details', 'Quelques détails'),
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xl),
        _GuestsStepper(
          value: _guests,
          onChanged: (v) => setState(() => _guests = v),
        ),
        const SizedBox(height: AppSpacing.lg),
        _MiniLabel(context.copy(
          'Note for the agency (optional)',
          'Note pour l\'agence (facultatif)',
        )),
        const SizedBox(height: AppSpacing.sm),
        NeuField(
          controller: _note,
          placeholder: context.copy(
            'Anything they should know…',
            'Ce qu\'ils devraient savoir…',
          ),
          icon: AppIcons.send,
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
        ),
      ],
    );
  }

  // ---- Step 3: review ----
  Widget _reviewStep() {
    final theme = Theme.of(context);
    final when = _type == ReservationType.visit
        ? '${_formatDate(_visitDay!)} · $_slot'
        : '${_formatDate(_range!.start)} → ${_formatDate(_range!.end)} · $_nights ${context.copy('nights', 'nuits')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.copy('Review your request', 'Vérifiez votre demande'),
            style: theme.textTheme.headlineMedium),
        const SizedBox(height: AppSpacing.xl),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.separator, width: 0.5),
          ),
          child: Column(
            children: [
              _ReviewRow(
                icon: AppIcons.location,
                label: context.copy('Home', 'Logement'),
                value: widget.property.title,
              ),
              _ReviewRow(
                icon: _type == ReservationType.visit
                    ? AppIcons.visit
                    : AppIcons.stay,
                label: _type == ReservationType.visit
                    ? context.copy('Visit', 'Visite')
                    : context.copy('Stay', 'Séjour'),
                value: when,
              ),
              _ReviewRow(
                icon: AppIcons.guests,
                label: context.copy('Guests', 'Voyageurs'),
                value: '$_guests',
              ),
              if (_type == ReservationType.stay)
                _ReviewRow(
                  icon: AppIcons.star,
                  label: context.copy('Estimated total', 'Total estimé'),
                  value: formatDinars(_total),
                  last: true,
                )
              else
                _ReviewRow(
                  icon: AppIcons.clock,
                  label: context.copy('Duration', 'Durée'),
                  value: context.copy('~45 min viewing', 'visite ~45 min'),
                  last: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          context.copy(
            'The agency reviews and confirms your request. You\'ll track its '
                'status in Trips.',
            'L\'agence examine et confirme votre demande. Suivez son statut '
                'dans Voyages.',
          ),
          style: theme.textTheme.bodyMedium,
        ),
        if (_error != null) _errorRow(_error!),
      ],
    );
  }

  // ---- Step 4: confirmed ----
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
              child: const Icon(AppIcons.check,
                  color: AppColors.onAccent, size: 40),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          TypingText(
            _type == ReservationType.visit
                ? context.copy('Your visit is requested.', 'Votre visite est demandée.')
                : context.copy('Your dates are on hold.', 'Vos dates sont réservées.'),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
            startDelay: const Duration(milliseconds: 260),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.copy(
              'We\'ve sent it to the agency. Track the status any time in Trips.',
              'Nous l\'avons envoyée à l\'agence. Suivez le statut dans Voyages.',
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xxl),
          NeuButton(
            label: context.copy('View my trips', 'Voir mes voyages'),
            icon: AppIcons.trips,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    final isReview = _step == 3;
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
        label: isReview
            ? context.copy('Confirm request', 'Confirmer la demande')
            : context.copy('Continue', 'Continuer'),
        icon: isReview ? AppIcons.check : AppIcons.forward,
        loading: isReview && _submitting,
        onPressed: () {
          if (_step == 1 && !_validateWhen()) {
            HapticFeedback.mediumImpact();
            return;
          }
          if (isReview) {
            _confirm();
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
        const Icon(Icons.error_outline_rounded,
            size: 16, color: AppColors.danger),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: AppColors.danger, fontSize: 13)),
        ),
      ],
    ),
  );

  static String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.step,
    required this.lastStep,
    required this.onBack,
  });

  final int step;
  final int lastStep;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final progress = (step / (lastStep - 1)).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.gutter,
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
          const SizedBox(width: AppSpacing.md),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
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
              child: Icon(icon,
                  size: 20,
                  color: selected ? AppColors.onAccent : AppColors.ink),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: selected ? AppColors.onAccent : AppColors.label,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.3,
                      color: selected
                          ? AppColors.onAccent.withValues(alpha: 0.7)
                          : AppColors.secondaryLabel,
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

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.fill,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.ink),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            const Icon(AppIcons.chevronRight,
                color: AppColors.tertiaryLabel, size: 18),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
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
        duration: const Duration(milliseconds: 160),
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.fill,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.onAccent : AppColors.label,
          ),
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.nights,
    required this.nightly,
    required this.total,
  });
  final int nights;
  final double nightly;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                '${formatDinars(nightly)} × $nights ${nights == 1 ? context.copy('night', 'nuit') : context.copy('nights', 'nuits')}',
                style: const TextStyle(
                    color: AppColors.secondaryLabel, fontSize: 13),
              ),
              const Spacer(),
              Text(formatDinars(total),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
          const Divider(height: AppSpacing.lg),
          Row(
            children: [
              Text(context.copy('Estimated total', 'Total estimé'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text(formatDinars(total),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuestsStepper extends StatelessWidget {
  const _GuestsStepper({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(context.copy('Guests', 'Voyageurs'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          _RoundBtn(
              icon: AppIcons.minus,
              onTap: value > 1 ? () => onChanged(value - 1) : null),
          SizedBox(
            width: 40,
            child: Text('$value',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          _RoundBtn(
              icon: AppIcons.add,
              onTap: value < 16 ? () => onChanged(value + 1) : null),
        ],
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  const _RoundBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.separator, width: 0.5),
        ),
        child: Icon(icon,
            size: 16,
            color: enabled ? AppColors.ink : AppColors.tertiaryLabel),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.secondaryLabel),
          const SizedBox(width: AppSpacing.md),
          Text(label,
              style: const TextStyle(
                  color: AppColors.secondaryLabel, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ],
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
        letterSpacing: 0.3,
      ),
    );
  }
}
