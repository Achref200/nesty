import 'package:flutter/material.dart';

import '../../../../core/branding/app_icons.dart';
import '../../../../core/services/app_feedback.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/neu/neu_surface.dart';
import '../../domain/entities/reservation.dart';

/// A single reservation row used across Trips, the host Calendar and the
/// dashboard. When [manageable] is true it shows host controls to confirm,
/// cancel or mark a reservation complete.
class ReservationTile extends StatelessWidget {
  const ReservationTile({
    super.key,
    required this.reservation,
    this.manageable = false,
    this.onConfirm,
    this.onCancel,
    this.onComplete,
    this.showGuest = false,
  });

  final Reservation reservation;
  final bool manageable;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final VoidCallback? onComplete;
  final bool showGuest;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get _when {
    final s = reservation.start;
    final date = '${s.day} ${_months[s.month - 1]}';
    if (reservation.type == ReservationType.visit) {
      final hh = s.hour.toString().padLeft(2, '0');
      final mm = s.minute.toString().padLeft(2, '0');
      return '$date · $hh:$mm';
    }
    final e = reservation.end;
    if (e == null) return date;
    return '$date → ${e.day} ${_months[e.month - 1]} · ${reservation.nights} nights';
  }

  @override
  Widget build(BuildContext context) {
    final isVisit = reservation.type == ReservationType.visit;
    return NeuSurface(
      borderRadius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.fill,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  isVisit
                      ? Icons.event_available_rounded
                      : Icons.calendar_month_rounded,
                  size: 18,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reservation.propertyTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _when,
                      style: const TextStyle(
                        color: AppColors.secondaryLabel,
                        fontSize: 13,
                      ),
                    ),
                    if (showGuest) ...[
                      const SizedBox(height: 1),
                      Text(
                        '${reservation.guestName} · ${reservation.guests} '
                        '${reservation.guests == 1 ? 'guest' : 'guests'}',
                        style: const TextStyle(
                          color: AppColors.tertiaryLabel,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusPill(status: reservation.status),
            ],
          ),
          if (manageable && reservation.status.isActive) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (reservation.status == ReservationStatus.pending)
                  Expanded(
                    child: _Action(
                      label: 'Confirm',
                      icon: AppIcons.check,
                      filled: true,
                      onTap: onConfirm == null
                          ? null
                          : () {
                              onConfirm!();
                              AppFeedback.success(
                                context,
                                'Reservation confirmed',
                              );
                            },
                    ),
                  ),
                if (reservation.status == ReservationStatus.confirmed)
                  Expanded(
                    child: _Action(
                      label: 'Mark done',
                      icon: AppIcons.checkAll,
                      filled: true,
                      onTap: onComplete == null
                          ? null
                          : () {
                              onComplete!();
                              AppFeedback.success(
                                context,
                                'Marked as complete',
                              );
                            },
                    ),
                  ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _Action(
                    label: 'Decline',
                    icon: AppIcons.close,
                    filled: false,
                    onTap: onCancel == null
                        ? null
                        : () {
                            onCancel!();
                            AppFeedback.info(context, 'Reservation cancelled');
                          },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      ReservationStatus.confirmed => (AppColors.ink, AppColors.onAccent),
      ReservationStatus.pending => (AppColors.accentSoft, AppColors.ink),
      ReservationStatus.completed => (AppColors.fill, AppColors.secondaryLabel),
      ReservationStatus.cancelled => (AppColors.fill, AppColors.tertiaryLabel),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.ink : AppColors.fill,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: filled ? AppColors.onAccent : AppColors.label,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: filled ? AppColors.onAccent : AppColors.label,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
