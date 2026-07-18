import 'package:equatable/equatable.dart';

/// The kind of room inside a property. Used both for display and to drive the
/// 3D reconstruction pipeline (each room is rebuilt from its own photos).
enum RoomType { bedroom, livingRoom, kitchen, bathroom, diningRoom, other }

extension RoomTypeX on RoomType {
  String get label => switch (this) {
    RoomType.bedroom => 'Chambre',
    RoomType.livingRoom => 'Salon',
    RoomType.kitchen => 'Kitchinette',
    RoomType.bathroom => "Salle d'eau",
    RoomType.diningRoom => 'Salle à manger',
    RoomType.other => 'Pièce',
  };
}

/// A single room described by the photos a host uploaded. The 3D engine turns
/// [images] into a navigable reconstruction. When a real equirectangular
/// capture exists, [panoramaUrl] powers a true look-around 360° / VR view.
///
/// [links] connect this room to others through doorways, which is what makes
/// the tour a *walk*: standing in a room you can head through a door into the
/// connected room, choosing your direction — exactly like a Street-View /
/// Matterport virtual tour built from a home's own photos.
class PropertyRoom extends Equatable {
  const PropertyRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.images,
    this.panoramaUrl,
    this.links = const [],
  });

  final String id;
  final String name;
  final RoomType type;
  final List<String> images;

  /// Equirectangular 360° photo for the free-look panorama viewer.
  final String? panoramaUrl;

  /// Doorways from this room into others, for room-to-room walking.
  final List<RoomLink> links;

  /// Whether a 360° look-around is available for this room.
  bool get hasPanorama => panoramaUrl != null;

  /// Whether enough photos exist to attempt a 3D reconstruction / orbit.
  bool get canReconstruct => images.length >= 2;

  @override
  List<Object?> get props => [id, name, type, images, panoramaUrl, links];
}

/// Normalizes a stored panorama URL. Real 360° captures pass through; known
/// placeholder / outdoor sample panoramas (older seed data pointed rooms at an
/// outdoor "city" sample, and an earlier build swapped in a stand-in interior)
/// are dropped entirely — the room then falls back to its own photos, rendered
/// as a navigable 3D space, instead of an unrelated image.
String? sanitizePanorama(String? url) {
  if (url == null) return null;
  final u = url.toLowerCase();
  const placeholders = [
    'aframe.io/360-image-gallery',
    '/city.jpg',
    '/cubes.jpg',
    '/sechelt.jpg',
    'netlify.app/assets/sphere',
    'threejs.org/examples/textures',
  ];
  return placeholders.any(u.contains) ? null : url;
}

/// A doorway from one room into another. [target] is the index of the
/// destination room within the property's room list; [heading] is where the
/// door sits, in degrees (−180…180, 0 = straight ahead), so a 360° room can
/// place the doorway in the right direction.
class RoomLink extends Equatable {
  const RoomLink({required this.target, this.heading = 0, this.label});

  final int target;
  final double heading;
  final String? label;

  @override
  List<Object?> get props => [target, heading, label];
}
