import '../../domain/entities/property.dart';

/// The seeker's discovery filters, applied on top of the loaded feed.
/// Modeled after the familiar Where / When / Who search, plus the Tunisian
/// long-vs-short term and who-it-suits dimensions.
class ListingFilter {
  const ListingFilter({
    this.city,
    this.rentalTerm,
    this.audience = const {},
    this.guests,
    this.maxPrice,
    this.nearestFirst = false,
    this.checkIn,
    this.checkOut,
  });

  /// Builds a starting filter from the member's onboarding answers so discovery
  /// opens already tuned to their preferences. Inputs are the stable
  /// profile-setup ids (see `SetupCatalog`); every one is optional. Kept
  /// deliberately gentle (budget, destination, term, capacity) so the default
  /// feed stays useful rather than over-filtered.
  factory ListingFilter.fromPreferences({
    String? region,
    String? budgetId,
    String? purposeId,
    String? householdId,
  }) {
    final term = switch (purposeId) {
      'long_term' => RentalTerm.longTerm,
      'seasonal' => RentalTerm.shortTerm,
      _ => null,
    };
    final maxPrice = switch (budgetId) {
      'lt500' => 500.0,
      '500_1000' => 1000.0,
      '1000_2000' => 2000.0,
      _ => null,
    };
    final guests = switch (householdId) {
      'couple' => 2,
      'family' => 4,
      'group' => 5,
      _ => null,
    };
    final city = (region != null && region.trim().isNotEmpty)
        ? region.trim()
        : null;
    return ListingFilter(
      city: city,
      rentalTerm: term,
      maxPrice: maxPrice,
      guests: guests,
    );
  }

  /// Destination / city text ("La Marsa", "Sousse"...). Null = anywhere.
  final String? city;

  /// Long-term (students/families) vs short-term (summer/vacation). Null = any.
  final RentalTerm? rentalTerm;

  /// Who it should suit: 'adults', 'children', 'baby', 'pets'.
  final Set<String> audience;

  /// Number of guests. Null = any.
  final int? guests;

  /// Only homes at or under this monthly price (TND). Null = no cap.
  final double? maxPrice;

  /// Sort the closest homes first (uses the device location when available).
  final bool nearestFirst;

  /// Optional stay window (biases toward short-term / vacation).
  final DateTime? checkIn;
  final DateTime? checkOut;

  static const empty = ListingFilter();

  bool get hasDates => checkIn != null && checkOut != null;

  bool get isActive =>
      (city != null && city!.isNotEmpty) ||
      rentalTerm != null ||
      audience.isNotEmpty ||
      guests != null ||
      maxPrice != null ||
      nearestFirst ||
      hasDates;

  int get activeCount =>
      ((city != null && city!.isNotEmpty) ? 1 : 0) +
      (rentalTerm != null ? 1 : 0) +
      (audience.isNotEmpty ? 1 : 0) +
      (guests != null ? 1 : 0) +
      (maxPrice != null ? 1 : 0) +
      (nearestFirst ? 1 : 0) +
      (hasDates ? 1 : 0);
}
