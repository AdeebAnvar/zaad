import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/utils/items_delivery_catalog_filter.dart';

void main() {
  group('itemMatchesDeliveryService', () {
    const thirdParty = {'3', '5'};

    test('empty item tag matches any partner', () {
      expect(
        itemMatchesDeliveryService(
          itemDeliveryService: null,
          filterToken: '3',
          thirdPartyPartnerServiceIds: thirdParty,
        ),
        isTrue,
      );
    });

    test('NORMAL hides numeric tags when partner list not synced yet', () {
      expect(
        itemMatchesDeliveryService(
          itemDeliveryService: '8',
          filterToken: 'NORMAL',
          thirdPartyPartnerServiceIds: const {},
        ),
        isFalse,
      );
      expect(
        itemMatchesDeliveryService(
          itemDeliveryService: null,
          filterToken: 'NORMAL',
          thirdPartyPartnerServiceIds: const {},
        ),
        isTrue,
      );
    });

    test('NORMAL shows own-fleet and hides aggregator-tagged items', () {
      expect(
        itemMatchesDeliveryService(
          itemDeliveryService: '3',
          filterToken: 'NORMAL',
          thirdPartyPartnerServiceIds: thirdParty,
        ),
        isFalse,
      );
      expect(
        itemMatchesDeliveryService(
          itemDeliveryService: '99',
          filterToken: 'NORMAL',
          thirdPartyPartnerServiceIds: thirdParty,
        ),
        isTrue,
      );
    });

    test('partner id filter matches numeric service id', () {
      expect(
        itemMatchesDeliveryService(
          itemDeliveryService: '3',
          filterToken: '3',
          thirdPartyPartnerServiceIds: thirdParty,
        ),
        isTrue,
      );
    });
  });
}
