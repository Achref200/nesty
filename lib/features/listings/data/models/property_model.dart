import '../../domain/entities/listing_schema.dart';
import '../../domain/entities/property.dart';

/// Data-layer model for [Property] with Supabase (de)serialization.
class PropertyModel extends Property {
  const PropertyModel({
    required super.id,
    required super.title,
    required super.city,
    required super.address,
    required super.pricePerMonth,
    required super.currency,
    required super.type,
    required super.bedrooms,
    required super.bathrooms,
    required super.areaSqm,
    required super.coverImage,
    required super.gallery,
    required super.rating,
    required super.reviewCount,
    required super.hostName,
    required super.description,
    required super.amenities,
    super.rentalTerm,
    super.audience,
    super.tags,
    super.latitude,
    super.longitude,
    super.isFavorite,
    super.isSuperhost,
    super.availableFrom,
    super.billsIncluded,
    super.flatmates,
    super.status,
    super.propertyType,
    super.maxGuests,
    super.district,
    super.contactPhone,
    super.rules,
    super.pricing,
    super.conditions,
  });

  factory PropertyModel.fromMap(Map<String, dynamic> map) {
    return PropertyModel(
      id: map['id'].toString(),
      title: map['title'] as String? ?? '',
      city: map['city'] as String? ?? '',
      address: map['address'] as String? ?? '',
      pricePerMonth: (map['price_per_month'] as num?)?.toDouble() ?? 0,
      currency: map['currency'] as String? ?? 'EUR',
      type: _typeFromString(map['type'] as String?),
      bedrooms: (map['bedrooms'] as num?)?.toInt() ?? 0,
      bathrooms: (map['bathrooms'] as num?)?.toInt() ?? 0,
      areaSqm: (map['area_sqm'] as num?)?.toDouble() ?? 0,
      coverImage: map['cover_image'] as String? ?? '',
      gallery: _stringList(map['gallery']),
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (map['review_count'] as num?)?.toInt() ?? 0,
      hostName: map['host_name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      amenities: _stringList(map['amenities']),
      rentalTerm: RentalTermX.fromId(map['rental_term'] as String?),
      audience: _stringList(map['audience']),
      tags: _stringList(map['tags']),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isSuperhost: (map['is_superhost'] as bool?) ?? false,
      availableFrom: map['available_from'] as String?,
      billsIncluded: (map['bills_included'] as bool?) ?? false,
      flatmates: (map['flatmates'] as num?)?.toInt() ?? 0,
      status: ListingStatusX.fromId(map['status'] as String?),
      propertyType: PropertyTypeX.fromId(map['property_type'] as String?),
      maxGuests: (map['max_guests'] as num?)?.toInt() ?? 0,
      district: map['district'] as String?,
      contactPhone: map['contact_phone'] as String?,
      rules: HouseRules.fromMap(_jsonMap(map['house_rules'])),
      pricing: ListingPricing.fromMap(_jsonMap(map['pricing'])),
      conditions: BookingConditions.fromMap(
        _jsonMap(map['booking_conditions']),
      ),
    );
  }

  /// The three wizard columns are `jsonb`. Supabase hands them back as maps,
  /// but a row written before the lifecycle migration has `{}` or no key at
  /// all, so anything that isn't a map becomes null and the value objects fall
  /// back to their defaults.
  static Map<String, dynamic>? _jsonMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
    return null;
  }

  static ListingType _typeFromString(String? value) {
    return switch (value) {
      'private_room' => ListingType.privateRoom,
      'shared_room' => ListingType.sharedRoom,
      _ => ListingType.entirePlace,
    };
  }

  static String _typeToString(ListingType type) => switch (type) {
    ListingType.privateRoom => 'private_room',
    ListingType.sharedRoom => 'shared_room',
    ListingType.entirePlace => 'entire_place',
  };

  /// Serializes to the same snake_case shape [fromMap] reads, so local
  /// persistence round-trips cleanly.
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'city': city,
    'address': address,
    'price_per_month': pricePerMonth,
    'currency': currency,
    'type': _typeToString(type),
    'bedrooms': bedrooms,
    'bathrooms': bathrooms,
    'area_sqm': areaSqm,
    'cover_image': coverImage,
    'gallery': gallery,
    'rating': rating,
    'review_count': reviewCount,
    'host_name': hostName,
    'description': description,
    'amenities': amenities,
    'rental_term': rentalTerm.id,
    'audience': audience,
    'tags': tags,
    'latitude': latitude,
    'longitude': longitude,
    'is_superhost': isSuperhost,
    'available_from': availableFrom,
    'bills_included': billsIncluded,
    'flatmates': flatmates,
    'status': status.id,
    'property_type': propertyType.id,
    'max_guests': maxGuests,
    'district': district,
    'contact_phone': contactPhone,
    'house_rules': rules.toMap(),
    'pricing': pricing.toMap(),
    'booking_conditions': conditions.toMap(),
  };

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }
}
