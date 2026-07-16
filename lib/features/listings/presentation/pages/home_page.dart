import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/di/injection.dart';
import '../../../../core/branding/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ios/ios_sliver_scaffold.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/motion/fade_slide_in.dart';
import '../../../../core/widgets/motion/shimmer.dart';
import '../../../../core/widgets/neu/neu_button.dart';
import '../../../../core/widgets/neu/neu_surface.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../notifications/data/notifications_store.dart';
import '../cubit/listings_cubit.dart';
import '../widgets/category_chips.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/property_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return IosSliverScaffold(
      title: 'Explore',
      trailing: const _HeaderActions(),
      onRefresh: () => context.read<ListingsCubit>().refresh(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),
        const SliverToBoxAdapter(child: FadeSlideIn(child: _SearchField())),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
        SliverToBoxAdapter(
          child: FadeSlideIn(
            delay: const Duration(milliseconds: 80),
            child: BlocBuilder<ListingsCubit, ListingsState>(
              buildWhen: (a, b) => a.category != b.category,
              builder: (context, state) => CategoryChips(
                selected: state.category,
                onSelected: (c) =>
                    context.read<ListingsCubit>().selectCategory(c),
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        BlocBuilder<ListingsCubit, ListingsState>(
          builder: (context, state) {
            switch (state.status) {
              case ListingsStatus.loading:
              case ListingsStatus.initial:
                return const _FeedSkeleton();
              case ListingsStatus.failure:
                return SliverToBoxAdapter(
                  child: _ErrorState(
                    message: state.errorMessage,
                    onRetry: () =>
                        context.read<ListingsCubit>().refresh(),
                  ),
                );
              case ListingsStatus.success:
                if (state.properties.isEmpty) {
                  return SliverToBoxAdapter(
                    child: _EmptyFeed(
                      filtered: state.filter.isActive,
                      onClear: () =>
                          context.read<ListingsCubit>().clearFilter(),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.gutter,
                    0,
                    AppSpacing.gutter,
                    120,
                  ),
                  sliver: SliverList.separated(
                    itemCount: state.properties.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.xxl),
                    itemBuilder: (context, index) {
                      final property = state.properties[index];
                      return FadeSlideIn(
                        delay: Duration(
                          milliseconds: 120 + (index.clamp(0, 6)) * 80,
                        ),
                        child: PropertyCard(
                          property: property,
                          onTap: () => context.push(
                            AppRoutes.listingDetailsPath(property.id),
                          ),
                        ),
                      );
                    },
                  ),
                );
            }
          },
        ),
      ],
    );
  }
}

class _HeaderActions extends StatelessWidget {
  const _HeaderActions();

  @override
  Widget build(BuildContext context) {
    final user = context.select<AuthCubit, AppUser?>((c) => c.state.user);
    final name = user?.displayName.trim() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: sl<NotificationsStore>(),
          builder: (context, _) {
            final unread = sl<NotificationsStore>().unread;
            return IconButton(
              onPressed: () => context.push(AppRoutes.notifications),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(AppIcons.bell, color: AppColors.ink, size: 22),
                  if (unread > 0)
                    Positioned(
                      right: -4,
                      top: -3,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints: const BoxConstraints(minWidth: 15),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unread > 9 ? '9+' : '$unread',
                          style: const TextStyle(
                            color: AppColors.onAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              tooltip: 'Notifications',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 38, height: 38),
            );
          },
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: () => context.push(AppRoutes.settings),
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty)
                ? AppImage(user.avatarUrl!, fit: BoxFit.cover)
                : Text(
                    initial,
                    style: const TextStyle(
                      color: AppColors.onAccent,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField();

  Future<void> _openFilters(BuildContext context) async {
    final cubit = context.read<ListingsCubit>();
    final result = await showFilterSheet(
      context,
      cubit.state.filter,
      cubit.destinations,
    );
    if (result != null) await cubit.applyFilter(result);
  }

  @override
  Widget build(BuildContext context) {
    final count = context.select<ListingsCubit, int>(
      (c) => c.state.filter.activeCount,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _openFilters(context),
              child: NeuSurface(
                pressed: true,
                borderRadius: 12,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 11,
                ),
                child: Row(
                  children: const [
                    Icon(
                      AppIcons.explore,
                      color: AppColors.secondaryLabel,
                      size: 20,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Text(
                      'Search city, area or budget',
                      style: TextStyle(
                        color: AppColors.secondaryLabel,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () => _openFilters(context),
            child: NeuSurface(
              borderRadius: 12,
              padding: const EdgeInsets.all(13),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.tune_rounded, size: 22, color: AppColors.ink),
                  if (count > 0)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: AppColors.onAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A shimmering placeholder feed shown while listings load.
class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        120,
      ),
      sliver: SliverList.separated(
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xxl),
        itemBuilder: (_, _) => const _CardSkeleton(),
      ),
    );
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget box(double h, double w, [double r = 12]) => Container(
      height: h,
      width: w,
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    return Shimmer(
      baseColor: AppColors.fill,
      highlightColor: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 11,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.fill,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(children: [box(16, 160), const Spacer(), box(16, 40)]),
          const SizedBox(height: AppSpacing.sm),
          box(13, 120),
          const SizedBox(height: AppSpacing.md),
          box(16, 90),
        ],
      ),
    );
  }
}

/// A friendly network / error state with a retry action.
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, this.message});
  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        60,
        AppSpacing.gutter,
        0,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeuSurface(
              borderRadius: 28,
              depth: 8,
              padding: const EdgeInsets.all(24),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 34,
                color: AppColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Couldn\'t load homes', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'It\'s usually a dropped connection. Give it another try.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 180,
              child: NeuButton(
                label: 'Try again',
                icon: AppIcons.chevronRight,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({this.filtered = false, this.onClear});
  final bool filtered;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        60,
        AppSpacing.gutter,
        0,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeuSurface(
              borderRadius: 28,
              depth: 8,
              padding: const EdgeInsets.all(24),
              child: Icon(
                filtered ? Icons.tune_rounded : AppIcons.explore,
                size: 34,
                color: AppColors.secondaryLabel,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              filtered ? 'No homes match your filters' : 'No homes here yet',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              filtered
                  ? 'Try widening your budget or clearing a filter.'
                  : 'New places land here as agencies publish them.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            if (filtered && onClear != null) ...[
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: 180,
                child: NeuButton(label: 'Clear filters', onPressed: onClear!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
