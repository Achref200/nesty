/// The listing vocabulary shared with the agency dashboard.
///
/// Every value here mirrors `nesty-web/src/lib/listings/schema.ts` one-for-one.
/// Both apps write the same Supabase rows, so if the two lists drift a listing
/// created on one side renders half-empty on the other — that already happened
/// once with amenities, where mobile stored `'Wi-Fi'` and the web expected
/// `'wifi'`. Keep the ids below identical to the web file; the labels are ours
/// to translate.
library;

/// Where a listing sits in its lifecycle. Matches the `status` check constraint
/// added by `20260722130000_listing_lifecycle.sql`.
enum ListingStatus {
  draft,
  completed,
  submitted,
  pendingModeration,
  published,
  disabled,
  deleted,
}

extension ListingStatusX on ListingStatus {
  String get id => switch (this) {
    ListingStatus.pendingModeration => 'pending_moderation',
    _ => name,
  };

  String labelFor(bool french) => switch (this) {
    ListingStatus.draft => french ? 'Brouillon' : 'Draft',
    ListingStatus.completed => french ? 'Prêt à publier' : 'Ready to publish',
    ListingStatus.submitted => french ? 'Soumis' : 'Submitted',
    ListingStatus.pendingModeration => french ? 'En modération' : 'In review',
    ListingStatus.published => french ? 'En ligne' : 'Live',
    ListingStatus.disabled => french ? 'Désactivé' : 'Deactivated',
    ListingStatus.deleted => french ? 'Supprimé' : 'Deleted',
  };

  /// Only a listing still in preparation may be edited — the same rule the
  /// dashboard enforces in its `persist()` server action.
  bool get isEditable =>
      this == ListingStatus.draft || this == ListingStatus.completed;

  /// Visible to travellers. `active` is the pre-migration spelling of
  /// `published`; rows written before the lifecycle migration still carry it,
  /// so both have to count as live or the feed silently empties.
  bool get isLive => this == ListingStatus.published;

  static ListingStatus fromId(String? raw) => switch (raw) {
    'active' || 'published' => ListingStatus.published,
    'hidden' || 'disabled' => ListingStatus.disabled,
    'completed' => ListingStatus.completed,
    'submitted' => ListingStatus.submitted,
    'pending_moderation' => ListingStatus.pendingModeration,
    'deleted' => ListingStatus.deleted,
    _ => ListingStatus.draft,
  };
}

/// The status values a traveller-facing query must accept. Mirrors
/// `PUBLIC_VISIBLE_STATUSES` on the web.
const publicVisibleStatuses = <String>['published', 'active'];

/// The kind of building — distinct from `ListingType`, which describes how much
/// of it you rent (entire place / private room / colocation).
enum PropertyType { apartment, villa, house, studio, room, riad, other }

extension PropertyTypeX on PropertyType {
  String get id => name;

  String labelFor(bool french) => switch (this) {
    PropertyType.apartment => french ? 'Appartement' : 'Apartment',
    PropertyType.villa => 'Villa',
    PropertyType.house => french ? 'Maison' : 'House',
    PropertyType.studio => 'Studio',
    PropertyType.room => french ? 'Chambre' : 'Room',
    PropertyType.riad => 'Riad',
    PropertyType.other => french ? 'Autre' : 'Other',
  };

  static PropertyType fromId(String? raw) => PropertyType.values.firstWhere(
    (t) => t.name == raw,
    orElse: () => PropertyType.apartment,
  );
}

/// Canonical amenity ids. The order matches the dashboard's checklist so the
/// two screens read the same way.
const amenityIds = <String>[
  'wifi',
  'ac',
  'heating',
  'hotWater',
  'kitchen',
  'fridge',
  'washer',
  'tv',
  'parking',
  'pool',
  'balcony',
  'garden',
  'elevator',
  'babyBed',
  'workspace',
];

/// Preselected when a host starts a new listing — the basics almost every
/// Tunisian rental already has.
const defaultAmenityIds = <String>['wifi', 'hotWater', 'kitchen'];

String amenityLabel(String id, bool french) => switch (id) {
  'wifi' => 'Wi-Fi',
  'ac' => french ? 'Climatisation' : 'Air conditioning',
  'heating' => french ? 'Chauffage' : 'Heating',
  'hotWater' => french ? 'Eau chaude' : 'Hot water',
  'kitchen' => french ? 'Cuisine équipée' : 'Equipped kitchen',
  'fridge' => french ? 'Réfrigérateur' : 'Fridge',
  'washer' => french ? 'Machine à laver' : 'Washing machine',
  'tv' => french ? 'Télévision' : 'TV',
  'parking' => french ? 'Parking' : 'Parking',
  'pool' => french ? 'Piscine' : 'Pool',
  'balcony' => french ? 'Balcon / Terrasse' : 'Balcony / Terrace',
  'garden' => french ? 'Jardin' : 'Garden',
  'elevator' => french ? 'Ascenseur' : 'Elevator',
  'babyBed' => french ? 'Lit bébé' : 'Baby cot',
  'workspace' => french ? 'Espace de travail' : 'Workspace',
  _ => id,
};

