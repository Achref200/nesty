import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/branding/app_icons.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/services/app_feedback.dart';
import '../../../../core/services/local_store.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/neu/neu_button.dart';
import '../../../../core/widgets/neu/neu_surface.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../onboarding/data/profile_setup_store.dart';
import '../../../profile/presentation/pages/profile_page.dart' show AboutSheet;

/// Preferences hub — notification channels, language and account actions.
/// Toggles persist on-device via [LocalStore] so they survive restarts.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _key = 'user_settings';

  late Map<String, dynamic> _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = {
      'push': true,
      'email': true,
      'reminders': true,
      'inbox': true,
      // Default to the language currently in effect (which follows the device
      // on first launch) until the member explicitly picks one.
      'language': AppLocale.instance.label,
      ...?LocalStore.instance.getJson(_key),
    };
  }

  void _set(String key, Object value) {
    setState(() => _prefs[key] = value);
    LocalStore.instance.setJson(_key, _prefs);
    if (key == 'push' ||
        key == 'email' ||
        key == 'reminders' ||
        key == 'inbox') {
      _syncNotificationPreferences();
    }
    HapticFeedback.selectionClick();
  }

  Future<void> _syncNotificationPreferences() async {
    if (!SupabaseService.isReady) return;
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      await SupabaseService.client.from('notification_preferences').upsert({
        'user_id': userId,
        'inbox_enabled': _prefs['inbox'] == true,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Local preference remains active when the user is offline.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(context.copy('Settings', 'Paramètres')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.md,
          AppSpacing.gutter,
          AppSpacing.xxl,
        ),
        children: [
          _SectionLabel(context.copy('Notifications', 'Notifications')),
          const SizedBox(height: AppSpacing.sm),
          _SwitchTile(
            icon: AppIcons.bell,
            title: context.copy('Push notifications', 'Notifications push'),
            subtitle: context.copy(
              'Visit and reservation updates',
              'Mises à jour des visites et réservations',
            ),
            value: _prefs['push'] == true,
            onChanged: (v) => _set('push', v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SwitchTile(
            icon: AppIcons.mail,
            title: context.copy('Email updates', 'Mises à jour par e-mail'),
            subtitle: context.copy(
              'Summaries and confirmations',
              'Récapitulatifs et confirmations',
            ),
            value: _prefs['email'] == true,
            onChanged: (v) => _set('email', v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SwitchTile(
            icon: AppIcons.clock,
            title: context.copy('Reminders', 'Rappels'),
            subtitle: context.copy(
              'A nudge before your visits',
              'Un rappel avant vos visites',
            ),
            value: _prefs['reminders'] == true,
            onChanged: (v) => _set('reminders', v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SwitchTile(
            icon: AppIcons.bell,
            title: context.copy(
              'In-app notifications',
              'Notifications dans l’application',
            ),
            subtitle: context.copy(
              'Verification and reservation updates',
              'Mises à jour des vérifications et réservations',
            ),
            value: _prefs['inbox'] == true,
            onChanged: (v) => _set('inbox', v),
          ),
          const SizedBox(height: AppSpacing.xl),

          _SectionLabel(context.copy('Preferences', 'Préférences')),
          const SizedBox(height: AppSpacing.sm),
          _NavTile(
            icon: Icons.translate_rounded,
            title: context.copy('Language', 'Langue'),
            trailing: _prefs['language'] as String? ?? 'English',
            onTap: _pickLanguage,
          ),
          const SizedBox(height: AppSpacing.sm),
          _NavTile(
            icon: AppIcons.bell,
            title: context.copy(
              'Notifications inbox',
              'Boîte de notifications',
            ),
            onTap: () => context.push(AppRoutes.notifications),
          ),
          const SizedBox(height: AppSpacing.xl),

          _SectionLabel(context.copy('About', 'À propos')),
          const SizedBox(height: AppSpacing.sm),
          _NavTile(
            icon: AppIcons.about,
            title: context.copy('What is Nesty?', 'Qu’est-ce que Nesty ?'),
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => const AboutSheet(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _NavTile(
            icon: AppIcons.shield,
            title: context.copy(
              'Privacy & security',
              'Confidentialité et sécurité',
            ),
            onTap: () => AppFeedback.comingSoon(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          _NavTile(
            icon: AppIcons.help,
            title: context.copy('Help center', 'Centre d’aide'),
            onTap: () => AppFeedback.comingSoon(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          _NavTile(
            icon: Icons.info_outline_rounded,
            title: context.copy('App version', 'Version de l’application'),
            trailing: '1.0.0',
          ),
          const SizedBox(height: AppSpacing.xl),

          _SectionLabel(context.copy('Account', 'Compte')),
          const SizedBox(height: AppSpacing.sm),
          _NavTile(
            icon: AppIcons.trash,
            title: context.copy('Delete account', 'Supprimer le compte'),
            danger: true,
            onTap: () => _confirmDeleteAccount(context),
          ),
          const SizedBox(height: AppSpacing.xxl),

          NeuButton(
            label: context.copy('Sign out', 'Se déconnecter'),
            filled: false,
            icon: AppIcons.signOut,
            onPressed: () {
              sl<ProfileSetupStore>().reset();
              context.read<AuthCubit>().signOut();
            },
          ),
        ],
      ),
    );
  }

  /// Confirms and performs permanent account deletion. On success the session
  /// ends and the router returns to the welcome flow.
  void _confirmDeleteAccount(BuildContext context) {
    final cubit = context.read<AuthCubit>();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(AppIcons.trash, color: AppColors.danger),
        title: Text(context.copy(
          'Delete your account?',
          'Supprimer votre compte ?',
        )),
        content: Text(context.copy(
          'This permanently removes your account, your listings, reservations '
              'and saved homes. This can\'t be undone.',
          'Ceci supprime définitivement votre compte, vos annonces, vos '
              'réservations et vos favoris. Cette action est irréversible.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.copy('Cancel', 'Annuler')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.onAccent,
            ),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final error = await cubit.deleteAccount();
              if (!context.mounted) return;
              if (error != null) {
                AppFeedback.errorToast(context, error);
              } else {
                AppFeedback.success(
                  context,
                  context.copy(
                    'Your account has been deleted.',
                    'Votre compte a été supprimé.',
                  ),
                );
              }
            },
            child: Text(context.copy('Delete', 'Supprimer')),
          ),
        ],
      ),
    );
  }

  void _pickLanguage() {
    const options = ['English', 'Français'];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final o in options)
              ListTile(
                title: Text(o),
                trailing: _prefs['language'] == o
                    ? const Icon(AppIcons.check, color: AppColors.ink)
                    : null,
                onTap: () {
                  _set('language', o);
                  AppLocale.instance.select(o);
                  Navigator.of(sheetContext).pop();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.secondaryLabel,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return NeuSurface(
      borderRadius: AppRadius.md,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.ink),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.onAccent,
            activeTrackColor: AppColors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.ink;
    return NeuSurface(
      borderRadius: AppRadius.md,
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, size: 20, color: color),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: danger ? FontWeight.w700 : FontWeight.w600,
            color: color,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null)
              Text(
                trailing!,
                style: const TextStyle(color: AppColors.secondaryLabel),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: danger
                  ? AppColors.danger.withValues(alpha: 0.6)
                  : AppColors.tertiaryLabel,
            ),
          ],
        ),
      ),
    );
  }
}
