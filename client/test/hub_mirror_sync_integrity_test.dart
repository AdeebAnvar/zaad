import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/sync/pos_sync_wire.dart';
import 'package:pos/core/sync/sync_inbox_applier.dart';
import 'package:pos/core/utils/order_log_cart_fallback.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/presentation/dine_in_log/dine_in_reference_utils.dart';
import 'package:pos/data/repository_impl/cart_repository_impl.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/sales_integrity_fixtures.dart';
import 'helpers/sync_inbox_test_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('hub ORDER_CREATE mirror (multi-terminal item integrity)', () {
    late AppDatabase db;
    late LocalHubSettings hubSettings;
    late SyncInboxApplier applier;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      hubSettings = LocalHubSettings(prefs);

      db = AppDatabase.memory();
      await seedBranch2Session(db);

      applier = SyncInboxApplier(
        db,
        hubSettings,
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

    test('two mirrored orders get different cart rows and correct lines each', () async {
      await applier.apply(
        '1',
        hubOrderEnvelope(
          hubOrderPayload(
            serverOrderId: 'hub-100',
            invoice: 'INV-2-100',
            branchId: 2,
            items: [lineSnapshot(itemId: 100, name: 'Burger', total: 50)],
            finalAmount: 50,
          ),
        ),
        const {},
      );
      await applier.apply(
        '2',
        hubOrderEnvelope(
          hubOrderPayload(
            serverOrderId: 'hub-101',
            invoice: 'INV-2-101',
            branchId: 2,
            items: [lineSnapshot(itemId: 101, name: 'Tea', total: 10)],
            finalAmount: 10,
            updatedAtMs: 2000,
          ),
        ),
        const {},
      );

      final oA = (await db.ordersDao.getOrderByServerId('hub-100'))!;
      final oB = (await db.ordersDao.getOrderByServerId('hub-101'))!;

      expect(oA.cartId, isNot(oB.cartId));
      expect(oA.branchId, 2);
      expect(oB.branchId, 2);
      expect(oA.invoiceNumber, 'INV-2-100');
      expect(oB.invoiceNumber, 'INV-2-101');

      final cartRepo = CartRepositoryImpl(db);
      final linesA = await OrderLogCartFallback.resolve(order: oA, db: db, cartRepo: cartRepo);
      final linesB = await OrderLogCartFallback.resolve(order: oB, db: db, cartRepo: cartRepo);

      expect(linesA.single.itemName, 'Burger');
      expect(linesB.single.itemName, 'Tea');
    });

    test('ORDER_UPDATE refreshes lines without stealing from other invoice', () async {
      await applier.apply(
        '1',
        hubOrderEnvelope(
          hubOrderPayload(
            serverOrderId: 'hub-200',
            invoice: 'INV-2-200',
            branchId: 2,
            items: [lineSnapshot(itemId: 100, name: 'Burger', total: 50)],
            finalAmount: 50,
            updatedAtMs: 1000,
          ),
        ),
        const {},
      );
      await applier.apply(
        '2',
        hubOrderEnvelope(
          hubOrderPayload(
            serverOrderId: 'hub-201',
            invoice: 'INV-2-201',
            branchId: 2,
            items: [lineSnapshot(itemId: 101, name: 'Tea', total: 10)],
            finalAmount: 10,
            updatedAtMs: 1000,
          ),
        ),
        const {},
      );

      await applier.apply(
        '3',
        hubOrderEnvelope(
          hubOrderPayload(
            serverOrderId: 'hub-200',
            invoice: 'INV-2-200',
            branchId: 2,
            items: [
              lineSnapshot(itemId: 100, name: 'Burger', qty: 2, total: 100),
            ],
            finalAmount: 100,
            updatedAtMs: 5000,
          ),
        ),
        const {},
      );

      final burger = (await db.ordersDao.getOrderByServerId('hub-200'))!;
      final tea = (await db.ordersDao.getOrderByServerId('hub-201'))!;
      final cartRepo = CartRepositoryImpl(db);

      final burgerLines = await OrderLogCartFallback.resolve(order: burger, db: db, cartRepo: cartRepo);
      final teaLines = await OrderLogCartFallback.resolve(order: tea, db: db, cartRepo: cartRepo);

      expect(burgerLines.single.quantity, 2);
      expect(teaLines.single.itemName, 'Tea');
    });

    test('skips mirror when snapshot has no branch and session missing', () async {
      await db.sessionDao.clearSession();

      await applier.apply(
        '1',
        hubOrderEnvelope(<String, dynamic>{
          'orderId': 'hub-nobranch',
          'updatedAt': 1000,
          'snapshot': <String, dynamic>{
            'invoice_number': 'INV-X',
            'status': 'completed',
            'created_at': DateTime.utc(2026, 5, 17).toIso8601String(),
            'final_amount': 10,
            'items': [lineSnapshot(itemId: 1, name: 'X')],
          },
        }),
        const {},
      );

      expect(await db.ordersDao.getOrderByServerId('hub-nobranch'), isNull);
    });

    test('stale ORDER_UPDATE still applies advanced delivery status', () async {
      await applier.apply(
        '1',
        hubOrderEnvelope(
          hubOrderPayload(
            serverOrderId: 'hub-stale-status',
            invoice: 'INV-2-900',
            branchId: 2,
            orderType: 'delivery',
            status: 'pending',
            items: [lineSnapshot(itemId: 100, name: 'Burger', total: 50)],
            finalAmount: 50,
            updatedAtMs: 2000,
          ),
        ),
        const {},
      );

      final row = (await db.ordersDao.getOrderByServerId('hub-stale-status'))!;
      await (db.update(db.orders)..where((o) => o.id.equals(row.id))).write(
        OrdersCompanion(
          hubMetadata: Value(
            jsonEncode(<String, dynamic>{
              'orderId': 'hub-stale-status',
              'updatedAt': 9000,
              'snapshot': <String, dynamic>{'status': 'pending'},
            }),
          ),
        ),
      );

      await applier.apply(
        '2',
        PosSyncEnvelope(
          eventId: 'evt-stale-status-upd',
          type: PosSyncEventTypes.orderUpdate,
          payload: hubOrderPayload(
            serverOrderId: 'hub-stale-status',
            invoice: 'INV-2-900',
            branchId: 2,
            orderType: 'delivery',
            status: 'delivered',
            items: [lineSnapshot(itemId: 100, name: 'Burger', total: 50)],
            finalAmount: 50,
            updatedAtMs: 1000,
          ),
          timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          deviceId: 'test-device',
        ),
        const {},
      );

      final after = (await db.ordersDao.getOrderByServerId('hub-stale-status'))!;
      expect(after.status, 'completed');
    });

    test('stale dine-in ORDER_UPDATE still applies table routing anchor', () async {
      await applier.apply(
        '1',
        hubOrderEnvelope(
          hubOrderPayload(
            serverOrderId: 'hub-dine-route',
            invoice: 'INV-2-800',
            branchId: 2,
            orderType: 'dine_in',
            status: 'kot',
            items: [lineSnapshot(itemId: 100, name: 'Burger', total: 50)],
            finalAmount: 50,
            updatedAtMs: 5000,
            dineInAnchor: '1|T1 | 2 pax',
            referenceNumber: 'ead',
          ),
        ),
        const {},
      );

      final row = (await db.ordersDao.getOrderByServerId('hub-dine-route'))!;
      await (db.update(db.orders)..where((o) => o.id.equals(row.id))).write(
        OrdersCompanion(
          hubMetadata: Value(
            jsonEncode(<String, dynamic>{
              'orderId': 'hub-dine-route',
              'updatedAt': 9000,
              'dine_in_anchor': '1|T1 | 2 pax',
              'snapshot': <String, dynamic>{'status': 'kot', 'order_type': 'dine_in'},
            }),
          ),
        ),
      );

      await applier.apply(
        '2',
        PosSyncEnvelope(
          eventId: 'evt-dine-route-move',
          type: PosSyncEventTypes.orderUpdate,
          payload: hubOrderPayload(
            serverOrderId: 'hub-dine-route',
            invoice: 'INV-2-800',
            branchId: 2,
            orderType: 'dine_in',
            status: 'kot',
            items: [lineSnapshot(itemId: 100, name: 'Burger', total: 50)],
            finalAmount: 50,
            updatedAtMs: 1000,
            dineInAnchor: '1|T4 | 2 pax',
            referenceNumber: 'ead',
          ),
          timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          deviceId: 'test-device',
        ),
        const {},
      );

      final after = (await db.ordersDao.getOrderByServerId('hub-dine-route'))!;
      expect(after.status, 'kot');
      expect(
        DineInRefParser.dineInRoutingAnchorForMatching(after),
        '1|T4 | 2 pax',
      );
    });

    test('uses snapshot branch_id not session branch 1 when both differ', () async {
      await db.sessionDao.saveSession(1, 'counter', 1);

      await applier.apply(
        '1',
        hubOrderEnvelope(
          hubOrderPayload(
            serverOrderId: 'hub-br',
            invoice: 'INV-2-300',
            branchId: 2,
            items: [lineSnapshot(itemId: 100, name: 'Burger')],
          ),
        ),
        const {},
      );

      final row = await db.ordersDao.getOrderByServerId('hub-br');
      expect(row?.branchId, 2);
    });
  });
}
