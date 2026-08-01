import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/branding/app_icons.dart';
import '../../../../core/config/ai_config.dart';
import '../../../../core/format/money.dart';
import '../../../../core/localization/app_locale.dart';
import '../../../../core/services/analytics_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_image.dart';
import '../../../../core/widgets/motion/nesty_loader.dart';
import '../../../../core/widgets/motion/fade_slide_in.dart';
import '../../../../core/widgets/neu/neu_button.dart';
import '../../../../core/widgets/neu/neu_icon_button.dart';
import '../../../../core/widgets/neu/neu_surface.dart';
import '../../../assistant/presentation/widgets/assistant_sheet.dart';
import '../../../saved/presentation/cubit/saved_cubit.dart';
import '../../../reservations/presentation/pages/reservation_flow_page.dart';
import '../../domain/entities/listing_schema.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/trust_info.dart';
import '../cubit/listing_details_cubit.dart';
import '../widgets/neighborhood_section.dart';
import '../widgets/trust_section.dart';

class ListingDetailsPage extends StatelessWidget {
  const ListingDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<ListingDetailsCubit, ListingDetailsState>(
        builder: (context, state) {
          if (state.status == ListingDetailsStatus.loading ||
              state.status == ListingDetailsStatus.initial) {
            return const Center(child: NestyLoader());
          }
          if (state.status == ListingDetailsStatus.failure ||
              state.property == null) {
            return Center(
              child: Text(
                state.errorMessage ?? context.copy('Not found', 'Introuvable'),
              ),
            );
          }
          return _Content(property: state.property!);
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.md,
              AppSpacing.gutter,
              120,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    NeuIconButton(
                      icon: AppIcons.back,
                      onTap: () => context.pop(),
                    ),
                    BlocBuilder<SavedCubit, SavedState>(
                      builder: (context, saved) {
                        final fav = saved.ids.contains(property.id);
                        return NeuIconButton(
                          icon: fav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          iconColor: fav ? AppColors.ink : null,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            if (!fav) Analytics.save(property.id);
                            context.read<SavedCubit>().toggle(property.id);
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: AspectRatio(
                    aspectRatio: 16 / 11,
                    child: Hero(
                      tag: 'property-image-${property.id}',
                      child: AppImage(property.coverImage, fit: BoxFit.cover),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          property.title,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      const Icon(AppIcons.star, size: 18, color: AppColors.ink),
                      const SizedBox(width: 3),
                      Text(
                        property.rating.toStringAsFixed(2),
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '  (${property.reviewCount})',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 110),
                  child: Row(
                    children: [
                      const Icon(
                        AppIcons.location,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          property.address,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: _Facts(property: property),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 190),
                  child: TrustSection(trust: TrustInfo.of(property)),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 260),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.copy('About this place', 'À propos du logement'),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        property.description,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (AiConfig.enabled)
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 290),
                    child: _AskAiCard(property: property),
                  ),
                const SizedBox(height: AppSpacing.xl),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 310),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.copy('Amenities', 'Équipements'),
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _Amenities(amenities: property.amenities),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 325),
                  child: _StayTerms(property: property),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 340),
                  child: NeighborhoodSection(property: property),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 360),
                  child: _HostRow(
                    hostName: property.hostName,
                    type: property.type,
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _BottomBar(property: property),
        ),
      ],
    );
  }
}

/// House rules and booking conditions, exactly as the agency set them in the
/// dashboard wizard. Before this existed a traveller only found out about the
/// no-pets rule or the deposit after asking, which is the sort of small
/// surprise that loses a booking.
class _StayTerms extends StatelessWidget {
  const _StayTerms({required this.property});

  final Property property;

