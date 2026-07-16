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
class PropertyRoom extends Equatable {
  const PropertyRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.images,
    this.panoramaUrl,
  });

  final String id;
  final String name;
  final RoomType type;
  final List<String> images;

  /// Equirectangular 360° photo for the free-look panorama viewer.
  final String? panoramaUrl;

  /// Whether a true 360° panorama is available.
  bool get hasPanorama => panoramaUrl != null;

  /// Whether enough photos exist to attempt a 3D reconstruction / orbit.
  bool get canReconstruct => images.length >= 2;

  @override
  List<Object?> get props => [id, name, type, images, panoramaUrl];
}
