import 'package:flutter/material.dart';

import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/neu/neu_surface.dart';

/// Explains the current verification status without inferring it from listing data.
class TrustSection extends StatelessWidget {
  const TrustSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NeuSurface(
      borderRadius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 22,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.copy(
                    'Listing verification',
                    'Vérification de l’annonce',
                  ),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.copy(
                    'Nesty has not independently verified this listing. Confirm details directly with the agency before booking.',
                    'Nesty n’a pas vérifié cette annonce de manière indépendante. Confirmez les informations directement auprès de l’agence avant de réserver.',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
