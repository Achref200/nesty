import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/branding/app_icons.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/neu/neu_button.dart';
import '../../domain/entities/account_standing.dart';
import '../cubit/auth_cubit.dart';

/// Full-screen surface shown when the signed-in account can no longer use the
/// app — it was suspended, its access was paused, or it was deleted. Reached
/// from the router when [AuthStatus.blocked] is emitted (on launch, on resume,
/// or when a suspended session tries to enter).
class AccountBlockedPage extends StatelessWidget {
  const AccountBlockedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final standing =
        context.select<AuthCubit, AccountStanding?>((c) => c.state.block) ??
        AccountStanding.unknown;
    final french = context.isFrench;
    final copy = _copyFor(standing.kind, french);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.gutter),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                ),
                child: Icon(copy.icon, size: 44, color: AppColors.onAccent),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                copy.title,
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                copy.body,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              if (standing.reason != null &&
                  standing.reason!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                _InfoRow(
                  label: french ? 'Motif' : 'Reason',
                  value: standing.reason!.trim(),
                ),
              ],
              if (standing.until != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(
                  label: french ? 'Jusqu\'au' : 'Until',
                  value: _formatDate(standing.until!, french),
                ),
              ],
              const Spacer(flex: 3),
              NeuButton(
                label: french ? 'Retour à la connexion' : 'Back to sign in',
                icon: AppIcons.back,
                onPressed: () => context.read<AuthCubit>().acknowledgeBlock(),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                french
                    ? 'Besoin d\'aide ? Écrivez à support@nesty.tn'
                    : 'Need help? Contact support@nesty.tn',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.tertiaryLabel,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  _BlockCopy _copyFor(AccountStandingKind kind, bool french) {
    switch (kind) {
      case AccountStandingKind.deleted:
        return _BlockCopy(
          icon: AppIcons.trash,
          title: french ? 'Compte fermé' : 'Account closed',
          body: french
              ? 'Ce compte n\'est plus disponible. Si vous pensez qu\'il '
                    's\'agit d\'une erreur, contactez notre support.'
              : 'This account is no longer available. If you think this is a '
                    'mistake, please reach out to our support team.',
        );
      case AccountStandingKind.disabled:
        return _BlockCopy(
          icon: AppIcons.clock,
          title: french ? 'Accès en pause' : 'Access paused',
          body: french
              ? 'L\'accès à ce compte est temporairement en pause. '
                    'Contactez-nous pour le réactiver.'
              : 'Access to this account is paused for now. Get in touch and '
                    'we\'ll help you get back in.',
        );
      case AccountStandingKind.banned:
      default:
        return _BlockCopy(
          icon: AppIcons.shield,
          title: french ? 'Compte suspendu' : 'Account suspended',
          body: french
              ? 'Ce compte a été suspendu pour non-respect de nos règles. '
                    'Contactez le support si vous avez des questions.'
              : 'This account has been suspended for breaking our rules. '
                    'Contact support if you have any questions.',
        );
    }
  }

  String _formatDate(DateTime date, bool french) {
    final d = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return french
        ? '${two(d.day)}/${two(d.month)}/${d.year}'
        : '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}

class _BlockCopy {
  const _BlockCopy({
    required this.icon,
    required this.title,
    required this.body,
  });
  final IconData icon;
  final String title;
  final String body;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.secondaryLabel,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
