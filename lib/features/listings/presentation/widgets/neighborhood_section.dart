import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/property.dart';

/// "Where you'll be" — an interactive map that lets a seeker scout the exact
/// spot, the streets and what's around it, then jump into Google Maps or Street
/// View to virtually walk the neighbourhood, all from the exact location.
///
/// Uses OpenStreetMap tiles (no API key). When the listing has real
/// coordinates, a pin marks the exact place; otherwise a soft circle shows the
/// approximate area derived from the city, so privacy is preserved pre-booking.
class NeighborhoodSection extends StatelessWidget {
  const NeighborhoodSection({super.key, required this.property});

  final Property property;

  bool get _hasExact => property.latitude != null && property.longitude != null;

  LatLng get _center => _hasExact
      ? LatLng(property.latitude!, property.longitude!)
      : _cityCentroid(property.city);

  Future<void> _openMaps() async {
    final p = _center;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${p.latitude},${p.longitude}',
    );
    await _launch(uri);
  }

  Future<void> _openStreetView() async {
    final p = _center;
    final uri = Uri.parse(
      'https://www.google.com/maps/@?api=1&map_action=pano'
      '&viewpoint=${p.latitude},${p.longitude}',
    );
    await _launch(uri);
  }

  Future<void> _launch(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // If no maps app/browser can handle it, fail quietly.
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Where you'll be", style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.place_outlined,
              size: 15,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                property.city,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: _hasExact ? 15.5 : 13.5,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.nesty.app',
                    ),
                    if (_hasExact)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _center,
                            width: 46,
                            height: 46,
                            child: const _MapPin(),
                          ),
                        ],
                      )
                    else
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: _center,
                            radius: 280,
                            useRadiusInMeter: true,
                            color: AppColors.ink.withValues(alpha: 0.12),
                            borderColor: AppColors.ink.withValues(alpha: 0.5),
                            borderStrokeWidth: 1.5,
                          ),
                        ],
                      ),
                  ],
                ),
                // Attribution (OSM tiles require credit).
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    color: AppColors.white.withValues(alpha: 0.7),
                    child: const Text(
                      '© OpenStreetMap',
                      style: TextStyle(fontSize: 9, color: AppColors.ink),
                    ),
                  ),
                ),
                if (!_hasExact)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Approximate area',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _MapButton(
                icon: Icons.map_outlined,
                label: 'Open in Maps',
                onTap: _openMaps,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _MapButton(
                icon: Icons.streetview_rounded,
                label: 'Street View',
                onTap: _openStreetView,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.ink,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.fill,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.separator),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: AppColors.ink),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A rough city-centre lookup for Tunisian cities so listings without exact
/// coordinates still show a believable neighbourhood.
LatLng _cityCentroid(String city) {
  final c = city.toLowerCase();
  if (c.contains('lac')) return const LatLng(36.8402, 10.2760);
  if (c.contains('marsa')) return const LatLng(36.8783, 10.3247);
  if (c.contains('sahloul')) return const LatLng(35.8385, 10.5967);
  if (c.contains('corniche')) return const LatLng(35.8306, 10.6386);
  if (c.contains('sousse')) return const LatLng(35.8256, 10.6084);
  if (c.contains('hammamet')) return const LatLng(36.4000, 10.6167);
  if (c.contains('djerba')) return const LatLng(33.8076, 10.8451);
  if (c.contains('sfax')) return const LatLng(34.7406, 10.7603);
  if (c.contains('tunis')) return const LatLng(36.8065, 10.1815);
  return const LatLng(36.8065, 10.1815); // Tunis fallback
}
