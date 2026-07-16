/// A reservation on a Nestly listing — either a **visit** (a scheduled
/// consultation/viewing at a single date & time) or a **stay** (a dated booking
/// with a check-in and check-out, for summer vacation rentals).
///
/// This is the backbone of the management side of the product: the calendar,
/// the host dashboard and the seeker's trips all read from reservations.
enum ReservationType { visit, stay }

extension ReservationTypeX on ReservationType {
  String get id => name;

  String get label => switch (this) {
    ReservationType.visit => 'Visit',
    ReservationType.stay => 'Stay',
  };

  String get verb => switch (this) {
    ReservationType.visit => 'Book a visit',
    ReservationType.stay => 'Reserve dates',
  };

  static ReservationType fromId(String? id) =>
      id == 'stay' ? ReservationType.stay : ReservationType.visit;
}

enum ReservationStatus { pending, confirmed, cancelled, completed }

extension ReservationStatusX on ReservationStatus {
  String get id => name;

  String get label => switch (this) {
    ReservationStatus.pending => 'Pending',
    ReservationStatus.confirmed => 'Confirmed',
    ReservationStatus.cancelled => 'Cancelled',
    ReservationStatus.completed => 'Completed',
  };

  bool get isActive =>
      this == ReservationStatus.pending || this == ReservationStatus.confirmed;

  static ReservationStatus fromId(String? id) => switch (id) {
    'confirmed' => ReservationStatus.confirmed,
    'cancelled' => ReservationStatus.cancelled,
    'completed' => ReservationStatus.completed,
    _ => ReservationStatus.pending,
  };
}

class Reservation {
  const Reservation({
    required this.id,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyCity,
    required this.guestId,
    required this.guestName,
    required this.type,
    required this.start,
    required this.createdAt,
    this.end,
    this.guests = 1,
    this.status = ReservationStatus.pending,
    this.note,
    this.estimatedTotal,
  });

  final String id;
  final String propertyId;
  final String propertyTitle;
  final String propertyCity;
  final String guestId;
  final String guestName;
  final ReservationType type;

  /// Visit: the date & time of the viewing. Stay: the check-in date.
  final DateTime start;

  /// Stay only: the check-out date.
  final DateTime? end;

  final int guests;
  final ReservationStatus status;
  final String? note;
  final double? estimatedTotal;
  final DateTime createdAt;

  /// Number of nights for a stay (0 for a visit).
  int get nights {
    final e = end;
    if (type != ReservationType.stay || e == null) return 0;
    return e.difference(DateTime(start.year, start.month, start.day)).inDays;
  }

  /// True when the reservation's date is today or in the future.
  bool get isUpcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !start.isBefore(today);
  }

  /// Every calendar day this reservation occupies (inclusive check-in →
  /// exclusive check-out for a stay; a single day for a visit).
  List<DateTime> get occupiedDays {
    final first = DateTime(start.year, start.month, start.day);
    if (type == ReservationType.visit || end == null) return [first];
    final days = <DateTime>[];
    for (var d = first; d.isBefore(end!); d = d.add(const Duration(days: 1))) {
      days.add(DateTime(d.year, d.month, d.day));
    }
    return days.isEmpty ? [first] : days;
  }

  Reservation copyWith({ReservationStatus? status}) => Reservation(
    id: id,
    propertyId: propertyId,
    propertyTitle: propertyTitle,
    propertyCity: propertyCity,
    guestId: guestId,
    guestName: guestName,
    type: type,
    start: start,
    end: end,
    guests: guests,
    status: status ?? this.status,
    note: note,
    estimatedTotal: estimatedTotal,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'property_id': propertyId,
    'property_title': propertyTitle,
    'property_city': propertyCity,
    'guest_id': guestId,
    'guest_name': guestName,
    'type': type.id,
    'start': start.toIso8601String(),
    'end': end?.toIso8601String(),
    'guests': guests,
    'status': status.id,
    'note': note,
    'estimated_total': estimatedTotal,
    'created_at': createdAt.toIso8601String(),
  };

  factory Reservation.fromMap(Map<String, dynamic> map) => Reservation(
    id: map['id'].toString(),
    propertyId: map['property_id']?.toString() ?? '',
    propertyTitle: map['property_title'] as String? ?? '',
    propertyCity: map['property_city'] as String? ?? '',
    guestId: map['guest_id'] as String? ?? '',
    guestName: map['guest_name'] as String? ?? '',
    type: ReservationTypeX.fromId(map['type'] as String?),
    start: DateTime.parse(map['start'] as String),
    end: (map['end'] as String?) == null
        ? null
        : DateTime.parse(map['end'] as String),
    guests: (map['guests'] as num?)?.toInt() ?? 1,
    status: ReservationStatusX.fromId(map['status'] as String?),
    note: map['note'] as String?,
    estimatedTotal: (map['estimated_total'] as num?)?.toDouble(),
    createdAt:
        DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}
