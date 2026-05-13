import 'package:flutter_test/flutter_test.dart';
import 'package:pos/domain/models/offer_model.dart';

void main() {
  group('OfferSchedule.isActiveAt', () {
    test('Monday 10:00 + 24h: active Mon 10:30 and Tue 09:59, inactive Tue 10:00', () {
      const days = ['monday'];
      const start = '10:00:00';
      const hours = 24.0;

      final mon1030 = DateTime(2025, 1, 6, 10, 30); // Monday
      expect(OfferSchedule.isActiveAt(mon1030, days: days, startTime: start, offerHours: hours), isTrue);

      final tue0959 = DateTime(2025, 1, 7, 9, 59);
      expect(OfferSchedule.isActiveAt(tue0959, days: days, startTime: start, offerHours: hours), isTrue);

      final tue1000 = DateTime(2025, 1, 7, 10, 0);
      expect(OfferSchedule.isActiveAt(tue1000, days: days, startTime: start, offerHours: hours), isFalse);

      final mon0959 = DateTime(2025, 1, 6, 9, 59);
      expect(OfferSchedule.isActiveAt(mon0959, days: days, startTime: start, offerHours: hours), isFalse);
    });

    test('without time window, monday-only matches whole Monday', () {
      final mon = DateTime(2025, 1, 6, 3, 0);
      expect(OfferSchedule.isActiveAt(mon, days: const ['monday']), isTrue);
      final tue = DateTime(2025, 1, 7, 3, 0);
      expect(OfferSchedule.isActiveAt(tue, days: const ['monday']), isFalse);
    });

    test('empty days + no window is always active', () {
      expect(OfferSchedule.isActiveAt(DateTime.now(), days: const []), isTrue);
    });
  });

  group('OfferCreatedUpdated.fromJson', () {
    test('parses start_time and offer_hour', () {
      final o = OfferCreatedUpdated.fromJson({
        'id': 1,
        'uuid': 'u',
        'branch_id': 1,
        'promocode': '',
        'from_date': '',
        'to_date': '',
        'value': '10',
        'type': 'amount',
        'active': 1,
        'created_at': '2020-01-01T00:00:00Z',
        'updated_at': '2020-01-01T00:00:00Z',
        'deleted_at': null,
        'offer_name': 'Test',
        'item_id': [],
        'category_id': [],
        'is_all_items': 1,
        'day': ['monday'],
        'start_time': '10:00:00',
        'offer_hour': 24,
      });
      expect(o.startTime, '10:00:00');
      expect(o.offerHours, 24.0);
    });
  });
}
