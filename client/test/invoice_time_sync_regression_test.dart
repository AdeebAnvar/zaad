import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/sync/pos_sync_wire.dart';
import 'package:pos/core/sync/sync_inbox_applier.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/sales_integrity_fixtures.dart';
import 'helpers/sync_inbox_test_stubs.dart';

/// Regression for field report:
/// - Recent Sales shows invoice "40m ago" (completed on MAIN)
/// - Delivery Log on SUB still shows same invoice "15m ago" (stuck pending)
///
/// Causes:
/// 1) Duplicate SQLite rows for one invoice (local SUB row + hub mirrored row)
/// 2) Stale LAN payload ignored completed status when SUB had newer local touch
const _kDeliverySaleLogPendingStatuses = ['placed', 'pending', 'kot'];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('invoice time + LAN sync regression', () {
    late AppDatabase db;
    late SyncInboxApplier applier;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final hub = LocalHubSettings(await SharedPreferences.getInstance());
      db = AppDatabase.memory();
      await seedBranch2Session(db);
      applier = SyncInboxApplier(
        db,
        hub,
        HubOrdersLiveSync(),
        StubPullDataRepository(),
        userRepo: StubUserRepository(),
        branchRepo: StubBranchRepository(),
        settingsRepo: StubSettingsRepository(),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('reproduces duplicate rows without invoice merge (symptom: two times, log stuck)', () async {
      final subCreated = DateTime(2026, 5, 17, 14, 30);
      final hubCreated = DateTime(2026, 5, 17, 14, 0);

      // SUB created delivery locally 30m later, no hub link yet.
      await db.into(db.orders).insert(
            OrdersCompanion.insert(
              cartId: 1,
              invoiceNumber: 'INV-2-DUP',
              branchId: const Value(2),
              totalAmount: 50,
              finalAmount: 50,
              createdAt: subCreated,
              status: const Value('pending'),
              orderType: const Value('delivery'),
            ),
          );

      // Simulate OLD applier: only KOT invoice merge — delivery pending not linked.
      // We assert the bug shape: insert without merge would duplicate.
      final beforeMerge = await db.ordersDao.findLocalOrderAwaitingHubLinkByInvoice(
        'INV-2-DUP',
        branchId: 2,
      );
      expect(beforeMerge, isNotNull);
      expect(beforeMerge!.status, 'pending');

      // With current merge + hub upsert, one row should remain.
      await applier.apply(
        'hub-dup-1',
        hubOrderEnvelope(
          hubOrderPayload(
            serverOrderId: 'hub-dup-1',
            invoice: 'INV-2-DUP',
            branchId: 2,
            orderType: 'delivery',
            status: 'delivered',
            createdAt: hubCreated,
            items: [lineSnapshot(itemId: 100, name: 'Burger', total: 50)],
            finalAmount: 50,
            updatedAtMs: 5000,
          ),
        ),
        const {},
      );

      final all = await db.ordersDao.getAllOrders(branchId: 2);
      final dupInvoices = all.where((o) => o.invoiceNumber == 'INV-2-DUP').toList();
      expect(dupInvoices, hasLength(1));

      final row = dupInvoices.single;
      expect(row.status, 'completed');
      expect(row.serverOrderId, 'hub-dup-1');
      // Local row keeps its original createdAt (UI time matches on all screens).
      expect(row.createdAt, subCreated);

      // Delivery log filter: completed must not appear.
      final inDeliveryLog = dupInvoices.where((o) {
        final s = o.status.toLowerCase();
        return _kDeliverySaleLogPendingStatuses.contains(s);
      });
      expect(inDeliveryLog, isEmpty);
    });

    test('stale hub completed update still clears delivery log on SUB', () async {
      final created = DateTime(2026, 5, 17, 10);

      await applier.apply(
        '1',
        hubOrderEnvelope(
          hubOrderPayload(
            serverOrderId: 'hub-stale-inv',
            invoice: 'INV-2-STALE',
            branchId: 2,
            orderType: 'delivery',
            status: 'pending',
            createdAt: created,
            items: [lineSnapshot(itemId: 100, name: 'Burger', total: 50)],
            updatedAtMs: 2000,
          ),
        ),
        const {},
      );

      final row = (await db.ordersDao.getOrderByServerId('hub-stale-inv'))!;
      await (db.update(db.orders)..where((o) => o.id.equals(row.id))).write(
        OrdersCompanion(
          hubMetadata: Value(
            '{"orderId":"hub-stale-inv","updatedAt":9000}',
          ),
        ),
      );

      await applier.apply(
        '2',
        PosSyncEnvelope(
          eventId: 'evt-stale-inv',
          type: PosSyncEventTypes.orderUpdate,
          payload: hubOrderPayload(
            serverOrderId: 'hub-stale-inv',
            invoice: 'INV-2-STALE',
            branchId: 2,
            orderType: 'delivery',
            status: 'delivered',
            createdAt: created,
            items: [lineSnapshot(itemId: 100, name: 'Burger', total: 50)],
            updatedAtMs: 1000,
          ),
          timestamp: 1,
          deviceId: 'MAIN-HUB',
        ),
        const {},
      );

      final after = (await db.ordersDao.getOrderByServerId('hub-stale-inv'))!;
      expect(after.status, 'completed');

      final pending = await db.ordersDao.filterOrders(
        orderType: 'delivery',
        statusAnyOf: _kDeliverySaleLogPendingStatuses,
        branchId: 2,
      );
      expect(pending.any((o) => o.invoiceNumber == 'INV-2-STALE'), isFalse);
    });
  });
}
