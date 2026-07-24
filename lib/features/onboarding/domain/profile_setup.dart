import 'package:flutter/widgets.dart';

import '../../../../core/branding/app_icons.dart';

/// The answers we collect from a member right after their first sign-up, so the
/// app can tailor discovery from day one. Kept deliberately light — a couple of
/// taps — and stored on the profile (see [ProfileSetupStore]).
@immutable
class ProfileSetup {
  const ProfileSetup({
    this.country,
    this.city,
    this.purpose,
    this.household,
    this.budget,
    this.regions = const [],
    this.completed = false,
  });

  /// Where the member is joining from (a TRE in Paris, a tourist in Lyon, a
  /// local in Tunis …). Powers currency hints and diaspora-aware messaging.
  final String? country;

  /// The city they're based in.
  final String? city;

  /// What brings them to Nesty — see [SetupOption] catalogs below.
  final String? purpose;

  /// Who usually travels/lives with them.
  final String? household;

  /// Their budget band.
  final String? budget;

  /// Tunisian regions they're most interested in.
  final List<String> regions;

  /// True once they've finished (or skipped) the questions.
  final bool completed;

  ProfileSetup copyWith({
    String? country,
    String? city,
    String? purpose,
    String? household,
    String? budget,
    List<String>? regions,
    bool? completed,
  }) {
    return ProfileSetup(
      country: country ?? this.country,
      city: city ?? this.city,
      purpose: purpose ?? this.purpose,
      household: household ?? this.household,
      budget: budget ?? this.budget,
      regions: regions ?? this.regions,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toMap() => {
    'country': country,
    'city': city,
    'purpose': purpose,
    'household': household,
    'budget': budget,
    'regions': regions,
    'completed': completed,
  };

  factory ProfileSetup.fromMap(Map<String, dynamic> map) => ProfileSetup(
    country: map['country'] as String?,
    city: map['city'] as String?,
    purpose: map['purpose'] as String?,
    household: map['household'] as String?,
    budget: map['budget'] as String?,
    regions:
        (map['regions'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    completed: map['completed'] == true,
  );
}

/// A single selectable answer with a stable [id] (stored) and localized labels.
class SetupOption {
  const SetupOption(this.id, this.en, this.fr, {this.icon});
  final String id;
  final String en;
  final String fr;
  final IconData? icon;

  String label(bool french) => french ? fr : en;
}

/// Static catalogs for the setup questions. IDs are language-independent so the
/// stored answer stays stable across locales.
abstract final class SetupCatalog {
  static const countries = [
    SetupOption('tunisia', 'Tunisia', 'Tunisie'),
    SetupOption('france', 'France', 'France'),
    SetupOption('germany', 'Germany', 'Allemagne'),
    SetupOption('italy', 'Italy', 'Italie'),
    SetupOption('belgium', 'Belgium', 'Belgique'),
    SetupOption('canada', 'Canada', 'Canada'),
    SetupOption('algeria', 'Algeria', 'Algérie'),
    SetupOption('other', 'Elsewhere', 'Ailleurs'),
  ];

  static const purposes = [
    SetupOption(
      'long_term',
      'Rent a home to live in',
      'Louer un logement à l\'année',
      icon: AppIcons.home,
    ),
    SetupOption(
      'seasonal',
      'Book a seasonal stay',
      'Réserver un séjour saisonnier',
      icon: AppIcons.trips,
    ),
    SetupOption(
      'colocation',
      'Find a colocation',
      'Trouver une colocation',
      icon: AppIcons.guests,
    ),
    SetupOption(
      'exploring',
      'Just exploring for now',
      'Je regarde pour l\'instant',
      icon: AppIcons.explore,
    ),
  ];

  static const households = [
    SetupOption('solo', 'Just me', 'Moi seul(e)', icon: AppIcons.profile),
    SetupOption('couple', 'A couple', 'En couple', icon: AppIcons.guests),
    SetupOption(
      'family',
      'Family with kids',
      'Famille avec enfants',
      icon: AppIcons.guests,
    ),
    SetupOption(
      'group',
      'A group of friends',
      'Un groupe d\'amis',
      icon: AppIcons.guests,
    ),
  ];

  static const budgets = [
    SetupOption('lt500', 'Under 500 DT', 'Moins de 500 DT'),
    SetupOption('500_1000', '500 – 1000 DT', '500 – 1000 DT'),
    SetupOption('1000_2000', '1000 – 2000 DT', '1000 – 2000 DT'),
    SetupOption('gt2000', 'Over 2000 DT', 'Plus de 2000 DT'),
  ];

  static const regions = [
    SetupOption('hammamet', 'Hammamet', 'Hammamet'),
    SetupOption('sousse', 'Sousse', 'Sousse'),
    SetupOption('djerba', 'Djerba', 'Djerba'),
    SetupOption('tunis', 'Tunis', 'Tunis'),
    SetupOption('monastir', 'Monastir', 'Monastir'),
    SetupOption('sfax', 'Sfax', 'Sfax'),
    SetupOption('nabeul', 'Nabeul', 'Nabeul'),
    SetupOption('bizerte', 'Bizerte', 'Bizerte'),
  ];
}
