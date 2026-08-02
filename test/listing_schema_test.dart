import 'package:flutter_test/flutter_test.dart';

import 'package:nestly/features/listings/data/models/property_model.dart';
import 'package:nestly/features/listings/domain/entities/listing_schema.dart';

/// Guards the contract mobile shares with `nesty-web/src/lib/listings/schema.ts`.
/// If one of these fails, a listing created on one surface will render wrong on
/// the other — which is exactly the drift this file exists to catch.
void main() {
  group('ListingStatus', () {
    test('treats the legacy and current live spellings as the same thing', () {
      // The lifecycle migration renamed `active` to `published`. Rows written
      // before it ran still say `active`, and both have to count as live.
      expect(ListingStatusX.fromId('active'), ListingStatus.published);
      expect(ListingStatusX.fromId('published'), ListingStatus.published);
      expect(ListingStatusX.fromId('hidden'), ListingStatus.disabled);
      expect(ListingStatusX.fromId('disabled'), ListingStatus.disabled);
    });

    test('publicVisibleStatuses covers both spellings', () {
      expect(publicVisibleStatuses, contains('published'));
      expect(publicVisibleStatuses, contains('active'));
      for (final s in publicVisibleStatuses) {
        expect(ListingStatusX.fromId(s).isLive, isTrue);
      }
    });

    test('a draft is never live', () {
      expect(ListingStatus.draft.isLive, isFalse);
      expect(ListingStatus.completed.isLive, isFalse);
      expect(ListingStatus.disabled.isLive, isFalse);
      expect(ListingStatusX.fromId(null).isLive, isFalse);
    });

    test('only a listing still in preparation is editable', () {
      expect(ListingStatus.draft.isEditable, isTrue);
      expect(ListingStatus.completed.isEditable, isTrue);
      expect(ListingStatus.published.isEditable, isFalse);
      expect(ListingStatus.disabled.isEditable, isFalse);
    });

    test('round-trips through the id the database stores', () {
      for (final s in ListingStatus.values) {
        expect(ListingStatusX.fromId(s.id), s, reason: 'broke on ${s.name}');
      }
    });
  });

  group('shared vocabulary', () {
    test('amenity ids are the canonical ones, not display strings', () {
      // Mobile used to store 'Wi-Fi' and 'Bills included', which the dashboard
      // could not read.
      expect(amenityIds, contains('wifi'));
      expect(amenityIds, contains('hotWater'));
      expect(amenityIds, isNot(contains('Wi-Fi')));
      expect(amenityIds, isNot(contains('Bills included')));
    });

    test('every amenity id has a label in both languages', () {
      for (final id in amenityIds) {
        expect(amenityLabel(id, false), isNotEmpty);
        expect(amenityLabel(id, true), isNotEmpty);
        expect(amenityLabel(id, false), isNot(id), reason: 'no EN label: $id');
      }
    });

    test('every tag id has a label in both languages', () {
      for (final id in listingTagIds) {
        expect(listingTagLabel(id, false), isNot(id), reason: 'no EN: $id');
        expect(listingTagLabel(id, true), isNotEmpty);
      }
    });

    test('an unknown id falls back to itself rather than throwing', () {
      expect(amenityLabel('jacuzzi', false), 'jacuzzi');
      expect(listingTagLabel('skiIn', true), 'skiIn');
    });

    test('the defaults a new listing starts with are all real amenities', () {
      for (final id in defaultAmenityIds) {
        expect(amenityIds, contains(id));
      }
    });
  });

  group('validation shared with the wizard', () {
    test('accepts Tunisian phone numbers with and without the prefix', () {
      expect(isValidTunisianPhone('20000000'), isTrue);
      expect(isValidTunisianPhone('+216 20 000 000'), isTrue);
      expect(isValidTunisianPhone('216-20-000-000'), isTrue);
      expect(isValidTunisianPhone('2000000'), isFalse); // seven digits
      expect(isValidTunisianPhone('+33 6 12 34 56 78'), isFalse);
    });

    test('the map pin has to land inside Tunisia', () {
      expect(isInTunisia(36.8, 10.18), isTrue); // Tunis
      expect(isInTunisia(35.83, 10.64), isTrue); // Sousse
      expect(isInTunisia(48.85, 2.35), isFalse); // Paris
    });

    test('photo limits match the dashboard wizard', () {
      expect(photoMin, 5);
      expect(photoMax, 30);
    });
  });

  group('PropertyModel round-trip', () {
    test('reads back everything the wizard writes', () {
      final row = <String, dynamic>{
        'id': 'l1',
        'title': 'Riad in the medina',
        'city': 'Sousse',
        'price_per_month': 900,
        'status': 'published',
        'property_type': 'riad',
        'max_guests': 6,
        'district': 'Khezama',
        'contact_phone': '+21620000000',
        'amenities': ['wifi', 'pool'],
        'tags': ['seaView'],
        'house_rules': {'pets': true, 'smoking': false, 'party': false,
                        'instructions': 'No shoes indoors.'},
        'pricing': {'model': 'night', 'amount': 180, 'minNights': 2},
        'booking_conditions': {
          'cancellation': 'strict',
          'paymentMethods': ['cash', 'card'],
          'paymentPolicy': 'mandatoryAdvance',
          'advancePct': 30,
        },
      };

      final p = PropertyModel.fromMap(row);

      expect(p.status, ListingStatus.published);
      expect(p.propertyType, PropertyType.riad);
      expect(p.maxGuests, 6);
      expect(p.district, 'Khezama');
      expect(p.rules.pets, isTrue);
      expect(p.rules.instructions, 'No shoes indoors.');
      expect(p.pricing.model, PricingModel.night);
      expect(p.pricing.amount, 180);
      expect(p.pricing.minNights, 2);
      expect(p.conditions.cancellation, CancellationPolicy.strict);
      expect(p.conditions.paymentMethods,
          containsAll([PaymentMethod.cash, PaymentMethod.card]));
      expect(p.conditions.paymentPolicy, PaymentPolicy.mandatoryAdvance);

      // The price shown is the host's own figure and period, not a monthly
      // number invented by dividing something.
      expect(p.displayPrice, 180);
      expect(p.displayPricingModel, PricingModel.night);
    });

    test('a pre-wizard row still loads, falling back to the monthly price', () {
      final p = PropertyModel.fromMap({
        'id': 'l2',
        'title': 'Old row',
        'city': 'Tunis',
        'price_per_month': 1200,
        'status': 'active',
      });

      expect(p.status, ListingStatus.published);
      expect(p.propertyType, PropertyType.apartment);
      expect(p.maxGuests, 0);
      expect(p.rules.pets, isFalse);
      expect(p.displayPrice, 1200);
      expect(p.displayPricingModel, PricingModel.month);
    });

    test('survives jsonb columns arriving empty or malformed', () {
      final p = PropertyModel.fromMap({
        'id': 'l3',
        'title': 'Half-migrated',
        'city': 'Sfax',
        'price_per_month': 500,
        'house_rules': <String, dynamic>{},
        'pricing': 'not-an-object',
        'booking_conditions': null,
      });

      expect(p.pricing.amount, 0);
      expect(p.conditions.paymentMethods, [PaymentMethod.cash]);
      expect(p.rules.instructions, '');
    });
  });
}
