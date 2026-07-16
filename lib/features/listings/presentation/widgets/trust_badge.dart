import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/trust_info.dart';

/// A compact trust pill for the feed card: a shield with the trust score. Hidden
/// for basic (unverified) listings so the feed stays calm and the badge stays
/// meaningful.
class TrustBadge extends StatelessWidget {
  const TrustBadge({super.key, required this.trust});

  final TrustInfo trust;

  @override
  Widget build(BuildContext context) {
    if (!trust.isVerified) return const SizedBox.shrink();
    final premium = trust.level == TrustLevel.premium;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: premium ? AppColors.accent : AppColors.fill,
        borderRadius: BorderRadius.circular(999),
        border: premium
            ? null
            : Border.all(color: AppColors.separator, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user_rounded,
            size: 13,
            color: premium ? AppColors.onAccent : AppColors.label,
          ),
          const SizedBox(width: 4),
          Text(
            '${trust.score}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: premium ? AppColors.onAccent : AppColors.label,
            ),
          ),
        ],
      ),
    );
  }
}
