import 'package:flutter/material.dart';

import '../../../app/di/injection.dart';
import '../../../core/branding/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/neu/neu_button.dart';
import '../../listings/data/datasources/host_listings_store.dart';
import '../data/subscription_store.dart';
import '../domain/entities/subscription_plan.dart';
import 'pages/paywall_page.dart';

/// Gate that enforces a Partner's monthly listing quota before publishing.
///
/// Returns `true` when the partner may publish (within quota, unlimited, or a
/// tier we couldn't resolve). When the cap is reached it presents an upsell
/// sheet and returns `false`, offering a one-tap jump to the paywall.
Future<bool> ensureWithinListingLimit(BuildContext context) async {
  final subStore = sl<SubscriptionStore>();
  final hostStore = sl<HostListingsStore>();

  final limit =
      subStore.current?.listingLimit ?? SubscriptionPlan.standard.listingLimit;
  final unlimited = limit < 0;
  if (unlimited || hostStore.items.length < limit) return true;

  final upgrade = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
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
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.fill,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              AppIcons.subscription,
              color: AppColors.ink,
              size: 24,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'You\'ve reached your plan\'s limit',
            style: Theme.of(sheetContext).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'You have $limit active listings on your current plan. Upgrade to '
            'publish more and unlock priority placement.',
            style: Theme.of(sheetContext).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          NeuButton(
            label: 'See plans',
            icon: AppIcons.trending,
            onPressed: () => Navigator.of(sheetContext).pop(true),
          ),
          const SizedBox(height: AppSpacing.sm),
          NeuButton(
            label: 'Not now',
            filled: false,
            onPressed: () => Navigator.of(sheetContext).pop(false),
          ),
        ],
      ),
    ),
  );

  if (upgrade == true && context.mounted) {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PaywallPage(upgrade: true)),
    );
  }
  return false;
}
