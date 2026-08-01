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

  /// Called with the reason the agency typed. It is never empty — the sheet
  /// won't submit without one, matching the dashboard.
  final void Function(String reason)? onCancel;
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

  /// "22h left" / "45m left" while the agency's 48 h window is still running.
  String? get _holdLeft {
    final left = reservation.remainingHold;
    if (left == Duration.zero) return null;
    if (left.inHours >= 1) return '${left.inHours}h left to answer';
    return '${left.inMinutes}m left to answer';
  }

  /// Asks for the reason before turning a request down. The dashboard refuses
  /// to submit without one and the traveller is shown the text, so the phone
  /// has to ask for it too — otherwise the same action means two different
  /// things depending on where the agency happens to be standing.
  Future<void> _askReason(
    BuildContext context,
    ReservationStatus status,
  ) async {
    final isCancel = status == ReservationStatus.confirmed;
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ReasonSheet(isCancel: isCancel),
    );
    if (reason == null || reason.isEmpty) return;
    onCancel?.call(reason);
    if (context.mounted) {
      AppFeedback.info(
        context,
        isCancel ? 'Reservation cancelled' : 'Request declined',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVisit = reservation.type == ReservationType.visit;
    // Read through `effectiveStatus` everywhere: a hold that lapsed minutes ago
    // is already dead, even though the row still says pending until the
    // 15-minute sweep catches up.
    final status = reservation.effectiveStatus;
    final hold = _holdLeft;
    final reason = reservation.cancellationReason;
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
                    if (reservation.reference != null) ...[
                      Text(
                        reservation.reference!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: AppColors.tertiaryLabel,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
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
              _StatusPill(status: status),
            ],
          ),

          // The 48 h clock. Shown to both sides — it's the agency's deadline
          // and the traveller's answer, so hiding it from either is unkind.
          if (hold != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 13,
                  color: AppColors.tertiaryLabel,
                ),
                const SizedBox(width: 5),
                Text(
                  hold,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tertiaryLabel,
                  ),
                ),
              ],
            ),
          ],

          // Why it fell through. The dashboard makes the agency write this, so
          // the traveller should never be left guessing.
          if (status.isRefusal && reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.fill,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status == ReservationStatus.rejected
                        ? 'Why it was declined'
                        : 'Why it was cancelled',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.tertiaryLabel,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    reason,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      color: AppColors.secondaryLabel,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (manageable && status.isActive) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (status == ReservationStatus.pending)
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
                if (status == ReservationStatus.confirmed)
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
                    label: status == ReservationStatus.confirmed
                        ? 'Cancel'
                        : 'Decline',
                    icon: AppIcons.close,
                    filled: false,
                    onTap: onCancel == null
                        ? null
                        : () => _askReason(context, status),
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

/// Bottom sheet that collects the mandatory decline/cancel reason. Kept in this
/// file because it exists only to serve the tile's Decline button.
class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet({required this.isCancel});

  final bool isCancel;

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  final _controller = TextEditingController();
  bool _touched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    setState(() => _touched = true);
    if (value.isEmpty) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final empty = _touched && _controller.text.trim().isEmpty;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.separator,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              widget.isCancel
                  ? 'Cancel this reservation'
                  : 'Decline this request',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              'The traveller sees this, so a short honest line goes a long way.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 3,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: widget.isCancel
                    ? 'The place is no longer available for these dates…'
                    : 'Already booked for these dates…',
                filled: true,
                fillColor: AppColors.fill,
                errorText: empty ? 'A reason is required.' : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Keep it'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: AppColors.onAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    child: Text(widget.isCancel ? 'Cancel stay' : 'Decline'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final ReservationStatus status;

  @override
  Widget build(BuildContext context) {
    // Confirmed is the only state that earns the solid ink pill. Everything
    // that's over — declined, expired, cancelled — settles back into the quiet
    // greys so a busy list still reads at a glance.
    final (bg, fg) = switch (status) {
      ReservationStatus.confirmed => (AppColors.ink, AppColors.onAccent),
      ReservationStatus.pending => (AppColors.accentSoft, AppColors.ink),
      ReservationStatus.completed => (AppColors.fill, AppColors.secondaryLabel),
      ReservationStatus.rejected => (AppColors.fill, AppColors.tertiaryLabel),
      ReservationStatus.expired => (AppColors.fill, AppColors.tertiaryLabel),
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
