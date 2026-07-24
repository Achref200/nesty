import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/ios/ios_sliver_scaffold.dart';
import '../../../../core/widgets/motion/fade_slide_in.dart';
import '../../../../core/widgets/neu/neu_surface.dart';
import '../../../listings/presentation/cubit/listings_cubit.dart';
import '../../../listings/presentation/widgets/property_card.dart';
import '../cubit/saved_cubit.dart';

/// Saved / favourites tab. Reads the saved ids from [SavedCubit] and resolves
/// them against the loaded catalog, so everything the user hearted persists and
/// appears here — with a warm, human empty-state when the list is bare.
class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SavedCubit, SavedState>(
      builder: (context, saved) {
        return BlocBuilder<ListingsCubit, ListingsState>(
          builder: (context, listings) {
            final items = listings.properties
                .where((p) => saved.ids.contains(p.id))
                .toList();

            return IosSliverScaffold(
              title: context.copy('Saved', 'Favoris'),
              slivers: [
                if (items.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptySaved(),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.gutter,
                        AppSpacing.sm,
                        AppSpacing.gutter,
                        AppSpacing.lg,
                      ),
                      child: Text(
                        items.length == 1
                            ? context.copy(
                                '1 home you\'re keeping an eye on',
                                '1 logement que vous suivez',
                              )
                            : context.copy(
                                '${items.length} homes you\'re keeping an eye on',
                                '${items.length} logements que vous suivez',
                              ),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.gutter,
                      0,
                      AppSpacing.gutter,
                      120,
                    ),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.xxl),
                      itemBuilder: (context, index) {
                        final property = items[index];
                        return FadeSlideIn(
                          delay: Duration(
                            milliseconds: 60 + (index.clamp(0, 6)) * 70,
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
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _EmptySaved extends StatelessWidget {
  const _EmptySaved();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        0,
        AppSpacing.gutter,
        140,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeSlideIn(
              child: NeuSurface(
                borderRadius: 32,
                depth: 10,
                padding: const EdgeInsets.all(28),
                child: const Icon(
                  Icons.favorite_border_rounded,
                  size: 40,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FadeSlideIn(
              delay: const Duration(milliseconds: 90),
              child: Text(
                context.copy('Nothing saved yet', 'Aucun favori'),
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: Text(
                context.copy(
                  'Tap the heart on any home to keep it here — '
                      'your shortlist follows you between visits.',
                  'Touchez le cœur d\'un logement pour le garder ici — '
                      'votre sélection vous suit entre les visites.',
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
