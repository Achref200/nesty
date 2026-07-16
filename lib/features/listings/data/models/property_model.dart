import '../../domain/entities/property.dart';
import '../../domain/entities/property_room.dart';

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
    required super.rooms,
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
    super.tour3dUrl,
    super.isFavorite,
    super.isSuperhost,
    super.availableFrom,
    super.billsIncluded,
    super.flatmates,
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
      rooms: _roomsFrom(map['rooms']),
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
      tour3dUrl: map['tour_3d_url'] as String?,
      isSuperhost: (map['is_superhost'] as bool?) ?? false,
      availableFrom: map['available_from'] as String?,
      billsIncluded: (map['bills_included'] as bool?) ?? false,
      flatmates: (map['flatmates'] as num?)?.toInt() ?? 0,
    );
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

  static String _roomTypeToString(RoomType type) => switch (type) {
    RoomType.livingRoom => 'living_room',
    RoomType.kitchen => 'kitchen',
    RoomType.bathroom => 'bathroom',
    RoomType.diningRoom => 'dining_room',
    RoomType.bedroom => 'bedroom',
    RoomType.other => 'other',
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
    'rooms': rooms
        .map(
          (r) => {
            'id': r.id,
            'name': r.name,
            'type': _roomTypeToString(r.type),
            'images': r.images,
            'panorama_url': r.panoramaUrl,
          },
        )
        .toList(),
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
    'tour_3d_url': tour3dUrl,
    'is_superhost': isSuperhost,
    'available_from': availableFrom,
    'bills_included': billsIncluded,
    'flatmates': flatmates,
  };

  static List<String> _stringList(dynamic value) {
    if (value is List) return value.map((e) => e.toString()).toList();
    return const [];
  }

  static List<PropertyRoom> _roomsFrom(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) {
      final map = e as Map<String, dynamic>;
      return PropertyRoom(
        id: map['id'].toString(),
        name: map['name'] as String? ?? '',
        type: _roomTypeFromString(map['type'] as String?),
        images: _stringList(map['images']),
        panoramaUrl: map['panorama_url'] as String?,
      );
    }).toList();
  }

  static RoomType _roomTypeFromString(String? value) {
    return switch (value) {
      'living_room' => RoomType.livingRoom,
      'kitchen' => RoomType.kitchen,
      'bathroom' => RoomType.bathroom,
      'dining_room' => RoomType.diningRoom,
      'bedroom' => RoomType.bedroom,
      _ => RoomType.other,
    };
  }
}
