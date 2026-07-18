import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/branding/app_icons.dart';
import '../../../../core/format/money.dart';
import '../../../../core/services/app_feedback.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/motion/fade_slide_in.dart';
import '../../../../core/widgets/motion/typing_text.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/subscription_store.dart';
import '../../domain/entities/subscription_plan.dart';

/// Dark canvas + light ink, deliberately inverted from the rest of the app so
/// upgrading to Partner reads as a distinct, premium moment.
const Color _bg = AppColors.ink;
const Color _fg = AppColors.white;

/// The Partner paywall — pick a tier and a billing cycle behind an online
/// subscription. Two entry points:
///
/// * **Onboarding** ([upgrade] = false): an unauthenticated seeker chose the
///   Partner role. Confirming stashes the plan and continues to sign-up, where
///   it's committed once the session lands.
/// * **Upgrade** ([upgrade] = true): a signed-in seeker becomes a Partner.
///   Confirming subscribes and switches their role in place.
///
/// Pushed with [Navigator] (not the router) so it works before authentication,
/// when the router would otherwise redirect back to onboarding.
class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key, this.upgrade = false});

  final bool upgrade;

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  SubscriptionPlan _plan = SubscriptionPlan.premium;
  BillingCycle _billing = BillingCycle.monthly;
  bool _busy = false;

  void _selectPlan(SubscriptionPlan p) {
    if (p == _plan) return;
    HapticFeedback.selectionClick();
    setState(() => _plan = p);
  }

  void _setBilling(BillingCycle c) {
    if (c == _billing) return;
    HapticFeedback.selectionClick();
    setState(() => _billing = c);
  }

  Future<void> _confirm() async {
    HapticFeedback.mediumImpact();
    final store = sl<SubscriptionStore>();

    if (!widget.upgrade) {
      // Pre-sign-up: remember the choice and let onboarding continue to auth.
      store.setPending(_plan, _billing);
      Navigator.of(context).pop(true);
      return;
    }

    // Signed-in upgrade: subscribe, then flip the role in place.
    setState(() => _busy = true);
    final authCubit = context.read<AuthCubit>();
    final error = await store.subscribe(_plan, _billing);
    final roleError = error == null
        ? await authCubit.switchRole(UserRole.partner)
        : null;
    if (!mounted) return;
    setState(() => _busy = false);
    final failure = error ?? roleError;
    if (failure != null) {
      AppFeedback.error(context, failure);
      return;
    }
    Navigator.of(context).pop(true);
    AppFeedback.success(context, 'Welcome to Nesty Partner 🎉');
  }

  @override
  Widget build(BuildContext context) {
    final price = _plan.priceFor(_billing);
    final isCustom = _plan == SubscriptionPlan.customized;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    AppSpacing.md,
                    AppSpacing.gutter,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _CloseButton(
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      FadeSlideIn(
                        child: Row(
                          children: [
                            const Icon(
                              AppIcons.subscription,
                              color: _fg,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'NESTY PARTNER',
                              style: TextStyle(
                                color: _fg.withValues(alpha: 0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Animated headline — the one moment of motion.
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 60),
                        child: TypingText(
                          'Grow on your terms.',
                          style: const TextStyle(
                            color: _fg,
                            fontSize: 34,
                            height: 1.05,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                          startDelay: const Duration(milliseconds: 220),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: Text(
                          'List homes from your network, manage requests, and '
                          'earn. Pick a plan.',
                          style: TextStyle(
                            color: _fg.withValues(alpha: 0.6),
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 140),
                        child: _BillingToggle(
                          billing: _billing,
                          onChanged: _setBilling,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      for (int i = 0;
                          i < SubscriptionPlan.values.length;
                          i++) ...[
                        FadeSlideIn(
                          delay: Duration(milliseconds: 180 + 60 * i),
                          child: _PlanRow(
                            plan: SubscriptionPlan.values[i],
                            billing: _billing,
                            selected: _plan == SubscriptionPlan.values[i],
                            onTap: () =>
                                _selectPlan(SubscriptionPlan.values[i]),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      // The selected plan's perks, animated on change.
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: SizeTransition(sizeFactor: a, child: child),
                        ),
                        child: _Perks(key: ValueKey(_plan), plan: _plan),
                      ),
                    ],
                  ),
                ),
              ),
              _Footer(
                label: isCustom
                    ? 'Request access'
                    : widget.upgrade
                        ? 'Subscribe'
                        : 'Continue',
                priceLine: isCustom
                    ? 'Custom pricing · we\'ll set you up'
                    : '${formatDinars(price!.toDouble())} / '
                        '${_billing == BillingCycle.monthly ? 'month' : 'year'} '
                        '· cancel anytime',
                busy: _busy,
                onTap: _confirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A minimal round close button that reads on the dark canvas.
class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _fg.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(AppIcons.close, color: _fg, size: 20),
      ),
    );
  }
}

class _BillingToggle extends StatelessWidget {
  const _BillingToggle({required this.billing, required this.onChanged});

  final BillingCycle billing;
  final ValueChanged<BillingCycle> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _fg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          for (final c in BillingCycle.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(c),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: billing == c ? _fg : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        c.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: billing == c
                              ? _bg
                              : _fg.withValues(alpha: 0.6),
                        ),
                      ),
                      if (c == BillingCycle.yearly) ...[
                        const SizedBox(width: 6),
                        Text(
                          '· 2 mo free',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: billing == c
                                ? _bg.withValues(alpha: 0.55)
                                : _fg.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A single, compact selectable plan row — name, one price, a check when
/// chosen. Details live in the animated perks panel below, keeping this clean.
class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.plan,
    required this.billing,
    required this.selected,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final BillingCycle billing;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = plan.priceFor(billing);
    final primary = selected ? _bg : _fg;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected ? _fg : _fg.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected ? _fg : _fg.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(plan.icon, size: 20, color: primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      plan.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                  if (plan.isMostPopular) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? _bg.withValues(alpha: 0.1)
                            : _fg.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'POPULAR',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _PriceLabel(price: price, billing: billing, primary: primary),
          ],
        ),
      ),
    );
  }
}

class _PriceLabel extends StatelessWidget {
  const _PriceLabel({
    required this.price,
    required this.billing,
    required this.primary,
  });

  final int? price;
  final BillingCycle billing;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    if (price == null) {
      return Text(
        'Let\'s talk',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: primary,
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          '$price DT',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: primary,
          ),
        ),
        Text(
          billing == BillingCycle.monthly ? '/mo' : '/yr',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: primary.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// The chosen plan's perks — a quiet, animated list under the rows.
class _Perks extends StatelessWidget {
  const _Perks({super.key, required this.plan});
  final SubscriptionPlan plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _fg.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final perk in plan.perks)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(AppIcons.check, size: 16, color: _fg),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      perk,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.3,
                        color: _fg.withValues(alpha: 0.85),
                      ),
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

class _Footer extends StatelessWidget {
  const _Footer({
    required this.label,
    required this.priceLine,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final String priceLine;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.md,
        AppSpacing.gutter,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _fg.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            priceLine,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: _fg.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: busy ? null : onTap,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: busy ? 0.7 : 1,
              child: Container(
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _fg,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: _bg,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _bg,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(AppIcons.forward, size: 18, color: _bg),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
