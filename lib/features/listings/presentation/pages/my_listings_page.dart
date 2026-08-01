import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../core/branding/app_icons.dart';
import '../../../../core/format/money.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/ios/ios_sliver_scaffold.dart';
import '../../../../core/widgets/motion/fade_slide_in.dart';
import '../../../../core/widgets/neu/neu_surface.dart';
import '../../../reservations/data/reservations_store.dart';
import '../../../reservations/domain/entities/reservation.dart';
import '../../data/datasources/host_listings_store.dart';
import '../../domain/entities/listing_schema.dart';
import '../../domain/entities/property.dart';

/// Host-only tab. Lists every place the agency has published — from Supabase
/// when connected (so places added on mobile OR the web both appear), marking
/// each Available or Reserved from the live reservations.
class MyListingsPage extends StatefulWidget {
  const MyListingsPage({super.key});

  @override
  State<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends State<MyListingsPage> {
  final HostListingsStore _store = sl<HostListingsStore>();

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  @override
  Widget build(BuildContext context) {
    final reservations = sl<ReservationsStore>();
    return ListenableBuilder(
      listenable: Listenable.merge([_store, reservations]),
      builder: (context, _) {
        final items = _store.items;
        return IosSliverScaffold(
          title: 'Your listings',
          onRefresh: () => _store.load(),
          slivers: [
            if (items.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyListings(),
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
                        ? '1 place live on Nesty'
                        : '${items.length} places live on Nesty',
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
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final property = items[index];
                    final reserved = reservations.all.any(
                      (r) =>
                          r.propertyId == property.id &&
                          r.status.isActive &&
                          r.isUpcoming,
                    );
                    return FadeSlideIn(
                      delay: Duration(milliseconds: 50 + index * 60),
                      child: _ListingRow(
                        property: property,
                        reserved: reserved,
                        onTap: () => context.push(
                          AppRoutes.listingDetailsPath(property.id),
                        ),
                        onDelete: () => _store.remove(property.id),
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
  }
}

class _ListingRow extends StatelessWidget {
  const _ListingRow({
    required this.property,
    required this.reserved,
    required this.onTap,
    required this.onDelete,
  });

  final Property property;
  final bool reserved;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NeuSurface(
      borderRadius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 76,
                height: 76,
                child: AppImage(property.coverImage, fit: BoxFit.cover),
              ),
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
                          property.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      // Anything that isn't live is called out — this is the
                      // only screen where a host sees their own drafts, so the
                      // difference has to be obvious.
                      if (!property.status.isLive) ...[
                        const SizedBox(width: AppSpacing.sm),
                        _StatusChip(status: property.status),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    property.city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        formatDinars(property.displayPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        ' / ${property.displayPricingModel.unitFor(context.isFrench)}',
                        style: const TextStyle(
                          color: AppColors.secondaryLabel,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: reserved
                              ? AppColors.ink
                              : AppColors.accentSoft,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          reserved ? 'Reserved' : 'Available',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: reserved
                                ? AppColors.onAccent
                                : AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                AppIcons.trash,
                size: 18,
                color: AppColors.tertiaryLabel,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyListings extends StatelessWidget {
  const _EmptyListings();

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
                  Icons.view_in_ar_rounded,
                  size: 40,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FadeSlideIn(
              delay: const Duration(milliseconds: 90),
              child: Text(
                'Publish your first place',
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FadeSlideIn(
              delay: const Duration(milliseconds: 160),
              child: Text(
                'Add a cover, the basics and a short description — and your '
                'place goes live for seekers. Tap the + to start.',
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

/// Small lifecycle marker on a host's own listing card. Stays in the grey
/// register — a draft is a quiet state, not an error.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ListingStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.labelFor(context.isFrench),
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
          color: AppColors.secondaryLabel,
        ),
      ),
    );
  }
}
