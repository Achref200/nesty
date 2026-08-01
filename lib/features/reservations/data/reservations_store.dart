import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/local_store.dart';
import '../../../core/services/supabase_service.dart';
import '../domain/entities/availability.dart';
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
  final List<AvailabilityBlock> _blocks = [];
  RealtimeChannel? _channel;

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
    await _loadBlocks();
    _subscribe();
    notifyListeners();
  }

  /// Live updates for rows this user can see. RLS already scopes the stream to
  /// the reservations they're the guest or the host of, so no filter is needed
  /// — and none would work anyway, since a seeker matches on `guest_id` while
  /// an agency matches on `host_id`.
  ///
  /// Any event just re-reads. The lists are small, a reload is one round-trip,
  /// and patching in place would have to replay the same soft-lock and
  /// ordering rules `load()` already applies.
  void _subscribe() {
    if (!_remote || _channel != null) return;
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    _channel = _client.channel('reservations:$uid')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'reservations',
        callback: (_) => _reload(),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'availability_blocks',
        callback: (_) => _reload(),
      )
      ..subscribe();
  }

  /// Refresh triggered by a realtime event rather than by a screen.
  Future<void> _reload() async {
    if (!_remote) return;
    try {
      final rows = await _client
          .from('reservations')
          .select('*, listings(title, city)')
          .order('start_at');
      _items
        ..clear()
        ..addAll((rows as List).map((e) => _fromRow(e as Map<String, dynamic>)));
      _sort();
      await _loadBlocks();
      notifyListeners();
    } catch (_) {
      // Transient — the next event or screen visit will pick it up.
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  /// Periods an agency has closed off by hand. The select policy is public, so
  /// a seeker can read them too and see the dates greyed out before asking.
  Future<void> _loadBlocks() async {
    if (!_remote) return;
    try {
      final rows = await _client
          .from('availability_blocks')
          .select('id, listing_id, start_date, end_date');
      _blocks
        ..clear()
        ..addAll(
          (rows as List).map(
            (e) => AvailabilityBlock.fromRow(e as Map<String, dynamic>),
          ),
        );
    } catch (_) {
      // The table arrives with the reservation module migration; before that
      // it simply doesn't exist and an empty block list is the right answer.
      _blocks.clear();
    }
  }

  /// Manual blocks for one listing.
  List<AvailabilityBlock> blocksFor(String listingId) =>
      _blocks.where((b) => b.listingId == listingId).toList();

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
      reference: row['reference'] as String?,
      expiresAt: DateTime.tryParse(row['expires_at'] as String? ?? ''),
      cancellationReason: row['cancellation_reason'] as String?,
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

  /// Reservations that fall on a given calendar day. Only the ones still
  /// holding the dates count — a declined, expired or cancelled request leaves
  /// the day free, which is exactly what the exclusion constraint does server
  /// side.
  List<Reservation> onDay(DateTime day) {
    final target = DateTime(day.year, day.month, day.day);
    return _items
        .where(
          (r) =>
              r.effectiveStatus.isActive &&
              r.occupiedDays.any((d) => d == target),
        )
        .toList();
  }

  /// The set of days in a month that carry at least one active reservation.
  Set<DateTime> markedDays(int year, int month) {
    final marked = <DateTime>{};
    for (final r in _items) {
      if (!r.effectiveStatus.isActive) continue;
      for (final d in r.occupiedDays) {
        if (d.year == year && d.month == month) marked.add(d);
      }
    }
    return marked;
  }

  /// Day-by-day availability for one listing, merging live reservations with
  /// the agency's manual blocks. Mirrors `computeCalendar` on the web, including
  /// its precedence rule: confirmed beats blocked beats pending.
  Map<DateTime, DayAvailability> calendarFor(String listingId) =>
      _calendar(listingId);

  /// The same read across every listing the signed-in user can see — what the
  /// host's month grid shows when it isn't scoped to one property.
  Map<DateTime, DayAvailability> calendarAcrossListings() => _calendar(null);

  Map<DateTime, DayAvailability> _calendar(String? listingId) {
    final map = <DateTime, DayAvailability>{};

    void mark(DateTime day, DayAvailability state) {
      final key = DateTime(day.year, day.month, day.day);
      final current = map[key];
      if (current == null || state.rank > current.rank) map[key] = state;
    }

    for (final r in _items) {
      if (listingId != null && r.propertyId != listingId) continue;
      final status = r.effectiveStatus;
      if (!status.isActive) continue;
      final state = status == ReservationStatus.confirmed
          ? DayAvailability.confirmed
          : DayAvailability.pending;
      for (final d in r.occupiedDays) {
        mark(d, state);
      }
    }

    for (final b in _blocks) {
      if (listingId != null && b.listingId != listingId) continue;
      for (final d in b.days) {
        mark(d, DayAvailability.blocked);
      }
    }

    return map;
  }

  /// Whether a traveller may request `[start, end)` on this listing. Checked
  /// before we hit the network so the seeker gets a sentence instead of a
  /// Postgres exclusion-constraint error.
  bool isRangeFree(String listingId, DateTime start, DateTime? end) {
    final calendar = calendarFor(listingId);
    final first = DateTime(start.year, start.month, start.day);
    final last = end == null
        ? first.add(const Duration(days: 1))
        : DateTime(end.year, end.month, end.day);
    final stop = last.isAfter(first) ? last : first.add(const Duration(days: 1));
    for (var d = first; d.isBefore(stop); d = d.add(const Duration(days: 1))) {
      final state = calendar[DateTime(d.year, d.month, d.day)];
      if (state != null && state != DayAvailability.available) return false;
    }
    return true;
  }

  int get pendingCount =>
      _items.where((r) => r.effectiveStatus == ReservationStatus.pending).length;

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

  /// Moves a reservation to [status]. [reason] is required whenever the agency
  /// turns a request down or cancels a confirmed stay — the dashboard enforces
  /// the same rule, and the traveller is shown whatever is written here.
  Future<void> setStatus(
    String id,
    ReservationStatus status, {
    String? reason,
  }) async {
    final trimmed = reason?.trim();
    if (_remote) {
      try {
        final patch = <String, dynamic>{'status': status.id};
        if (trimmed != null && trimmed.isNotEmpty) {
          patch['cancellation_reason'] = trimmed;
        }
        await _client.from('reservations').update(patch).eq('id', id);
        await load();
      } catch (_) {}
      return;
    }
    final index = _items.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _items[index] = _items[index].copyWith(
      status: status,
      cancellationReason: trimmed,
    );
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
