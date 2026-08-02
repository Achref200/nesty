import 'package:flutter_test/flutter_test.dart';

import 'package:nestly/core/error/db_error_messages.dart';
import 'package:nestly/features/reservations/domain/entities/availability.dart';
import 'package:nestly/features/reservations/domain/entities/reservation.dart';

/// Regression cover for the reservation rules the mobile app shares with the
/// agency dashboard. Every group here corresponds to something that was
/// actually wrong, so a failure means the two surfaces have drifted apart
/// again rather than that a rule was tightened.

Reservation _stay({
  required DateTime start,
  DateTime? end,
  ReservationStatus status = ReservationStatus.pending,
  DateTime? expiresAt,
  String listingId = 'listing-1',
}) => Reservation(
  id: 'r1',
  propertyId: listingId,
  propertyTitle: 'Sea view apartment',
  propertyCity: 'Sousse',
  guestId: 'g1',
  guestName: 'Amine',
  type: ReservationType.stay,
  start: start,
  end: end,
  status: status,
  expiresAt: expiresAt,
  createdAt: DateTime(2026, 8, 1),
);

void main() {
  group('ReservationStatus.fromId', () {
    // The bug: `rejected` and `expired` weren't in the enum, so both fell
    // through the default branch to `pending`. A traveller who had been turned
    // down went on seeing "Pending" indefinitely.
    test('parses every status the database can store', () {
      expect(ReservationStatusX.fromId('pending'), ReservationStatus.pending);
      expect(
        ReservationStatusX.fromId('confirmed'),
        ReservationStatus.confirmed,
      );
      expect(ReservationStatusX.fromId('rejected'), ReservationStatus.rejected);
      expect(
        ReservationStatusX.fromId('cancelled'),
        ReservationStatus.cancelled,
      );
      expect(ReservationStatusX.fromId('expired'), ReservationStatus.expired);
      expect(
        ReservationStatusX.fromId('completed'),
        ReservationStatus.completed,
      );
    });

    test('does not quietly turn a refusal into a pending request', () {
      expect(
        ReservationStatusX.fromId('rejected'),
        isNot(ReservationStatus.pending),
      );
      expect(
        ReservationStatusX.fromId('expired'),
        isNot(ReservationStatus.pending),
      );
    });

    test('falls back to pending only for genuinely unknown values', () {
      expect(ReservationStatusX.fromId(null), ReservationStatus.pending);
      expect(ReservationStatusX.fromId('nonsense'), ReservationStatus.pending);
    });
  });

  group('which statuses hold the dates', () {
    test('only pending and confirmed block a calendar', () {
      expect(ReservationStatus.pending.isActive, isTrue);
      expect(ReservationStatus.confirmed.isActive, isTrue);
      for (final s in [
        ReservationStatus.rejected,
        ReservationStatus.cancelled,
        ReservationStatus.expired,
        ReservationStatus.completed,
      ]) {
        expect(s.isActive, isFalse, reason: '$s should release the dates');
      }
    });

    test('a refusal is the pair the traveller gets a reason for', () {
      expect(ReservationStatus.rejected.isRefusal, isTrue);
      expect(ReservationStatus.cancelled.isRefusal, isTrue);
      expect(ReservationStatus.expired.isRefusal, isFalse);
      expect(ReservationStatus.completed.isRefusal, isFalse);
    });
  });

  group('soft lock', () {
    test('a lapsed pending hold reads as expired without waiting for the job', () {
      final r = _stay(
        start: DateTime.now().add(const Duration(days: 10)),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(r.status, ReservationStatus.pending);
      expect(r.effectiveStatus, ReservationStatus.expired);
      expect(r.remainingHold, Duration.zero);
    });

    test('a live hold keeps its remaining time and stays pending', () {
      final r = _stay(
        start: DateTime.now().add(const Duration(days: 10)),
        expiresAt: DateTime.now().add(const Duration(hours: 5)),
      );
      expect(r.effectiveStatus, ReservationStatus.pending);
      expect(r.remainingHold.inMinutes, greaterThan(0));
    });

    test('a row with no expiry is left alone', () {
      final r = _stay(start: DateTime.now().add(const Duration(days: 3)));
      expect(r.effectiveStatus, ReservationStatus.pending);
      expect(r.remainingHold, Duration.zero);
    });

    test('only pending rows are subject to the hold', () {
      final r = _stay(
        start: DateTime.now().add(const Duration(days: 10)),
        status: ReservationStatus.confirmed,
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(r.effectiveStatus, ReservationStatus.confirmed);
    });
  });

  group('occupancy', () {
    test('a stay holds check-in up to but not including check-out', () {
      final r = _stay(
        start: DateTime(2026, 8, 10),
        end: DateTime(2026, 8, 13),
      );
      expect(r.occupiedDays, [
        DateTime(2026, 8, 10),
        DateTime(2026, 8, 11),
        DateTime(2026, 8, 12),
      ]);
      // Back-to-back stays are allowed: the 13th is free for the next guest.
      expect(r.occupiedDays, isNot(contains(DateTime(2026, 8, 13))));
      expect(r.nights, 3);
    });

    test('a stay with no end still holds one night', () {
      final r = _stay(start: DateTime(2026, 8, 10));
      expect(r.occupiedDays, [DateTime(2026, 8, 10)]);
    });
  });

  group('AvailabilityBlock', () {
    test('covers its range with the end date excluded', () {
      final b = AvailabilityBlock(
        id: 'b1',
        listingId: 'listing-1',
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 4),
      );
      expect(b.days, [
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 2),
        DateTime(2026, 9, 3),
      ]);
    });

    test('a zero-width block still covers its start day', () {
      final b = AvailabilityBlock(
        id: 'b2',
        listingId: 'listing-1',
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 1),
      );
      expect(b.days, [DateTime(2026, 9, 1)]);
    });
  });

  group('DayAvailability precedence', () {
    // Must match STATE_RANK in nesty-web/src/lib/availability.ts, or the two
    // calendars disagree about what colour a day is.
    test('confirmed outranks blocked outranks pending outranks available', () {
      expect(
        DayAvailability.confirmed.rank,
        greaterThan(DayAvailability.blocked.rank),
      );
      expect(
        DayAvailability.blocked.rank,
        greaterThan(DayAvailability.pending.rank),
      );
      expect(
        DayAvailability.pending.rank,
        greaterThan(DayAvailability.available.rank),
      );
    });

    test('only an available day can be booked', () {
      expect(DayAvailability.available.isBookable, isTrue);
      for (final s in [
        DayAvailability.pending,
        DayAvailability.blocked,
        DayAvailability.confirmed,
      ]) {
        expect(s.isBookable, isFalse);
      }
    });
  });

  group('describeDbError', () {
    test('explains a double-booking without naming the constraint', () {
      final msg = describeDbError(
        'conflicting key value violates exclusion constraint '
        '"reservations_no_active_overlap"',
      );
      expect(msg, contains('overlap'));
      expect(msg, isNot(contains('constraint')));
      expect(msg, isNot(contains('_')));
    });

    test('explains a manually blocked period', () {
      expect(
        describeDbError('These dates are blocked for this listing.'),
        contains('blocked'),
      );
    });

    test('turns a missing column into something actionable', () {
      final msg = describeDbError(
        'column "payload" of relation "notifications" does not exist',
      );
      expect(msg, contains('isn\'t available'));
    });

    test('never echoes an unrecognised database message back at the user', () {
      const raw = 'PGRST301 JWT expired at 2026-08-01T00:00:00Z';
      final msg = describeDbError(raw);
      expect(msg, isNot(contains('PGRST301')));
      expect(msg, isNot(contains('JWT')));
      expect(msg, isNotEmpty);
    });
  });
}