/// Discovery tags. Same ids as the dashboard's tag picker.
const listingTagIds = <String>[
  'seaView',
  'beachfront',
  'cityCenter',
  'quietArea',
  'nearBeach',
  'nearShops',
  'luxury',
  'family',
  'romantic',
  'remoteWork',
  'nature',
  'authenticTunisian',
];

String listingTagLabel(String id, bool french) => switch (id) {
  'seaView' => french ? 'Vue mer' : 'Sea view',
  'beachfront' => french ? 'Bord de mer' : 'Beachfront',
  'cityCenter' => french ? 'Centre-ville' : 'City centre',
  'quietArea' => french ? 'Quartier calme' : 'Quiet area',
  'nearBeach' => french ? 'Proche plage' : 'Near the beach',
  'nearShops' => french ? 'Proche commerces' : 'Near shops',
  'luxury' => french ? 'Luxe' : 'Luxury',
  'family' => french ? 'Familial' : 'Family friendly',
  'romantic' => french ? 'Romantique' : 'Romantic',
  'remoteWork' => french ? 'Télétravail' : 'Remote work',
  'nature' => 'Nature',
  'authenticTunisian' => french ? 'Authentique tunisien' : 'Authentic Tunisian',
  _ => id,
};

enum PricingModel { night, week, month }

extension PricingModelX on PricingModel {
  String get id => name;

  String labelFor(bool french) => switch (this) {
    PricingModel.night => french ? 'Par nuit' : 'Per night',
    PricingModel.week => french ? 'Par semaine' : 'Per week',
    PricingModel.month => french ? 'Par mois' : 'Per month',
  };

  /// Short suffix for a price line, e.g. "180 TND / nuit".
  String unitFor(bool french) => switch (this) {
    PricingModel.night => french ? 'nuit' : 'night',
    PricingModel.week => french ? 'semaine' : 'week',
    PricingModel.month => french ? 'mois' : 'month',
  };

  static PricingModel fromId(String? raw) => switch (raw) {
    'week' => PricingModel.week,
    'month' => PricingModel.month,
    _ => PricingModel.night,
  };
}

enum PaymentMethod { cash, card, bankTransfer }

extension PaymentMethodX on PaymentMethod {
  String get id => name;

  String labelFor(bool french) => switch (this) {
    PaymentMethod.cash => french ? 'Espèces' : 'Cash',
    PaymentMethod.card => french ? 'Carte bancaire' : 'Card',
    PaymentMethod.bankTransfer => french ? 'Virement' : 'Bank transfer',
  };

  static PaymentMethod fromId(String? raw) => switch (raw) {
    'card' => PaymentMethod.card,
    'bankTransfer' => PaymentMethod.bankTransfer,
    _ => PaymentMethod.cash,
  };
}

enum PaymentPolicy { mandatoryAdvance, optionalAdvance }

extension PaymentPolicyX on PaymentPolicy {
  String get id => name;

  String labelFor(bool french) => switch (this) {
    PaymentPolicy.mandatoryAdvance =>
      french ? 'Avance obligatoire' : 'Advance required',
    PaymentPolicy.optionalAdvance =>
      french ? 'Avance optionnelle' : 'Advance optional',
  };

  static PaymentPolicy fromId(String? raw) => raw == 'mandatoryAdvance'
      ? PaymentPolicy.mandatoryAdvance
      : PaymentPolicy.optionalAdvance;
}

enum CancellationPolicy { flexible, moderate, strict }

extension CancellationPolicyX on CancellationPolicy {
  String get id => name;

  String labelFor(bool french) => switch (this) {
    CancellationPolicy.flexible => french ? 'Flexible' : 'Flexible',
    CancellationPolicy.moderate => french ? 'Modérée' : 'Moderate',
    CancellationPolicy.strict => french ? 'Stricte' : 'Strict',
  };

  String blurbFor(bool french) => switch (this) {
    CancellationPolicy.flexible => french
        ? 'Annulation gratuite jusqu\'à 24 h avant l\'arrivée.'
        : 'Free cancellation up to 24 h before check-in.',
    CancellationPolicy.moderate => french
        ? 'Annulation gratuite jusqu\'à 5 jours avant l\'arrivée.'
        : 'Free cancellation up to 5 days before check-in.',
    CancellationPolicy.strict => french
        ? 'Non remboursable après confirmation.'
        : 'Non-refundable once confirmed.',
  };

  static CancellationPolicy fromId(String? raw) => switch (raw) {
    'moderate' => CancellationPolicy.moderate,
    'strict' => CancellationPolicy.strict,
    _ => CancellationPolicy.flexible,
  };
}

/// Photo rules, identical to the dashboard wizard's step 2.
const photoMin = 5;
const photoMax = 30;

/// A listing has to sit inside Tunisia — the same bounding box the web uses to
/// validate the map pin.
const tunisiaMinLat = 30.2;
const tunisiaMaxLat = 37.7;
const tunisiaMinLng = 7.4;
const tunisiaMaxLng = 11.7;

