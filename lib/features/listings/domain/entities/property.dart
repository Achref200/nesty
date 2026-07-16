import 'package:equatable/equatable.dart';

import 'property_room.dart';

/// A property/colocation listing.
enum ListingType { entirePlace, privateRoom, sharedRoom }

extension ListingTypeX on ListingType {
  String get label => switch (this) {
    ListingType.entirePlace => 'Entire place',
    ListingType.privateRoom => 'Private room',
    ListingType.sharedRoom => 'Colocation',
  };
}

/// How long the place is offered for. Tunisia has two very different demands:
/// year-long homes for students & families, and short summer/vacation stays.
enum RentalTerm { shortTerm, longTerm }

extension RentalTermX on RentalTerm {
  String get id => switch (this) {
    RentalTerm.shortTerm => 'short_term',
    RentalTerm.longTerm => 'long_term',
  };

  String get label => switch (this) {
    RentalTerm.shortTerm => 'Short term',
    RentalTerm.longTerm => 'Long term',
  };

  String get blurb => switch (this) {
    RentalTerm.shortTerm => 'Summer & vacation stays',
    RentalTerm.longTerm => 'A year or more — students & families',
  };

  static RentalTerm fromId(String? value) => switch (value) {
    'short_term' => RentalTerm.shortTerm,
    _ => RentalTerm.longTerm,
  };
}

class Property extends Equatable {
  const Property({
    required this.id,
    required this.title,
    required this.city,
    required this.address,
    required this.pricePerMonth,
    required this.currency,
    required this.type,
    required this.bedrooms,
    required this.bathrooms,
    required this.areaSqm,
    required this.coverImage,
    required this.gallery,
    required this.rooms,
    required this.rating,
    required this.reviewCount,
    required this.hostName,
    required this.description,
    required this.amenities,
    this.rentalTerm = RentalTerm.longTerm,
    this.audience = const [],
    this.tags = const [],
    this.latitude,
    this.longitude,
    this.tour3dUrl,
    this.isFavorite = false,
    this.isSuperhost = false,
    this.availableFrom,
    this.billsIncluded = false,
    this.flatmates = 0,
  });

  final String id;
  final String title;
  final String city;
  final String address;
  final double pricePerMonth;
  final String currency;
  final ListingType type;
  final int bedrooms;
  final int bathrooms;
  final double areaSqm;
  final String coverImage;
  final List<String> gallery;
  final List<PropertyRoom> rooms;
  final double rating;
  final int reviewCount;
  final String hostName;
  final String description;
  final List<String> amenities;

  /// Offer length and who the place is suited for.
  final RentalTerm rentalTerm;

  /// Who the place suits, e.g. 'adults', 'children', 'baby', 'pets'.
  final List<String> audience;

  /// Free-form discovery tags, e.g. 'students', 'beach', 'furnished'.
  final List<String> tags;

  /// Optional map coordinates, used to surface the closest homes first.
  final double? latitude;
  final double? longitude;

  /// Pre-rendered 3D walkthrough video generated from the room photos.
  final String? tour3dUrl;
  final bool isFavorite;

  /// Realistic marketplace signals used across the UI.
  final bool isSuperhost;
  final String? availableFrom;
  final bool billsIncluded;
  final int flatmates;

  /// True when the place offers an immersive tour: a generated walkthrough, a
  /// 360° panorama, or enough room photos to orbit.
  bool get has3dTour =>
      tour3dUrl != null ||
      rooms.any((r) => r.canReconstruct || r.hasPanorama);

  Property copyWith({bool? isFavorite}) {
    return Property(
      id: id,
      title: title,
      city: city,
      address: address,
      pricePerMonth: pricePerMonth,
      currency: currency,
      type: type,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      areaSqm: areaSqm,
      coverImage: coverImage,
      gallery: gallery,
      rooms: rooms,
      rating: rating,
      reviewCount: reviewCount,
      hostName: hostName,
      description: description,
      amenities: amenities,
      rentalTerm: rentalTerm,
      audience: audience,
      tags: tags,
      latitude: latitude,
      longitude: longitude,
      tour3dUrl: tour3dUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      isSuperhost: isSuperhost,
      availableFrom: availableFrom,
      billsIncluded: billsIncluded,
      flatmates: flatmates,
    );
  }

  @override
  List<Object?> get props => [id, isFavorite];
}
