import '../../../../core/error/exceptions.dart';
import '../../domain/entities/property.dart';
import '../../domain/entities/property_room.dart';
import '../models/property_model.dart';
import 'listing_remote_data_source.dart';
import 'local_listings_store.dart';

/// A curated in-memory catalog used in demo mode. Every image is a stable
/// Unsplash URL and the 3D tour points at a public sample video, so the app
/// looks and feels complete without any backend. Listings the host publishes
/// from inside the app (via [LocalListingsStore]) are merged in on top, so a
/// place you create shows up in the feed immediately.
class MockListingRemoteDataSource implements ListingRemoteDataSource {
  MockListingRemoteDataSource(this._local);

  final LocalListingsStore _local;

  static const _sampleTour =
      'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';

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
      title: 'Bright T3 with 3D tour',
      city: 'Tunis, Les Berges du Lac',
      address: 'Rue du Lac Turkana, Les Berges du Lac 2, 1053',
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
      rooms: const [
        PropertyRoom(
          id: '1-r1',
          name: 'Chambre 1',
          type: RoomType.bedroom,
          images: [
            'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=1000&q=80',
            'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?w=1000&q=80',
            'https://images.unsplash.com/photo-1560185007-cde436f6a4d0?w=1000&q=80',
          ],
          panoramaUrl:
              'https://photo-sphere-viewer-data.netlify.app/assets/sphere.jpg',
        ),
        PropertyRoom(
          id: '1-r2',
          name: 'Chambre 2',
          type: RoomType.bedroom,
          images: [
            'https://images.unsplash.com/photo-1616594039964-ae9021a400a0?w=1000&q=80',
            'https://images.unsplash.com/photo-1617104666213-4b8b6c9fa9f0?w=1000&q=80',
            'https://images.unsplash.com/photo-1560448204-603b3fc33ddc?w=1000&q=80',
          ],
        ),
        PropertyRoom(
          id: '1-r3',
          name: 'Salle à manger',
          type: RoomType.diningRoom,
          images: [
            'https://images.unsplash.com/photo-1615529182904-14819c35db37?w=1000&q=80',
            'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1000&q=80',
            'https://images.unsplash.com/photo-1600566753086-00f18fb6b3ea?w=1000&q=80',
          ],
          panoramaUrl:
              'https://cdn.aframe.io/360-image-gallery-boilerplate/img/city.jpg',
        ),
        PropertyRoom(
          id: '1-r4',
          name: 'Kitchinette',
          type: RoomType.kitchen,
          images: [
            'https://images.unsplash.com/photo-1556911220-bff31c812dba?w=1000&q=80',
            'https://images.unsplash.com/photo-1600489000022-c2086d79f9d4?w=1000&q=80',
          ],
        ),
        PropertyRoom(
          id: '1-r5',
          name: "Salle d'eau",
          type: RoomType.bathroom,
          images: [
            'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=1000&q=80',
            'https://images.unsplash.com/photo-1620626011761-996317b8d101?w=1000&q=80',
          ],
        ),
      ],
      rating: 4.92,
      reviewCount: 128,
      hostName: 'Skander',
      description:
          'A calm, light-filled T3 in Les Berges du Lac, two minutes from '
          'Lac 2. Two real bedrooms, a proper dining nook and a bright '
          'kitchinette. Every room was scanned into a 3D tour, so you can walk '
          'the whole place tonight and only visit once you\u2019re sure.',
      amenities: const ['Wi-Fi', 'Heating', 'Elevator', 'Washer', 'Balcony'],
      tour3dUrl: _sampleTour,
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
      rooms: const [
        PropertyRoom(
          id: '2-r1',
          name: 'Chambre privée',
          type: RoomType.bedroom,
          images: [
            'https://images.unsplash.com/photo-1505691938895-1758d7feb511?w=1000&q=80',
            'https://images.unsplash.com/photo-1560185009-dddeb820c7b7?w=1000&q=80',
            'https://images.unsplash.com/photo-1560185127-6ed189bf02f4?w=1000&q=80',
          ],
          panoramaUrl:
              'https://cdn.aframe.io/360-image-gallery-boilerplate/img/cubes.jpg',
        ),
        PropertyRoom(
          id: '2-r2',
          name: "Salle d'eau partagée",
          type: RoomType.bathroom,
          images: [
            'https://images.unsplash.com/photo-1552321554-5fefe8c9ef14?w=1000&q=80',
          ],
        ),
      ],
      rating: 4.75,
      reviewCount: 64,
      hostName: 'Aymen',
      description:
          'A private room in a warm three-person coloc, right by Sahloul. '
          'You\u2019ll share a big kitchen and a water room with two friendly '
          'flatmates in their late twenties. Bills and Wi-Fi are all included.',
      amenities: const ['Wi-Fi', 'Heating', 'Shared kitchen', 'Bills included'],
      tour3dUrl: _sampleTour,
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
      rooms: const [
        PropertyRoom(
          id: '3-r1',
          name: 'Pièce de vie',
          type: RoomType.livingRoom,
          images: [
            'https://images.unsplash.com/photo-1493809842364-78817add7ffb?w=1000&q=80',
            'https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=1000&q=80',
            'https://images.unsplash.com/photo-1567767292278-a4f21aa2d36e?w=1000&q=80',
          ],
          panoramaUrl:
              'https://cdn.aframe.io/360-image-gallery-boilerplate/img/sechelt.jpg',
        ),
        PropertyRoom(
          id: '3-r2',
          name: 'Kitchinette',
          type: RoomType.kitchen,
          images: [
            'https://images.unsplash.com/photo-1600489000022-c2086d79f9d4?w=1000&q=80',
            'https://images.unsplash.com/photo-1556909212-d5b604d0c90d?w=1000&q=80',
          ],
        ),
      ],
      rating: 4.88,
      reviewCount: 91,
      hostName: 'Nour',
      description:
          'A compact, beautifully designed studio overlooking the Sousse '
          'Corniche and the sea. Thoughtful storage, a real desk and a calm palette \u2014 '
          'ideal for a professional or a student who wants to live well in a '
          'small footprint.',
      amenities: const ['Wi-Fi', 'Heating', 'Kitchenette', 'Desk'],
      tour3dUrl: _sampleTour,
      isSuperhost: true,
      availableFrom: 'Sep 15',
      billsIncluded: false,
      flatmates: 0,
    ),
  ];
}
