import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ios/ios_sliver_scaffold.dart';
import '../../../../core/widgets/motion/fade_slide_in.dart';
import '../../../../core/widgets/neu/neu_surface.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../data/reservations_store.dart';
import '../../domain/entities/reservation.dart';
import '../widgets/reservation_tile.dart';

/// The seeker's "Trips" tab: every visit and stay they've requested, split into
/// upcoming and past, reading straight from [ReservationsStore] so it stays in
/// sync the moment a request is made or a host confirms it.
class MyTripsPage extends StatelessWidget {
  const MyTripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = sl<ReservationsStore>();
    final guestId = context.select<AuthCubit, String>(
      (c) => c.state.user?.id ?? 'guest',
    );

    return IosSliverScaffold(
      title: 'Trips',
      slivers: [
        SliverToBoxAdapter(
          child: ListenableBuilder(
            listenable: store,
            builder: (context, _) {
              final mine = store.forGuest(guestId);
              final upcoming =
                  mine.where((r) => r.status.isActive && r.isUpcoming).toList();
              final past = mine
                  .where((r) => !(r.status.isActive && r.isUpcoming))
                  .toList()
                ..sort((a, b) => b.start.compareTo(a.start));

              if (mine.isEmpty) {
                return const _EmptyTrips();
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  AppSpacing.sm,
                  AppSpacing.gutter,
                  140,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (upcoming.isNotEmpty) ...[
                      const _SectionLabel('Upcoming'),
                      const SizedBox(height: AppSpacing.md),
                      ...upcoming.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: ReservationTile(
                            reservation: r,
                            manageable: true,
                            onCancel: () => store.setStatus(
                              r.id,
                              ReservationStatus.cancelled,
                            ),
                            // Seekers only cancel; hosts confirm/complete.
                            onConfirm: null,
                            onComplete: null,
                          ),
                        ),
                      ),
                    ],
                    if (past.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      const _SectionLabel('History'),
                      const SizedBox(height: AppSpacing.md),
                      ...past.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: ReservationTile(reservation: r),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
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

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        80,
        AppSpacing.gutter,
        140,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeSlideIn(
              child: NeuSurface(
                borderRadius: 32,
                depth: 10,
                padding: const EdgeInsets.all(28),
                child: const Icon(
                  Icons.luggage_outlined,
                  size: 40,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FadeSlideIn(
              delay: const Duration(milliseconds: 90),
              child: Text('No trips yet', style: theme.textTheme.titleMedium),
            ),
            const SizedBox(height: AppSpacing.sm),
            FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: Text(
                'Book a visit or reserve your summer dates on any home — '
                'they\'ll appear here to track.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
