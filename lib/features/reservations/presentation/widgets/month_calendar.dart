import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// A compact, monochrome month calendar. Marked days carry a small ink dot,
/// today is outlined, and the selected day fills solid ink. Built in-house to
/// hold the black/white/grey identity precisely — no third-party theming.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selected,
    required this.marked,
    required this.onSelect,
    required this.onMonthChanged,
  });

  /// Any day within the month being shown (day component is ignored).
  final DateTime month;
  final DateTime? selected;
  final Set<DateTime> marked;
  final ValueChanged<DateTime> onSelect;
  final ValueChanged<DateTime> onMonthChanged;

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
      final isMarked = marked.contains(day);
      cells.add(
        _DayCell(
          day: d,
          isToday: isToday,
          isSelected: isSelected,
          isMarked: isMarked,
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
    required this.isMarked,
    required this.onTap,
  });

  final int day;
  final bool isToday;
  final bool isSelected;
  final bool isMarked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
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
                color: isSelected ? AppColors.onAccent : AppColors.label,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isMarked
                    ? (isSelected ? AppColors.onAccent : AppColors.ink)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
