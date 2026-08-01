import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ios/ios_sliver_scaffold.dart';
import '../../../../core/widgets/motion/fade_slide_in.dart';
import '../../../../core/widgets/motion/nesty_loader.dart';
import '../../../../core/widgets/neu/neu_surface.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../reservations/data/reservations_store.dart';
import '../../../reservations/domain/entities/reservation.dart';
import '../../../reservations/presentation/widgets/reservation_tile.dart';

/// Host-only home. A professional analytics dashboard that surfaces how seekers
/// interact with a host's listings — views, saves, tour dwell time, per-room
/// attention and listing performance — the kind of insight traditional
/// marketplaces rarely give owners. Figures here are illustrative demo data.
class HostDashboardPage extends StatelessWidget {
  const HostDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthCubit, String>(
      (c) => c.state.user?.displayName ?? 'host',
    );

    return IosSliverScaffold(
      title: context.copy('Dashboard', 'Tableau de bord'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.sm,
            AppSpacing.gutter,
            140,
          ),
          sliver: SliverList.list(
            children: [
              FadeSlideIn(
                child: Text(
                  context.copy('Welcome back, $name.', 'Bon retour, $name.'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const FadeSlideIn(
                delay: Duration(milliseconds: 40),
                child: _ReservationsOverview(),
              ),
              const SizedBox(height: AppSpacing.xl),
              const FadeSlideIn(
                delay: Duration(milliseconds: 80),
                child: _EngagementSection(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A live overview of reservations pulled from [ReservationsStore]: pending
/// requests, upcoming visits & stays, and inline controls to confirm, decline
/// or complete the next few — the operational core of the agency dashboard.
class _ReservationsOverview extends StatelessWidget {
  const _ReservationsOverview();

  @override
  Widget build(BuildContext context) {
    final store = sl<ReservationsStore>();
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final upcoming = store.upcoming;
        final pending = store.pendingCount;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _CountCard(
                    icon: Icons.mark_email_unread_outlined,
                    value: '$pending',
                    label: context.copy(
                      'Pending requests',
                      'Demandes en attente',
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _CountCard(
                    icon: Icons.event_available_outlined,
                    value: '${upcoming.length}',
                    label: context.copy('Upcoming', 'À venir'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            _SectionLabel(context.copy('Next up', 'À suivre')),
            const SizedBox(height: AppSpacing.md),
            if (upcoming.isEmpty)
              NeuSurface(
                borderRadius: AppRadius.md,
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_note_outlined,
                      color: AppColors.tertiaryLabel,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        context.copy(
                          'No requests yet. When seekers book a visit or reserve '
                          'dates, they land here.',
                          'Aucune demande pour le moment. Les visites et '
                          'réservations des chercheurs apparaîtront ici.',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...upcoming.take(4).map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ReservationTile(
                    reservation: r,
                    manageable: true,
                    showGuest: true,
                    onConfirm: () =>
                        store.setStatus(r.id, ReservationStatus.confirmed),
                    // A pending request is declined, a confirmed one is
                    // cancelled — same two outcomes the dashboard offers.
                    onCancel: (reason) => store.setStatus(
                      r.id,
                      r.effectiveStatus == ReservationStatus.confirmed
                          ? ReservationStatus.cancelled
                          : ReservationStatus.rejected,
                      reason: reason,
                    ),
                    onComplete: () =>
                        store.setStatus(r.id, ReservationStatus.completed),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CountCard extends StatelessWidget {
  const _CountCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return NeuSurface(
      borderRadius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.ink),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
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

class _ListingPerformanceCard extends StatelessWidget {
  const _ListingPerformanceCard({
    required this.title,
    required this.views,
    required this.saves,
    required this.score,
  });

  final String title;
  final int views;
  final int saves;
  final double score;

  @override
  Widget build(BuildContext context) {
    return NeuSurface(
      borderRadius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              _ScorePill(score: score),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _MiniStat(
                icon: Icons.visibility_outlined,
                value: '$views',
                label: context.copy('views', 'vues'),
              ),
              const SizedBox(width: AppSpacing.xl),
              _MiniStat(
                icon: Icons.favorite_border_rounded,
                value: '$saves',
                label: context.copy('saves', 'favoris'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.score});
  final double score;

  @override
  Widget build(BuildContext context) {
    final strong = score >= 0.7;
    final color = strong ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '${(score * 100).round()} / 100',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}

/// Real engagement pulled from Supabase — total views/saves/tour-requests, the
/// number of listings, and per-listing performance. No mock data.
class _EngagementSection extends StatefulWidget {
  const _EngagementSection();

  @override
  State<_EngagementSection> createState() => _EngagementSectionState();
}

class _EngagementSectionState extends State<_EngagementSection> {
  bool _loading = true;
  _HostStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!SupabaseService.isReady) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final client = SupabaseService.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final listingsRes =
          await client.from('listings').select('id, title').eq('host_id', uid);
      final eventsRes = await client
          .from('listing_events')
          .select('listing_id, type')
          .eq('host_id', uid);

      final titles = <String, String>{};
      for (final row in (listingsRes as List)) {
        final m = row as Map<String, dynamic>;
        titles[m['id'].toString()] = (m['title'] as String?) ?? 'Listing';
      }
      final perView = <String, int>{};
      final perSave = <String, int>{};
      var views = 0, saves = 0, tours = 0;
      for (final row in (eventsRes as List)) {
        final m = row as Map<String, dynamic>;
        final id = m['listing_id'].toString();
        switch (m['type'] as String?) {
          case 'view':
            views++;
            perView[id] = (perView[id] ?? 0) + 1;
          case 'save':
            saves++;
            perSave[id] = (perSave[id] ?? 0) + 1;
          case 'tour':
            tours++;
        }
      }
      final maxViews = perView.values.isEmpty
          ? 0
          : perView.values.reduce((a, b) => a > b ? a : b);
      final top =
          titles.entries
              .map(
                (e) => _ListingStat(
                  title: e.value,
                  views: perView[e.key] ?? 0,
                  saves: perSave[e.key] ?? 0,
                  score: maxViews == 0 ? 0.0 : (perView[e.key] ?? 0) / maxViews,
                ),
              )
              .toList()
            ..sort((a, b) => b.views.compareTo(a.views));

      if (!mounted) return;
      setState(() {
        _loading = false;
        _stats = _HostStats(
          views: views,
          saves: saves,
          tours: tours,
          listings: titles.length,
          top: top.take(4).toList(),
        );
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: NestyLoader(size: 56)),
      );
    }
    final s = _stats;
    if (s == null) {
      return NeuSurface(
        borderRadius: AppRadius.md,
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          context.copy(
            'Engagement insights appear here once seekers start exploring your '
            'listings.',
            'Les indicateurs apparaîtront ici dès que les chercheurs '
            'exploreront vos annonces.',
          ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(context.copy('Engagement', 'Engagement')),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _CountCard(
                icon: Icons.visibility_outlined,
                value: '${s.views}',
                label: context.copy('Views', 'Vues'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _CountCard(
                icon: Icons.favorite_border_rounded,
                value: '${s.saves}',
                label: context.copy('Saves', 'Favoris'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _CountCard(
                icon: Icons.event_available_outlined,
                value: '${s.tours}',
                label: context.copy('Tour requests', 'Demandes de visite'),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _CountCard(
                icon: Icons.home_work_outlined,
                value: '${s.listings}',
                label: context.copy('Listings', 'Annonces'),
              ),
            ),
          ],
        ),
        if (s.top.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const _SectionLabel('Listing performance'),
          const SizedBox(height: AppSpacing.md),
          for (final l in s.top) ...[
            _ListingPerformanceCard(
              title: l.title,
              views: l.views,
              saves: l.saves,
              score: l.score,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ],
    );
  }
}

class _HostStats {
  const _HostStats({
    required this.views,
    required this.saves,
    required this.tours,
    required this.listings,
    required this.top,
  });

  final int views;
  final int saves;
  final int tours;
  final int listings;
  final List<_ListingStat> top;
}

class _ListingStat {
  const _ListingStat({
    required this.title,
    required this.views,
    required this.saves,
    required this.score,
  });

  final String title;
  final int views;
  final int saves;
  final double score;
}