  @override
  Widget build(BuildContext context) {
    final french = context.isFrench;
    final theme = Theme.of(context);
    final rules = property.rules;
    final conditions = property.conditions;
    final pricing = property.pricing;

    final lines = <({IconData icon, String text})>[
      (
        icon: rules.pets
            ? Icons.pets_rounded
            : Icons.do_not_disturb_on_outlined,
        text: rules.pets
            ? context.copy('Pets welcome', 'Animaux acceptés')
            : context.copy('No pets', 'Animaux non admis'),
      ),
      (
        icon: rules.smoking
            ? Icons.smoking_rooms_rounded
            : Icons.smoke_free_rounded,
        text: rules.smoking
            ? context.copy('Smoking allowed', 'Fumeur autorisé')
            : context.copy('No smoking', 'Non-fumeur'),
      ),
      (
        icon: rules.party
            ? Icons.celebration_rounded
            : Icons.volume_off_rounded,
        text: rules.party
            ? context.copy('Events allowed', 'Fêtes autorisées')
            : context.copy('No parties or events', 'Fêtes non autorisées'),
      ),
      if (pricing.minNights > 1)
        (
          icon: Icons.nights_stay_outlined,
          text: context.copy(
            '${pricing.minNights} nights minimum',
            '${pricing.minNights} nuits minimum',
          ),
        ),
      (
        icon: Icons.event_available_outlined,
        text: conditions.cancellation.blurbFor(french),
      ),
      (
        icon: Icons.account_balance_wallet_outlined,
        text: conditions.paymentMethods
            .map((m) => m.labelFor(french))
            .join(' · '),
      ),
      if (conditions.paymentPolicy == PaymentPolicy.mandatoryAdvance &&
          conditions.advancePct > 0)
        (
          icon: Icons.savings_outlined,
          text: context.copy(
            '${conditions.advancePct.toStringAsFixed(0)}% deposit required',
            'Acompte de ${conditions.advancePct.toStringAsFixed(0)} % requis',
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.copy('Good to know', 'Bon à savoir'),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        NeuSurface(
          borderRadius: AppRadius.md,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.lg,
          ),
          child: Column(
            children: [
              for (final line in lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        line.icon,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          line.text,
                          style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.35,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (rules.instructions.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            rules.instructions.trim(),
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.property});
  final Property property;

  @override
  Widget build(BuildContext context) {
    return NeuSurface(
      borderRadius: AppRadius.md,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.lg,
        horizontal: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Capacity only shows once the host has actually set it — an empty
          // slot reading "0 guests" looks broken.
          if (property.maxGuests > 0) ...[
            _Fact(
              Icons.people_outline_rounded,
              '${property.maxGuests}',
              context.copy('Guests', 'Voyageurs'),
            ),
            _divider(),
          ],
          _Fact(AppIcons.bed, '${property.bedrooms}', context.copy('Bedrooms', 'Chambres')),
          _divider(),
          _Fact(AppIcons.bath, '${property.bathrooms}', context.copy('Bathrooms', 'Salles de bain')),
          if (property.areaSqm > 0) ...[
            _divider(),
            _Fact(
              AppIcons.area,
              '${property.areaSqm.toStringAsFixed(0)} m²',
              context.copy('Area', 'Surface'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 36, color: AppColors.divider);
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.value, this.label);
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textPrimary, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _Amenities extends StatelessWidget {
  const _Amenities({required this.amenities});
  final List<String> amenities;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        // Amenities come back as canonical ids ('hotWater'), the same ones the
        // dashboard writes. Translate at the edge so the chip reads properly in
        // both languages.
        for (final a in amenities)
          NeuSurface(
            borderRadius: AppRadius.pill,
            depth: 4,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              amenityLabel(a, context.isFrench),
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }
}

String _listingContext(Property p) {
  final price = '${p.pricePerMonth.toStringAsFixed(0)} ${p.currency}/month';
  final amenities = p.amenities.isEmpty
      ? 'none listed'
      : p.amenities.join(', ');
  return [
    'The user is viewing a specific listing on Nestly. Answer about THIS place.',
    'Title: ${p.title}',
    'Type: ${p.type.label} (${p.rentalTerm.label})',
    'Location: ${p.city} \u2014 ${p.address}',
    'Price: $price${p.billsIncluded ? ' (bills included)' : ''}',
    'Bedrooms: ${p.bedrooms}, Bathrooms: ${p.bathrooms}, '
        'Area: ${p.areaSqm.toStringAsFixed(0)} m\u00b2',
    'Rating: ${p.rating.toStringAsFixed(2)} from ${p.reviewCount} reviews'
        '${p.isSuperhost ? ', superhost' : ''}',
    'Host: ${p.hostName}',
    if (p.flatmates > 0) 'Flatmates: ${p.flatmates}',
    'Amenities: $amenities',
    'Description: ${p.description}',
  ].join('\n');
}

class _AskAiCard extends StatelessWidget {
  const _AskAiCard({required this.property});
  final Property property;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        showAssistant(
          context,
          subtitle: property.title,
          contextNote: _listingContext(property),
          suggestions: [
            context.copy(
              'Is this a fair price for the area?',
              'Le prix est-il correct pour le quartier ?',
            ),
            context.copy(
              'What should I ask the host?',
              'Que dois-je demander à l\'hôte ?',
            ),
            context.copy(
              'Give me the pros and cons',
              'Donne-moi les avantages et inconvénients',
            ),
          ],
        );
      },
      child: NeuSurface(
        borderRadius: AppRadius.md,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.ink, AppColors.inkSoft],
                ),
              ),
              child: const Icon(
                AppIcons.assistant,
                color: AppColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.copy(
                      'Ask Nesty AI about this place',
                      'Demander à l\'IA Nesty sur ce logement',
                    ),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.copy(
                      'Deal check, what to ask the host, pros & cons…',
                      'Bon plan, questions à l\'hôte, avantages & inconvénients…',
                    ),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(AppIcons.chevronRight, color: AppColors.tertiaryLabel),
          ],
        ),
      ),
    );
  }
}

class _HostRow extends StatelessWidget {
  const _HostRow({required this.hostName, required this.type});
  final String hostName;
  final ListingType type;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        NeuSurface(
          borderRadius: AppRadius.pill,
          depth: 5,
          padding: const EdgeInsets.all(14),
          child: const Icon(AppIcons.profile, color: AppColors.textPrimary),
        ),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.copy('Hosted by $hostName', 'Proposé par $hostName'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text(
              type.label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.property});
  final Property property;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(
          top: BorderSide(color: AppColors.separator, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            offset: const Offset(0, -10),
            blurRadius: 30,
            spreadRadius: -8,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.lg,
        AppSpacing.gutter,
        bottomInset + AppSpacing.lg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        formatDinars(property.displayPrice),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '/ ${property.displayPricingModel.unitFor(context.isFrench)}',
                      style: const TextStyle(
                        color: AppColors.secondaryLabel,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  context.copy(
                    'Free to request · you pick the dates',
                    'Demande gratuite · vous choisissez les dates',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.secondaryLabel,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          NeuButton(
            label: context.copy('Reserve', 'Réserver'),
            icon: AppIcons.calendar,
            expand: false,
            onPressed: () => _reserve(context),
          ),
        ],
      ),
    );
  }

  Future<void> _reserve(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final created = await startReservationFlow(context, property);
    if (created && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.copy(
            'Request sent — track it in Trips.',
            'Demande envoyée — suivez-la dans Voyages.',
          )),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
