import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/neu/neu_tappable.dart';

class CategoryChip {
  const CategoryChip(this.id, this.label, this.icon);
  final String id;
  final String label;
  final IconData icon;
}

const kCategories = <CategoryChip>[
  CategoryChip('all', 'All', Icons.apps_rounded),
  CategoryChip('entirePlace', 'Entire', Icons.home_rounded),
  CategoryChip('sharedRoom', 'Colocation', Icons.groups_rounded),
  CategoryChip('privateRoom', 'Private', Icons.meeting_room_rounded),
];

/// Horizontal, single-select category filter.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        itemCount: kCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final c = kCategories[index];
          final active = c.id == selected;
          return NeuTappable(
            onTap: () => onSelected(c.id),
            borderRadius: AppRadius.pill,
            depth: 5,
            color: active ? AppColors.accent : null,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  c.icon,
                  size: 17,
                  color: active ? AppColors.onAccent : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  c.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: active
                        ? AppColors.onAccent
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
