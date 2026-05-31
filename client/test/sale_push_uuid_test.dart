import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/utils/sale_push_uuid.dart';

void main() {
  group('generateSalePushUuid', () {
    test('each call produces a new random uuid', () {
      final a = generateSalePushUuid();
      final b = generateSalePushUuid();
      expect(a, isNot(equals(b)));
    });
  });

  group('readSalePushUuidFromSnap', () {
    test('reads stored uuid from snapshot', () {
      const uuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
      expect(
        readSalePushUuidFromSnap({'sale_push_uuid': uuid}),
        uuid,
      );
    });

    test('returns null when absent or blank', () {
      expect(readSalePushUuidFromSnap({}), isNull);
      expect(readSalePushUuidFromSnap({'sale_push_uuid': '  '}), isNull);
    });
  });

  group('duplicate receipt ids', () {
    test('two orders with same invoice get different generated uuids', () {
      final first = generateSalePushUuid();
      final second = generateSalePushUuid();
      expect(first, isNot(second));
    });
  });

  group('deterministicCreditPushUuid', () {
    test('credit uuid is stable for the same sale uuid', () {
      const sale = '11111111-2222-3333-4444-555555555555';
      expect(
        deterministicCreditPushUuid(sale),
        deterministicCreditPushUuid(sale),
      );
    });
  });
}
