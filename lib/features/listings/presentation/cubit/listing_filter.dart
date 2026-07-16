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
