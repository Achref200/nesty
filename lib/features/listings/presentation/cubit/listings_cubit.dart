import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/property.dart';
import '../../domain/usecases/get_listings.dart';
import 'listing_filter.dart';

part 'listings_state.dart';

/// Drives the home feed: loads listings, then filters/sorts them by category,
/// rental term, audience, price and proximity — all on the same source so the
/// mobile experience stays in sync with the web catalog.
class ListingsCubit extends Cubit<ListingsState> {
  ListingsCubit({required GetListings getListings})
    : _getListings = getListings,
      super(const ListingsState());

  final GetListings _getListings;

  /// The unfiltered feed as loaded from the backend.
  List<Property> _raw = const [];
  Position? _position;

  Future<void> load({String category = 'all'}) async {
    emit(state.copyWith(status: ListingsStatus.loading, category: category));
    final result = await _getListings(GetListingsParams(category: category));
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: ListingsStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (properties) {
        _raw = properties;
        emit(
          state.copyWith(
            status: ListingsStatus.success,
            properties: _applyFilter(_raw, state.filter),
          ),
        );
      },
    );
  }

  Future<void> selectCategory(String category) => load(category: category);

  Future<void> refresh() => load(category: state.category);

  /// Distinct destinations (city label before the comma) from the real feed,
  /// most common first — powers the search sheet's suggestions, no mock data.
  List<String> get destinations {
    final counts = <String, int>{};
    for (final p in _raw) {
      final city = p.city.split(',').first.trim();
      if (city.isEmpty) continue;
      counts[city] = (counts[city] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.map((e) => e.key).toList();
  }

  /// Applies the seeker's discovery filters. Best-effort resolves the device
  /// location when "nearest first" is on so the closest homes float up.
  Future<void> applyFilter(ListingFilter filter) async {
    if (filter.nearestFirst) {
      _position ??= await _lastKnownPosition();
    }
    emit(
      state.copyWith(
        filter: filter,
        properties: _applyFilter(_raw, filter),
      ),
    );
  }

  void clearFilter() => emit(
    state.copyWith(
      filter: ListingFilter.empty,
      properties: _applyFilter(_raw, ListingFilter.empty),
    ),
  );

  List<Property> _applyFilter(List<Property> source, ListingFilter filter) {
    final city = filter.city?.trim().toLowerCase();
    final list = source.where((p) {
      if (city != null && city.isNotEmpty) {
        final hay = '${p.city} ${p.address}'.toLowerCase();
        if (!hay.contains(city)) return false;
      }
      if (filter.rentalTerm != null && p.rentalTerm != filter.rentalTerm) {
        return false;
      }
      if (filter.maxPrice != null && p.pricePerMonth > filter.maxPrice!) {
        return false;
      }
      if (filter.guests != null) {
        final capacity = (p.bedrooms < 1 ? 1 : p.bedrooms) * 2;
        if (capacity < filter.guests!) return false;
      }
      if (filter.audience.isNotEmpty &&
          !filter.audience.every((a) => p.audience.contains(a))) {
        return false;
      }
      return true;
    }).toList();

    if (filter.nearestFirst && _position != null) {
      final pos = _position!;
      list.sort((a, b) => _distance(pos, a).compareTo(_distance(pos, b)));
    }
    return list;
  }

  double _distance(Position from, Property p) {
    if (p.latitude == null || p.longitude == null) return double.maxFinite;
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      p.latitude!,
      p.longitude!,
    );
  }

  Future<Position?> _lastKnownPosition() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }
}
