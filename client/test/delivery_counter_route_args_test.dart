import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/utils/delivery_counter_route_args.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository_impl/delivery_partner_repository_impl.dart';

void main() {
  group('resolveDeliveryCounterRouteArgs', () {
    late AppDatabase db;
    late DeliveryPartnerRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.memory();
      repo = DeliveryPartnerRepositoryImpl(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<void> seedPartner({required int id, required String name}) async {
      await db.deliveryPartnersDao.upsertDeliveryPartner(
        DeliveryPartnersCompanion.insert(
          id: Value(id),
          name: name,
        ),
      );
    }

    test('NORMAL label maps to NORMAL service id', () async {
      final r = await resolveDeliveryCounterRouteArgs(
        deliveryPartnerLabel: 'NORMAL',
        partnerRepo: repo,
      );
      expect(r.deliveryPartner, 'NORMAL');
      expect(r.deliveryServiceId, 'NORMAL');
    });

    test('partner name maps to numeric service id', () async {
      await seedPartner(id: 3, name: 'Talabat');
      final r = await resolveDeliveryCounterRouteArgs(
        deliveryPartnerLabel: 'Talabat',
        partnerRepo: repo,
      );
      expect(r.deliveryPartner, 'Talabat');
      expect(r.deliveryServiceId, '3');
    });

    test('partner id string maps to name + id service', () async {
      await seedPartner(id: 5, name: 'Noon');
      final r = await resolveDeliveryCounterRouteArgs(
        deliveryPartnerLabel: '5',
        partnerRepo: repo,
      );
      expect(r.deliveryPartner, 'Noon');
      expect(r.deliveryServiceId, '5');
    });
  });
}
