import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/neu/neu_surface.dart';
import '../../domain/entities/trust_info.dart';

/// The "Verified by Nestly" panel on the listing details page. Makes trust
/// transparent: an overall score, the trust level, and the exact checks that
/// were passed — directly addressing authenticity concerns in the market.
class TrustSection extends StatelessWidget {
  const TrustSection({super.key, required this.trust});

  final TrustInfo trust;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NeuSurface(
      borderRadius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                size: 22,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verified by Nesty',
                      style: theme.textTheme.titleMedium,
                    ),
                    Text(trust.level.label, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              Text('${trust.score}', style: theme.textTheme.titleLarge),
              const Padding(
                padding: EdgeInsets.only(top: 4, left: 1),
                child: Text(
                  '/100',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _ScoreBar(score: trust.score),
          const SizedBox(height: AppSpacing.lg),
          _Check(
            passed: trust.identityVerified,
            label: 'Owner identity verified',
          ),
          _Check(
            passed: trust.ownershipVerified,
            label: 'Proof of ownership / mandate',
          ),
          _Check(passed: trust.locationVerified, label: 'Location confirmed'),
          _Check(passed: trust.videoVerified, label: 'Video walkthrough'),
          _Check(passed: trust.tourComplete, label: 'Full 3D room tour'),
          _Check(
            passed: trust.wellReviewed,
            label: 'Consistently well reviewed',
            last: true,
          ),
        ],
      ),
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.score});
  final int score;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        children: [
          Container(height: 6, color: AppColors.fill),
          FractionallySizedBox(
            widthFactor: (score / 100).clamp(0.0, 1.0),
            child: Container(height: 6, color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.passed, required this.label, this.last = false});

  final bool passed;
  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.md),
      child: Row(
        children: [
          Icon(
            passed
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 19,
            color: passed ? AppColors.accent : AppColors.tertiaryLabel,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: passed ? AppColors.label : AppColors.secondaryLabel,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
