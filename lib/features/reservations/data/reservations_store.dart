import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/local_store.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/entities/reservation.dart';

/// Reactive store for reservations (visits & stays). When Supabase is
/// configured it is the source of truth — the seeker's booking on mobile and
/// the agency's actions on the web dashboard read and write the same rows (RLS
/// scopes each user to their own). In demo mode it falls back to on-device
/// [LocalStore] so the experience still works with no backend.
class ReservationsStore extends ChangeNotifier {
  ReservationsStore() {
    if (!_remote) _loadLocal();
  }

  static const _key = 'reservations';

  final List<Reservation> _items = [];

  bool get _remote => SupabaseService.isReady;
  SupabaseClient get _client => SupabaseService.client;

  // ---------------------------------------------------------------- loading --
  void _loadLocal() {
    _items
      ..clear()
      ..addAll(LocalStore.instance.getJsonList(_key).map(Reservation.fromMap));
    _sort();
  }

  /// Loads reservations for the signed-in user from Supabase (RLS returns the
  /// rows where they are the guest or the host). Falls back to local storage in
  /// demo mode. Safe to call repeatedly.
  Future<void> load() async {
    if (!_remote) {
      _loadLocal();
      notifyListeners();
      return;
    }
    try {
      final rows = await _client
          .from('reservations')
          .select('*, listings(title, city)')
          .order('start_at');
      _items
        ..clear()
        ..addAll((rows as List).map((e) => _fromRow(e as Map<String, dynamic>)));
      _sort();
    } catch (_) {
      // Keep whatever we have; screens show graceful empty states.
    }
    notifyListeners();
  }

  Reservation _fromRow(Map<String, dynamic> row) {
    final listing = row['listings'] as Map<String, dynamic>?;
    return Reservation(
      id: row['id'].toString(),
      propertyId: row['listing_id']?.toString() ?? '',
      propertyTitle: (listing?['title'] as String?) ?? 'Listing',
      propertyCity: (listing?['city'] as String?) ?? '',
      guestId: (row['guest_id'] as String?) ?? '',
      guestName: (row['guest_name'] as String?) ?? 'Guest',
      type: ReservationTypeX.fromId(row['type'] as String?),
      start: DateTime.parse(row['start_at'] as String),
      end: row['end_at'] == null
          ? null
          : DateTime.parse(row['end_at'] as String),
      guests: (row['guests'] as num?)?.toInt() ?? 1,
      status: ReservationStatusX.fromId(row['status'] as String?),
      note: row['note'] as String?,
      estimatedTotal: (row['estimated_total'] as num?)?.toDouble(),
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  void _sort() => _items.sort((a, b) => a.start.compareTo(b.start));

  // ---------------------------------------------------------------- getters --
  /// All reservations, ordered by date.
  List<Reservation> get all => List.unmodifiable(_items);

  /// Reservations made by a specific guest (the seeker's own trips).
  List<Reservation> forGuest(String guestId) =>
      _items.where((r) => r.guestId == guestId).toList();

  /// Active, upcoming reservations ordered by soonest first.
  List<Reservation> get upcoming =>
      _items.where((r) => r.status.isActive && r.isUpcoming).toList();

  /// Reservations that fall on a given calendar day.
  List<Reservation> onDay(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    return _items
        .where(
          (r) =>
              r.status != ReservationStatus.cancelled &&
              r.occupiedDays.any((d) => d == target),
        )
        .toList();
  }

  /// The set of days in a month that carry at least one active reservation.
  Set<DateTime> markedDays(int year, int month) {
    final marked = <DateTime>{};
    for (final r in _items) {
      if (r.status == ReservationStatus.cancelled) continue;
      for (final d in r.occupiedDays) {
        if (d.year == year && d.month == month) marked.add(d);
      }
    }
    return marked;
  }

  int get pendingCount =>
      _items.where((r) => r.status == ReservationStatus.pending).length;

  // -------------------------------------------------------------- mutations --
  /// Creates a reservation. Returns `null` on success, or a human-friendly
  /// error message the UI can surface when the request could not be sent.
  Future<String?> add(Reservation reservation) async {
    if (_remote) {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        return 'Please sign in to send a request.';
      }
      try {
        await _client.from('reservations').insert({
          'listing_id': reservation.propertyId,
          'guest_id': uid,
          'guest_name': reservation.guestName,
          'type': reservation.type.id,
          'start_at': reservation.start.toIso8601String(),
          'end_at': reservation.end?.toIso8601String(),
          'guests': reservation.guests,
          'note': reservation.note,
          'estimated_total': reservation.estimatedTotal,
        });
        await load();
        return null;
      } on PostgrestException catch (e) {
        return e.message;
      } catch (_) {
        return 'We couldn\'t send your request. Check your connection and try again.';
      }
    }
    _items.add(reservation);
    _sort();
    await _persist();
    notifyListeners();
    return null;
  }

  Future<void> setStatus(String id, ReservationStatus status) async {
    if (_remote) {
      try {
        await _client
            .from('reservations')
            .update({'status': status.id})
            .eq('id', id);
        await load();
      } catch (_) {}
      return;
    }
    final index = _items.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _items[index] = _items[index].copyWith(status: status);
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    if (_remote) {
      try {
        await _client.from('reservations').delete().eq('id', id);
        await load();
      } catch (_) {}
      return;
    }
    _items.removeWhere((r) => r.id == id);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() => LocalStore.instance.setJsonList(
    _key,
    _items.map((r) => r.toMap()).toList(),
  );
}