bool isInTunisia(double lat, double lng) =>
    lat >= tunisiaMinLat &&
    lat <= tunisiaMaxLat &&
    lng >= tunisiaMinLng &&
    lng <= tunisiaMaxLng;

/// Eight local digits, optionally prefixed with +216.
bool isValidTunisianPhone(String raw) {
  final digits = raw.replaceAll(RegExp(r'[\s().-]'), '');
  return RegExp(r'^(\+?216)?\d{8}$').hasMatch(digits);
}

/// What guests may and may not do. Stored in the `house_rules` jsonb column.
class HouseRules {
  const HouseRules({
    this.pets = false,
    this.smoking = false,
    this.party = false,
    this.instructions = '',
  });

  final bool pets;
  final bool smoking;
  final bool party;
  final String instructions;

  HouseRules copyWith({
    bool? pets,
    bool? smoking,
    bool? party,
    String? instructions,
  }) => HouseRules(
    pets: pets ?? this.pets,
    smoking: smoking ?? this.smoking,
    party: party ?? this.party,
    instructions: instructions ?? this.instructions,
  );

  Map<String, dynamic> toMap() => {
    'pets': pets,
    'smoking': smoking,
    'party': party,
    'instructions': instructions,
  };

  factory HouseRules.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const HouseRules();
    return HouseRules(
      pets: map['pets'] as bool? ?? false,
      smoking: map['smoking'] as bool? ?? false,
      party: map['party'] as bool? ?? false,
      instructions: map['instructions'] as String? ?? '',
    );
  }
}

/// The `pricing` jsonb column. `amount` is in TND and always paired with
/// [model] — a bare number is meaningless without knowing the period.
class ListingPricing {
  const ListingPricing({
    this.model = PricingModel.night,
    this.amount = 0,
    this.minNights = 1,
    this.longStayDiscountPct = 0,
    this.extraFee = 0,
  });

  final PricingModel model;
  final double amount;
  final int minNights;
  final double longStayDiscountPct;
  final double extraFee;

  ListingPricing copyWith({
    PricingModel? model,
    double? amount,
    int? minNights,
    double? longStayDiscountPct,
    double? extraFee,
  }) => ListingPricing(
    model: model ?? this.model,
    amount: amount ?? this.amount,
    minNights: minNights ?? this.minNights,
    longStayDiscountPct: longStayDiscountPct ?? this.longStayDiscountPct,
    extraFee: extraFee ?? this.extraFee,
  );

  Map<String, dynamic> toMap() => {
    'model': model.id,
    'amount': amount,
    'minNights': minNights,
    'longStayDiscountPct': longStayDiscountPct,
    'extraFee': extraFee,
  };

  factory ListingPricing.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const ListingPricing();
    return ListingPricing(
      model: PricingModelX.fromId(map['model'] as String?),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      minNights: (map['minNights'] as num?)?.toInt() ?? 1,
      longStayDiscountPct:
          (map['longStayDiscountPct'] as num?)?.toDouble() ?? 0,
      extraFee: (map['extraFee'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// The `booking_conditions` jsonb column.
class BookingConditions {
  const BookingConditions({
    this.cancellation = CancellationPolicy.flexible,
    this.paymentMethods = const [PaymentMethod.cash],
    this.paymentPolicy = PaymentPolicy.optionalAdvance,
    this.advancePct = 0,
  });

  final CancellationPolicy cancellation;
  final List<PaymentMethod> paymentMethods;
  final PaymentPolicy paymentPolicy;
  final double advancePct;

  BookingConditions copyWith({
    CancellationPolicy? cancellation,
    List<PaymentMethod>? paymentMethods,
    PaymentPolicy? paymentPolicy,
    double? advancePct,
  }) => BookingConditions(
    cancellation: cancellation ?? this.cancellation,
    paymentMethods: paymentMethods ?? this.paymentMethods,
    paymentPolicy: paymentPolicy ?? this.paymentPolicy,
    advancePct: advancePct ?? this.advancePct,
  );

  Map<String, dynamic> toMap() => {
    'cancellation': cancellation.id,
    'paymentMethods': paymentMethods.map((m) => m.id).toList(),
    'paymentPolicy': paymentPolicy.id,
    'advancePct': advancePct,
  };

  factory BookingConditions.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const BookingConditions();
    final raw = map['paymentMethods'];
    final methods = raw is List
        ? raw.map((e) => PaymentMethodX.fromId(e.toString())).toList()
        : const [PaymentMethod.cash];
    return BookingConditions(
      cancellation: CancellationPolicyX.fromId(map['cancellation'] as String?),
      paymentMethods: methods.isEmpty ? const [PaymentMethod.cash] : methods,
      paymentPolicy: PaymentPolicyX.fromId(map['paymentPolicy'] as String?),
      advancePct: (map['advancePct'] as num?)?.toDouble() ?? 0,
    );
  }
}
