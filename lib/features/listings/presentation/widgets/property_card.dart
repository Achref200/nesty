import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/branding/app_icons.dart';
import '../../../../core/format/money.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/services/app_feedback.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/motion/parallax_image.dart';
import '../../../../core/widgets/neu/neu_tappable.dart';
import '../../../saved/presentation/cubit/saved_cubit.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/trust_info.dart';
import 'trust_badge.dart';

/// The primary feed card. A large image with a floating 3D badge, then a
/// compact info row rendered on a soft-morphism surface.
class PropertyCard extends StatefulWidget {
  const PropertyCard({super.key, required this.property, this.onTap});

  final Property property;
  final VoidCallback? onTap;

  @override
  State<PropertyCard> createState() => _PropertyCardState();
}

class _PropertyCardState extends State<PropertyCard> {
  final GlobalKey _imageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final property = widget.property;
    return NeuTappable(
      onTap: widget.onTap,
      borderRadius: AppRadius.lg,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            key: _imageKey,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: AspectRatio(
                  aspectRatio: 16 / 11,
                  child: Hero(
                    tag: 'property-image-${property.id}',
                    child: ParallaxImage(
                      itemKey: _imageKey,
                      child: AppImage(property.coverImage, fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              if (property.has3dTour)
                Positioned(
                  left: AppSpacing.md,
                  top: AppSpacing.md,
                  child: _Badge(),
                ),
              Positioned(
                right: AppSpacing.md,
                top: AppSpacing.md,
                child: _SaveButton(id: property.id),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.sm,
            ),
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
                    const Icon(
                      AppIcons.star,
                      size: 15,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      property.rating.toStringAsFixed(2),
                      style: theme.textTheme.labelLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        property.city,
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    TrustBadge(trust: TrustInfo.of(property)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatDinars(property.pricePerMonth),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(' / month', style: theme.textTheme.bodyMedium),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _MiniTag(property.rentalTerm.label, filled: true),
                    for (final t in property.tags.take(2))
                      _MiniTag(_prettyTag(t)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _prettyTag(String t) {
  final s = t.replaceAll('-', ' ').replaceAll('_', ' ');
  return s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

/// A compact monochrome pill used to surface a listing's term & tags.
class _MiniTag extends StatelessWidget {
  const _MiniTag(this.label, {this.filled = false});
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: filled ? AppColors.ink : AppColors.fill,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: filled ? AppColors.onAccent : AppColors.secondaryLabel,
        ),
      ),
    );
  }
}

/// A small circular heart that saves/unsaves a listing, backed by [SavedCubit]
/// so the state persists and stays in sync everywhere the card appears.
class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final saved = context.select<SavedCubit, bool>((c) => c.isSaved(id));
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.read<SavedCubit>().toggle(id);
        if (!saved) Analytics.save(id);
        AppFeedback.info(
          context,
          saved ? 'Removed from saved' : 'Saved to your list',
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(saved),
            size: 18,
            color: saved ? AppColors.ink : AppColors.secondaryLabel,
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.tour3d, size: 14, color: AppColors.onAccent),
          SizedBox(width: 5),
          Text(
            '3D tour',
            style: TextStyle(
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
