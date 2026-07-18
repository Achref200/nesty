import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/branding/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/ios/ios_sliver_scaffold.dart';
import '../../../../core/widgets/motion/fade_slide_in.dart';
import '../../../../core/widgets/neu/neu_button.dart';
import '../../../../core/widgets/neu/neu_surface.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../listings/data/datasources/host_listings_store.dart';
import '../../../listings/presentation/pages/create_listing_page.dart';
import '../../../notifications/data/notifications_store.dart';
import '../../../reservations/data/reservations_store.dart';
import '../../../subscription/data/subscription_store.dart';
import '../../../subscription/domain/entities/subscription.dart';
import '../../../subscription/domain/entities/subscription_plan.dart';
import '../../../subscription/presentation/pages/paywall_page.dart';
import '../../../subscription/presentation/partner_gate.dart';

/// The Partner home — a light overview (not a full agency dashboard). It shows
/// the active plan and monthly usage, a couple of live counts, and a shortcut
/// to publish. Everything deeper lives in the Listings and Calendar tabs.
class PartnerHomePage extends StatelessWidget {
  const PartnerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final hostStore = sl<HostListingsStore>();
    final reservations = sl<ReservationsStore>();
    final subscription = sl<SubscriptionStore>();

    return IosSliverScaffold(
      title: 'Your space',
      trailing: const _PartnerHeaderActions(),
      onRefresh: () async {
        await Future.wait([hostStore.load(), reservations.load()]);
        await subscription.load();
      },
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.sm,
            AppSpacing.gutter,
            120,
          ),
          sliver: SliverList.list(
            children: [
              FadeSlideIn(
                child: AnimatedBuilder(
                  animation: Listenable.merge([subscription, hostStore]),
                  builder: (context, _) => _PlanCard(
                    subscription: subscription.current,
                    activeListings: hostStore.items.length,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: AnimatedBuilder(
                  animation: Listenable.merge([hostStore, reservations]),
                  builder: (context, _) => Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: AppIcons.listings,
                          value: '${hostStore.items.length}',
                          label: 'Active listings',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _StatCard(
                          icon: AppIcons.visit,
                          value: '${reservations.pendingCount}',
                          label: 'Pending requests',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const FadeSlideIn(
                delay: Duration(milliseconds: 140),
                child: _SectionLabel('Grow your network'),
              ),
              const SizedBox(height: AppSpacing.sm),
              FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: NeuSurface(
                  borderRadius: AppRadius.lg,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.fill,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: const Icon(
                              AppIcons.partner,
                              color: AppColors.ink,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              'Every home you know is a listing waiting to '
                              'happen. Publish it, share it, get requests.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      NeuButton(
                        label: 'Publish a home',
                        icon: AppIcons.add,
                        onPressed: () => _publish(context, hostStore),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _publish(BuildContext context, HostListingsStore hostStore) async {
    if (!await ensureWithinListingLimit(context)) return;
    if (!context.mounted) return;
    final published = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateListingPage()),
    );
    if (published == true) await hostStore.load();
  }
}

/// Shows the active plan, monthly listing usage and a shortcut to manage it.
class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.subscription, required this.activeListings});

  final Subscription? subscription;
  final int activeListings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = subscription?.plan ?? SubscriptionPlan.standard;
    final limit = subscription?.listingLimit ?? plan.listingLimit;
    final unlimited = limit < 0;
    final ratio = unlimited || limit == 0
        ? 0.0
        : (activeListings / limit).clamp(0.0, 1.0);

    return NeuSurface(
      borderRadius: AppRadius.lg,
      color: AppColors.accent,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(plan.icon, color: AppColors.onAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                '${plan.label} plan',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.onAccent,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PaywallPage(upgrade: true),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.onAccent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    'Manage',
                    style: TextStyle(
                      color: AppColors.onAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            unlimited
                ? '$activeListings listings · unlimited'
                : '$activeListings of $limit listings this month',
            style: const TextStyle(
              color: AppColors.onAccent,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: unlimited ? 1 : ratio,
              minHeight: 7,
              backgroundColor: AppColors.onAccent.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.onAccent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            unlimited
                ? 'Your customized plan has no listing cap.'
                : ratio >= 1
                    ? 'You\'ve reached your monthly limit — upgrade for more.'
                    : 'Room for ${(limit - activeListings).clamp(0, limit)} '
                        'more this month.',
            style: TextStyle(
              color: AppColors.onAccent.withValues(alpha: 0.75),
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NeuSurface(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.ink),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.secondaryLabel,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _PartnerHeaderActions extends StatelessWidget {
  const _PartnerHeaderActions();

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthCubit, AppUser?>((c) => c.state.user);
    final name = user?.displayName.trim() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: sl<NotificationsStore>(),
          builder: (context, _) {
            final unread = sl<NotificationsStore>().unread;
            return IconButton(
              onPressed: () => context.push(AppRoutes.notifications),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(AppIcons.bell, color: AppColors.ink, size: 22),
                  if (unread > 0)
                    Positioned(
                      right: -4,
                      top: -3,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(minWidth: 15),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                            color: AppColors.onAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: 'Notifications',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 38, height: 38),
            );
          },
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => context.push(AppRoutes.settings),
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                ? AppImage(user.avatarUrl!, fit: BoxFit.cover)
                : Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.onAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
