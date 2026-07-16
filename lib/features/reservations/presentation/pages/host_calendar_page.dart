import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ios/ios_sliver_scaffold.dart';
import '../../../../core/widgets/motion/fade_slide_in.dart';
import '../../../../core/widgets/neu/neu_surface.dart';
import '../../data/reservations_store.dart';
import '../../domain/entities/reservation.dart';
import '../widgets/month_calendar.dart';
import '../widgets/reservation_tile.dart';

/// Host-only calendar. A month grid marks every day that carries a visit or a
/// stay; tapping a day reveals what's booked and lets the host confirm, decline
/// or complete each request. This is the operational heart of the agency view.
class HostCalendarPage extends StatefulWidget {
  const HostCalendarPage({super.key});

  @override
  State<HostCalendarPage> createState() => _HostCalendarPageState();
}

class _HostCalendarPageState extends State<HostCalendarPage> {
  late DateTime _month;
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
    _selected = DateTime(now.year, now.month, now.day);
  }

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final store = sl<ReservationsStore>();
    return IosSliverScaffold(
      title: 'Calendar',
      slivers: [
        SliverToBoxAdapter(
          child: ListenableBuilder(
            listenable: store,
            builder: (context, _) {
              final marked = store.markedDays(_month.year, _month.month);
              final dayItems = store.onDay(_selected);
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
                    FadeSlideIn(
                      child: NeuSurface(
                        borderRadius: AppRadius.lg,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: MonthCalendar(
                          month: _month,
                          selected: _selected,
                          marked: marked,
                          onSelect: (d) => setState(() => _selected = d),
                          onMonthChanged: (m) => setState(() => _month = m),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        Text(
                          '${_selected.day} ${_months[_selected.month - 1]}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        if (dayItems.any(
                          (r) => r.status == ReservationStatus.confirmed,
                        ))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: const Text(
                              'Unavailable · reserved',
                              style: TextStyle(
                                color: AppColors.onAccent,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (dayItems.isEmpty)
                      _EmptyDay()
                    else
                      ...dayItems.map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: ReservationTile(
                            reservation: r,
                            manageable: true,
                            showGuest: true,
                            onConfirm: () => store.setStatus(
                              r.id,
                              ReservationStatus.confirmed,
                            ),
                            onCancel: () => store.setStatus(
                              r.id,
                              ReservationStatus.cancelled,
                            ),
                            onComplete: () => store.setStatus(
                              r.id,
                              ReservationStatus.completed,
                            ),
                          ),
                        ),
                      ),
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

class _EmptyDay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NeuSurface(
      borderRadius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: [
          const Icon(
            Icons.event_busy_rounded,
            color: AppColors.tertiaryLabel,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Nothing booked on this day.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
