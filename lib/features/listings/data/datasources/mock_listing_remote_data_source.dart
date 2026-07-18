import '../../../../core/error/exceptions.dart';
import '../../domain/entities/property.dart';
import '../models/property_model.dart';
import 'listing_remote_data_source.dart';
import 'local_listings_store.dart';

/// A curated in-memory catalog used in demo mode. Every image is a stable
/// Unsplash URL, so the app looks and feels complete without any backend.
/// Listings the host publishes from inside the app (via [LocalListingsStore])
/// are merged in on top, so a place you create shows up in the feed immediately.
class MockListingRemoteDataSource implements ListingRemoteDataSource {
  MockListingRemoteDataSource(this._local);

  final LocalListingsStore _local;

  List<PropertyModel> get _all => [
    ..._local.items.whereType<PropertyModel>(),
    ..._catalog,
  ];

  @override
  Future<List<PropertyModel>> getListings({String? category}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final all = _all;
    if (category == null || category == 'all') return all;
    return all.where((p) => p.type.name == category).toList();
  }

  @override
  Future<PropertyModel> getListingById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final match = _all.where((p) => p.id == id);
    if (match.isEmpty) throw const ServerException('Listing not found');
    return match.first;
  }

  static final List<PropertyModel> _catalog = [
    PropertyModel(
      id: '1',
      title: 'Bright T3 by Lac 2',
      city: 'Tunis, Les Berges du Lac',
      address: 'Rue du Lac Turkana, Les Berges du Lac 2, 1053',
      latitude: 36.8402,
      longitude: 10.2760,
      pricePerMonth: 1900,
      currency: 'TND',
      type: ListingType.entirePlace,
      bedrooms: 2,
      bathrooms: 1,
      areaSqm: 68,
      coverImage:
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=1200&q=80',
      gallery: const [
        'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=1200&q=80',
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200&q=80',
        'https://images.unsplash.com/photo-1484154218962-a197022b5858?w=1200&q=80',
      ],
      rating: 4.92,
      reviewCount: 128,
      hostName: 'Skander',
      description:
          'A calm, light-filled T3 in Les Berges du Lac, two minutes from '
          'Lac 2. Two real bedrooms, a proper dining nook and a bright '
          'kitchinette.',
      amenities: const ['Wi-Fi', 'Heating', 'Elevator', 'Washer', 'Balcony'],
      isSuperhost: true,
      availableFrom: 'Aug 1',
      billsIncluded: false,
      flatmates: 0,
    ),
    PropertyModel(
      id: '2',
      title: 'Sunny room in a friendly coloc',
      city: 'Sousse, Sahloul',
      address: 'Rue Yasser Arafat, Sahloul, 4054',
      latitude: 35.8385,
      longitude: 10.5967,
      pricePerMonth: 550,
      currency: 'TND',
      type: ListingType.sharedRoom,
      bedrooms: 1,
      bathrooms: 1,
      areaSqm: 16,
      coverImage:
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200&q=80',
      gallery: const [
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200&q=80',
        'https://images.unsplash.com/photo-1505691938895-1758d7feb511?w=1200&q=80',
      ],
      rating: 4.75,
      reviewCount: 64,
      hostName: 'Aymen',
      description:
          'A private room in a warm three-person coloc, right by Sahloul. '
          'You\u2019ll share a big kitchen and a water room with two friendly '
          'flatmates in their late twenties. Bills and Wi-Fi are all included.',
      amenities: const ['Wi-Fi', 'Heating', 'Shared kitchen', 'Bills included'],
      isSuperhost: false,
      availableFrom: 'Now',
      billsIncluded: true,
      flatmates: 2,
    ),
    PropertyModel(
      id: '3',
      title: 'Design studio with sea view',
      city: 'Sousse, Corniche',
      address: 'Boulevard de la Corniche, Sousse 4000',
      latitude: 35.8306,
      longitude: 10.6386,
      pricePerMonth: 820,
      currency: 'TND',
      type: ListingType.entirePlace,
      bedrooms: 1,
      bathrooms: 1,
      areaSqm: 34,
      coverImage:
          'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=1200&q=80',
      gallery: const [
        'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=1200&q=80',
        'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=1200&q=80',
      ],
      rating: 4.88,
      reviewCount: 91,
      hostName: 'Nour',
      description:
          'A compact, beautifully designed studio overlooking the Sousse '
          'Corniche and the sea. Thoughtful storage, a real desk and a calm '
          'palette \u2014 ideal for a professional or a student who wants to '
          'live well in a small footprint.',
      amenities: const ['Wi-Fi', 'Heating', 'Kitchenette', 'Desk'],
      isSuperhost: true,
      availableFrom: 'Sep 15',
      billsIncluded: false,
      flatmates: 0,
    ),
  ];
}
