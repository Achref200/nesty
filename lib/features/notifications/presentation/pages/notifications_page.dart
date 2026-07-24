import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/branding/app_icons.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/neu/neu_surface.dart';
import '../../data/notifications_store.dart';

/// The activity center. Reads the real Supabase `notifications` table (fed by
/// reservation triggers) and updates live — an agency confirmation on the web
/// lands here on mobile instantly.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationsStore _store = sl<NotificationsStore>();

  @override
  void initState() {
    super.initState();
    // Opening the center clears the unread badge.
    WidgetsBinding.instance.addPostFrameCallback((_) => _store.markAllRead());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(context.copy('Notifications', 'Notifications')),
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final items = _store.all;
          if (items.isEmpty) return const _EmptyNotifications();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.md,
              AppSpacing.gutter,
              AppSpacing.xxl,
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _NotificationTile(items[i]),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile(this.notification);
  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _iconFor(notification.type);
    return NeuSurface(
      borderRadius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.fill,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 20, color: AppColors.ink),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!notification.read)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (notification.body != null) ...[
                  const SizedBox(height: 2),
                  Text(notification.body!, style: theme.textTheme.bodyMedium),
                ],
                const SizedBox(height: 4),
                Text(
                  _timeAgo(notification.createdAt),
                  style: const TextStyle(
                    color: AppColors.tertiaryLabel,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String type) {
    if (type.contains('confirmed')) return AppIcons.check;
    if (type.contains('cancelled')) return Icons.close_rounded;
    if (type.contains('completed')) return AppIcons.star;
    if (type.contains('request')) return AppIcons.clock;
    return AppIcons.bell;
  }

  static String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NeuSurface(
            borderRadius: 28,
            depth: 8,
            padding: const EdgeInsets.all(24),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 34,
              color: AppColors.secondaryLabel,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            context.copy('Nothing yet', 'Rien pour l\'instant'),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
            child: Text(
              context.copy(
                'When you request a visit or an agency responds, updates show up '
                    'here in real time.',
                'Quand vous demandez une visite ou qu\'une agence répond, les '
                    'mises à jour apparaissent ici en temps réel.',
              ),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
