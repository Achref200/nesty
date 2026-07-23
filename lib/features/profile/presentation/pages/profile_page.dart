import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/branding/app_icons.dart';
import '../../../../core/services/app_feedback.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/motion/nesty_loader.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/ios/ios_sliver_scaffold.dart';
import '../../../../core/widgets/motion/fade_slide_in.dart';
import '../../../../core/widgets/neu/neu_button.dart';
import '../../../../core/widgets/neu/neu_field.dart';
import '../../../../core/widgets/neu/neu_surface.dart';
import '../../../../core/widgets/neu/neu_tappable.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../subscription/data/subscription_store.dart';
import '../../../subscription/domain/entities/subscription_plan.dart';
import '../../../subscription/presentation/pages/paywall_page.dart';
import '../../../verification/presentation/widgets/verification_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, this.showBack = false});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return IosSliverScaffold(
      title: 'Profile',
      leading: showBack
          ? IconButton(
              icon: const Icon(AppIcons.back, size: 20),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.sm,
            AppSpacing.gutter,
            120,
          ),
          sliver: SliverList.list(
            children: [
              FadeSlideIn(
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    return _ProfileCard(user: state.user);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const FadeSlideIn(
                delay: Duration(milliseconds: 80),
                child: VerificationCard(),
              ),
              const SizedBox(height: AppSpacing.xl),
              const FadeSlideIn(
                delay: Duration(milliseconds: 100),
                child: _SectionLabel('Account'),
              ),
              const SizedBox(height: AppSpacing.sm),
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: _Tile(
                  AppIcons.profile,
                  'Personal details',
                  onTap: () => _editName(context),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                delay: const Duration(milliseconds: 160),
                child: _Tile(
                  AppIcons.lock,
                  'Change password',
                  onTap: () => _changePassword(context),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: _Tile(
                  AppIcons.settings,
                  'Settings & preferences',
                  onTap: () => context.push(AppRoutes.settings),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const FadeSlideIn(
                delay: Duration(milliseconds: 200),
                child: _PartnerTile(),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FadeSlideIn(
                delay: const Duration(milliseconds: 340),
                child: NeuButton(
                  label: 'Sign out',
                  filled: false,
                  icon: AppIcons.signOut,
                  onPressed: () => context.read<AuthCubit>().signOut(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _changePassword(BuildContext context) {
    final cubit = context.read<AuthCubit>();
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.sm,
          AppSpacing.gutter,
          MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New password',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            NeuField(
              controller: controller,
              placeholder: 'New password (6+ characters)',
              icon: AppIcons.lock,
              obscureText: true,
            ),
            const SizedBox(height: AppSpacing.lg),
            NeuButton(
              label: 'Update password',
              onPressed: () async {
                final pw = controller.text;
                if (pw.length < 6) {
                  AppFeedback.error(
                    sheetContext,
                    'Password needs at least 6 characters.',
                  );
                  return;
                }
                Navigator.of(sheetContext).pop();
                final error = await cubit.updatePassword(pw);
                if (!context.mounted) return;
                if (error == null) {
                  AppFeedback.success(context, 'Password updated.');
                } else {
                  AppFeedback.error(context, error);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _editName(BuildContext context) {
    final cubit = context.read<AuthCubit>();
    final controller = TextEditingController(
      text: cubit.state.user?.fullName ?? '',
    );
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.sm,
          AppSpacing.gutter,
          MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Your name',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            NeuField(
              controller: controller,
              placeholder: 'Full name',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: AppSpacing.lg),
            NeuButton(
              label: 'Save',
              onPressed: () {
                cubit.updateName(controller.text);
                Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});
  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NeuSurface(
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          _AvatarEditor(user: user),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? 'Guest',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(user?.email ?? '', style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.sm),
                _RoleBadge(role: user?.role ?? UserRole.seeker),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable avatar that lets the user pick a photo from their device and
/// uploads it to Supabase Storage, then saves the URL on their profile.
class _AvatarEditor extends StatefulWidget {
  const _AvatarEditor({required this.user});
  final AppUser? user;

  @override
  State<_AvatarEditor> createState() => _AvatarEditorState();
}

class _AvatarEditorState extends State<_AvatarEditor> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  Future<void> _pick() async {
    final cubit = context.read<AuthCubit>();
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (x == null) return;
    setState(() => _busy = true);
    final error = await _uploadAndSave(cubit, x);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) {
      AppFeedback.error(context, error);
    } else {
      AppFeedback.success(context, 'Profile photo updated');
    }
  }

  Future<String?> _uploadAndSave(AuthCubit cubit, XFile x) async {
    try {
      final url = await Cloudinary.uploadFile(
        File(x.path),
        folder: 'nesty/avatars',
      );
      return cubit.updateAvatar(url);
    } on CloudinaryException catch (e) {
      return e.message;
    } catch (_) {
      return 'Couldn\'t upload the photo. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.user?.avatarUrl;
    final hasImage = url != null && url.isNotEmpty;
    return GestureDetector(
      onTap: _busy ? null : _pick,
      child: Stack(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.fill,
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.antiAlias,
            child: _busy
                ? const Center(
                    child: NestyLoader(size: 26),
                  )
                : hasImage
                    ? AppImage(url, fit: BoxFit.cover)
                    : const Icon(
                        AppIcons.profile,
                        size: 28,
                        color: AppColors.textSecondary,
                      ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 12,
                color: AppColors.onAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A fixed pill showing the account type. Seekers, agencies and partners are
/// distinct accounts — the only in-app transition is a seeker upgrading to a
/// (paid) Partner.
class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final (icon, label) = switch (role) {
      UserRole.host => (AppIcons.agency, 'Agency account'),
      UserRole.partner => (AppIcons.partner, 'Partner account'),
      UserRole.seeker => (AppIcons.seeker, 'Seeker account'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.onAccent),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.onAccent,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.secondaryLabel,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.label, {this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return NeuTappable(
      onTap: onTap ?? () {},
      borderRadius: AppRadius.md,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textPrimary, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Icon(
            AppIcons.chevronRight,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

/// Role-aware entry to the Partner programme. Seekers see a promo to upgrade
/// (paid, behind the paywall); Partners see a shortcut to manage their plan;
/// agencies see nothing (they're provisioned by Nesty).
class _PartnerTile extends StatelessWidget {
  const _PartnerTile();

  Future<void> _openPaywall(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaywallPage(upgrade: true)),
    );
  }

  /// Partner subscription management — shows the plan and the two ways out
  /// (change plan, or cancel — which is what drops them back to a seeker).
  void _manage(BuildContext context) {
    final store = sl<SubscriptionStore>();
    final authCubit = context.read<AuthCubit>();
    final sub = store.current;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final renew = sub?.currentPeriodEnd;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.sm,
            AppSpacing.gutter,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${sub?.plan.label ?? 'Partner'} plan',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                renew == null
                    ? 'Active subscription.'
                    : 'Renews ${renew.day}/${renew.month}/${renew.year}.',
                style: Theme.of(sheetContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              NeuButton(
                label: 'Change plan',
                icon: AppIcons.trending,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _openPaywall(context);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              NeuButton(
                label: 'Cancel subscription',
                filled: false,
                icon: AppIcons.close,
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  final error = await store.cancel();
                  if (error == null) {
                    // Cancelling is one of the only two ways back to a seeker.
                    await authCubit.switchRole(UserRole.seeker);
                  }
                  if (!context.mounted) return;
                  if (error == null) {
                    AppFeedback.success(
                      context,
                      'Subscription cancelled — you\'re back to a seeker account.',
                    );
                  } else {
                    AppFeedback.error(context, error);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your Partner space stays available until the plan ends. You '
                'can only return to a seeker account by cancelling or letting '
                'it lapse.',
                style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.select<AuthCubit, UserRole>(
      (c) => c.state.user?.role ?? UserRole.seeker,
    );

    if (role == UserRole.partner) {
      return _Tile(
        AppIcons.subscription,
        'Manage subscription',
        onTap: () => _manage(context),
      );
    }
    if (role == UserRole.host) return const SizedBox.shrink();

    // Seeker — a promo to become a Partner.
    final theme = Theme.of(context);
    return NeuTappable(
      onTap: () => _openPaywall(context),
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: AppColors.accent,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.onAccent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              AppIcons.partner,
              color: AppColors.onAccent,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Become a Partner',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.onAccent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'List homes from your network and earn. Subscription plans.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onAccent.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            AppIcons.chevronRight,
            color: AppColors.onAccent,
          ),
        ],
      ),
    );
  }
}

/// An in-app answer to "who is Nestly for, and why?" — shown through the
/// product, not a wall of marketing copy. Nestly is a two-sided marketplace
/// (B2C): seekers on one side, hosts on the other, meeting over trust and 3D.
class AboutSheet extends StatelessWidget {
  const AboutSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          AppSpacing.sm,
          AppSpacing.gutter,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Why Nesty exists', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Renting in Tunisia runs on Facebook groups and blurry photos. '
              'Nesty replaces the guesswork with trust and a real 3D tour — '
              'so you only visit the home you already believe in.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            const _AboutRow(
              icon: AppIcons.seeker,
              title: 'For seekers',
              body: 'Students and young professionals who want to tour, '
                  'compare and shortlist homes without wasting a Saturday.',
            ),
            const SizedBox(height: AppSpacing.lg),
            const _AboutRow(
              icon: AppIcons.agency,
              title: 'For agencies',
              body: 'Owners who want serious tenants fast — and finally see '
                  'how people react to their place.',
            ),
            const SizedBox(height: AppSpacing.lg),
            const _AboutRow(
              icon: AppIcons.verified,
              title: 'The model',
              body: 'A two-sided marketplace built on trust, 3D tours and '
                  'neighbourhood intelligence — not listing volume.',
            ),
            const SizedBox(height: AppSpacing.xl),
            NeuButton(
              label: 'Got it',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.fill,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 18, color: AppColors.ink),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  color: AppColors.secondaryLabel,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
