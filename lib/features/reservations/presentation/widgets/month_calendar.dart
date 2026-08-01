import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/availability.dart';

/// A compact, monochrome month calendar. Today is outlined, the selected day
/// fills solid ink, and each day carries a small marker for what it's doing.
/// Built in-house to hold the black/white/grey identity precisely — no
/// third-party theming.
///
/// Pass [states] to get the full availability read (booked / on hold /
/// blocked), which is what the agency dashboard shows. [marked] stays for the
/// simpler screens that only care whether *something* is on that day.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selected,
    required this.marked,
    required this.onSelect,
    required this.onMonthChanged,
    this.states,
  });

  /// Any day within the month being shown (day component is ignored).
  final DateTime month;
  final DateTime? selected;
  final Set<DateTime> marked;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<DateTime> onMonthChanged;

  /// Day → what's holding it. Takes precedence over [marked] when present.
  final Map<DateTime, DayAvailability>? states;

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final year = month.year;
    final m = month.month;
    final first = DateTime(year, m, 1);
    final daysInMonth = DateTime(year, m + 1, 0).day;
    // Monday-first offset (Dart weekday: Mon=1..Sun=7).
    final leading = first.weekday - 1;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final cells = <Widget>[];
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(year, m, d);
      final isToday = day == today;
      final isSelected = selected != null &&
          DateTime(selected!.year, selected!.month, selected!.day) == day;
      // A screen that supplied `states` gets the precise read; everything else
      // keeps the old on/off dot.
      final state = states != null
          ? (states![day] ?? DayAvailability.available)
          : (marked.contains(day)
                ? DayAvailability.confirmed
                : DayAvailability.available);
      cells.add(
        _DayCell(
          day: d,
          isToday: isToday,
          isSelected: isSelected,
          state: state,
          onTap: () {
            HapticFeedback.selectionClick();
            onSelect(day);
          },
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Text(
              '${_months[m - 1]} $year',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const Spacer(),
            _NavBtn(
              icon: Icons.chevron_left_rounded,
              onTap: () => onMonthChanged(DateTime(year, m - 1, 1)),
            ),
            const SizedBox(width: AppSpacing.xs),
            _NavBtn(
              icon: Icons.chevron_right_rounded,
              onTap: () => onMonthChanged(DateTime(year, m + 1, 1)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            for (final w in _weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: const TextStyle(
                      color: AppColors.tertiaryLabel,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: cells,
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.state,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final DayAvailability state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Three distinguishable markers inside one grey scale: a solid dot for a
    // booking, a hollow ring while a request is still on hold, and a short bar
    // for dates the agency closed by hand.
    final ink = isSelected ? AppColors.onAccent : AppColors.ink;
    final soft = isSelected ? AppColors.onAccent : AppColors.tertiaryLabel;
    final taken = state != DayAvailability.available;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : Colors.transparent,
          shape: BoxShape.circle,
          border: isToday && !isSelected
              ? Border.all(color: AppColors.ink, width: 1.2)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                // A taken day steps back so the free ones read first.
                color: isSelected
                    ? AppColors.onAccent
                    : (taken ? AppColors.secondaryLabel : AppColors.label),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 4,
              child: switch (state) {
                DayAvailability.available => const SizedBox.shrink(),
                DayAvailability.confirmed => _Marker(
                  width: 4,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: ink),
                ),
                DayAvailability.pending => _Marker(
                  width: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: soft, width: 1),
                  ),
                ),
                DayAvailability.blocked => _Marker(
                  width: 9,
                  height: 2,
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({
    required this.width,
    required this.decoration,
    this.height = 4,
  });

  final double width;
  final double height;
  final Decoration decoration;

  @override
  Widget build(BuildContext context) => Center(
    child: Container(width: width, height: height, decoration: decoration),
  );
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.fill,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.ink),
      ),
    );
  }
}
