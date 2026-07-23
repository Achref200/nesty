import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/branding/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/verification_store.dart';
import '../../domain/entities/verification.dart';
import '../pages/verification_flow_page.dart';

/// The identity-verification prompt shown on the Profile. A bold call-to-action
/// the first time (Upwork-style, one-time), a calm "under review" state once
/// submitted, and a verified confirmation after approval.
class VerificationCard extends StatelessWidget {
  const VerificationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = sl<VerificationStore>();
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        switch (store.status) {
          case VerificationStatus.none:
            return _Cta(onTap: () => startVerificationFlow(context));
          case VerificationStatus.rejected:
            return _Cta(
              rejected: true,
              onTap: () => startVerificationFlow(context),
            );
          case VerificationStatus.pending:
            return const _Status(
              icon: AppIcons.clock,
              title: 'Verification under review',
              subtitle:
                  'We\u2019re checking your documents — usually within a day.',
            );
          case VerificationStatus.verified:
            return const _Status(
              icon: AppIcons.verified,
              title: 'Identity verified',
              subtitle: 'Your account carries the verified badge.',
              solid: true,
            );
        }
      },
    );
  }
}

class _Cta extends StatelessWidget {
  const _Cta({required this.onTap, this.rejected = false});
  final VoidCallback onTap;
  final bool rejected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.onAccent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(AppIcons.shield,
                  color: AppColors.onAccent, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rejected
                        ? 'Re-verify your identity'
                        : 'Verify your identity',
                    style: const TextStyle(
                        color: AppColors.onAccent,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Get your verified badge in about two minutes.',
                    style: TextStyle(
                        color: AppColors.onAccent.withValues(alpha: 0.72),
                        fontSize: 13,
                        height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(AppIcons.chevronRight,
                color: AppColors.onAccent, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.solid = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.separator, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: solid ? AppColors.ink : AppColors.fill,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon,
                color: solid ? AppColors.onAccent : AppColors.ink, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15.5)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.3,
                        color: AppColors.secondaryLabel)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
