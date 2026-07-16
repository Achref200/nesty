import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/branding/app_icons.dart';
import '../../../../core/services/local_store.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/neu/neu_button.dart';
import '../../../../core/widgets/neu/neu_surface.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
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
      'language': 'English',
      ...?LocalStore.instance.getJson(_key),
    };
  }

  void _set(String key, Object value) {
    setState(() => _prefs[key] = value);
    LocalStore.instance.setJson(_key, _prefs);
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.md,
          AppSpacing.gutter,
          AppSpacing.xxl,
        ),
        children: [
          const _SectionLabel('Notifications'),
          const SizedBox(height: AppSpacing.sm),
          _SwitchTile(
            icon: AppIcons.bell,
            title: 'Push notifications',
            subtitle: 'Visit and reservation updates',
            value: _prefs['push'] == true,
            onChanged: (v) => _set('push', v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SwitchTile(
            icon: AppIcons.mail,
            title: 'Email updates',
            subtitle: 'Summaries and confirmations',
            value: _prefs['email'] == true,
            onChanged: (v) => _set('email', v),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SwitchTile(
            icon: AppIcons.clock,
            title: 'Reminders',
            subtitle: 'A nudge before your visits',
            value: _prefs['reminders'] == true,
            onChanged: (v) => _set('reminders', v),
          ),
          const SizedBox(height: AppSpacing.xl),

          const _SectionLabel('Preferences'),
          const SizedBox(height: AppSpacing.sm),
          _NavTile(
            icon: Icons.translate_rounded,
            title: 'Language',
            trailing: _prefs['language'] as String? ?? 'English',
            onTap: _pickLanguage,
          ),
          const SizedBox(height: AppSpacing.sm),
          _NavTile(
            icon: AppIcons.bell,
            title: 'Notifications inbox',
            onTap: () => context.push(AppRoutes.notifications),
          ),
          const SizedBox(height: AppSpacing.xl),

          const _SectionLabel('About'),
          const SizedBox(height: AppSpacing.sm),
          _NavTile(
            icon: AppIcons.about,
            title: 'What is Nesty?',
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => const AboutSheet(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const _NavTile(icon: AppIcons.shield, title: 'Privacy & security'),
          const SizedBox(height: AppSpacing.sm),
          const _NavTile(icon: AppIcons.help, title: 'Help center'),
          const SizedBox(height: AppSpacing.sm),
          const _NavTile(
            icon: Icons.info_outline_rounded,
            title: 'App version',
            trailing: '1.0.0',
          ),
          const SizedBox(height: AppSpacing.xxl),

          NeuButton(
            label: 'Sign out',
            filled: false,
            icon: AppIcons.signOut,
            onPressed: () => context.read<AuthCubit>().signOut(),
          ),
        ],
      ),
    );
  }

  void _pickLanguage() {
    const options = ['English', 'Français', 'العربية'];
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
  });

  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return NeuSurface(
      borderRadius: AppRadius.md,
      padding: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, size: 20, color: AppColors.ink),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
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
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.tertiaryLabel,
            ),
          ],
        ),
      ),
    );
  }
}
