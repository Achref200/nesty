/// What a single day on a listing's calendar is doing.
///
/// The order matters: when a reservation and a manual block land on the same
/// day, the higher [rank] wins. That's the same precedence the dashboard uses,
/// so the two calendars can never disagree about a day's colour.
enum DayAvailability { available, pending, blocked, confirmed }

extension DayAvailabilityX on DayAvailability {
  int get rank => switch (this) {
    DayAvailability.available => 0,
    DayAvailability.pending => 1,
    DayAvailability.blocked => 2,
    DayAvailability.confirmed => 3,
  };

  /// Can a traveller still ask for this day?
  bool get isBookable => this == DayAvailability.available;

  String labelFor(bool french) => switch (this) {
    DayAvailability.available => french ? 'Disponible' : 'Available',
    DayAvailability.pending => french ? 'En attente' : 'On hold',
    DayAvailability.blocked => french ? 'Bloquée' : 'Blocked',
    DayAvailability.confirmed => french ? 'Réservée' : 'Booked',
  };
}

/// A period the agency closed off by hand — maintenance, an owner stay, a
/// booking taken over the phone. Mirrors `public.availability_blocks`, whose
/// end date is exclusive so back-to-back blocks don't fight over a day.
class AvailabilityBlock {
  const AvailabilityBlock({
    required this.id,
    required this.listingId,
    required this.start,
    required this.end,
    this.reason,
  });

  final String id;
  final String listingId;
  final DateTime start;

  /// Exclusive — the listing is free again on this date.
  final DateTime end;
  final String? reason;

  /// Every day this block covers, check-out day excluded.
  List<DateTime> get days {
    final first = DateTime(start.year, start.month, start.day);
    final stop = DateTime(end.year, end.month, end.day);
    final out = <DateTime>[];
    for (
      var d = first;
      d.isBefore(stop.isAfter(first) ? stop : first.add(const Duration(days: 1)));
      d = d.add(const Duration(days: 1))
    ) {
      out.add(DateTime(d.year, d.month, d.day));
    }
    return out.isEmpty ? [first] : out;
  }

  factory AvailabilityBlock.fromRow(Map<String, dynamic> row) {
    final start =
        DateTime.tryParse(row['start_date'] as String? ?? '') ?? DateTime.now();
    final end =
        DateTime.tryParse(row['end_date'] as String? ?? '') ??
        start.add(const Duration(days: 1));
    return AvailabilityBlock(
      id: row['id'].toString(),
      listingId: row['listing_id']?.toString() ?? '',
      start: start,
      end: end,
      reason: row['reason'] as String?,
    );
  }
}
