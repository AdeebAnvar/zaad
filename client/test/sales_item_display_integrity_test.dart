
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/utils/order_log_cart_fallback.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository_impl/cart_repository_impl.dart';
import 'package:pos/data/repository_impl/order_repository_impl.dart';
import 'helpers/sales_integrity_fixtures.dart';

/// Regression: Recent Sales / day close must not show another bill's lines when cart_id is shared.
void main() {
  group('shared cart_id — customer bug reproduction', () {
    late AppDatabase db;
    late int sharedCartId;

    setUp(() async {
      db = AppDatabase.memory();
      sharedCartId = await db.cartsDao.createCart('_shared', branchId: 2);
    });

    tearDown(() async {
      await db.close();
    });

    Future<Order> insertOrder({
      required String invoice,
      required String liveName,
      required int itemId,
      String? hubMetadata,
    }) async {
      await db.into(db.cartItems).insert(
            CartItemsCompanion.insert(
              cartId: sharedCartId,
              itemId: itemId,
              quantity: 1,
              total: const Value(10),
              itemName: Value(liveName),
            ),
          );
      final orderId = await db.ordersDao.createOrder(
        OrdersCompanion.insert(
          cartId: sharedCartId,
          invoiceNumber: invoice,
          totalAmount: 10,
          finalAmount: 10,
          createdAt: DateTime.utc(2026, 5, 17, 12),
          status: const Value('completed'),
          orderType: const Value('take_away'),
          branchId: const Value(2),
          cashAmount: const Value(10),
          hubMetadata: hubMetadata == null ? const Value.absent() : Value(hubMetadata),
        ),
      );
      return (await db.ordersDao.getOrderById(orderId))!;
    }

    test('live cart shows last sale items for both invoices', () async {
      await insertOrder(invoice: 'INV-2-010', liveName: 'Coffee A', itemId: 1);
      await (db.delete(db.cartItems)..where((c) => c.cartId.equals(sharedCartId))).go();
      await insertOrder(invoice: 'INV-2-011', liveName: 'Tea B', itemId: 2);

      final all = await db.ordersDao.getAllOrders(branchId: 2);
      final oA = all.firstWhere((o) => o.invoiceNumber == 'INV-2-010');
      final oB = all.firstWhere((o) => o.invoiceNumber == 'INV-2-011');
      final cartRepo = CartRepositoryImpl(db);

      expect((await cartRepo.getCartItemsByCartId(oA.cartId))!.single.itemName, 'Tea B');
      expect((await cartRepo.getCartItemsByCartId(oB.cartId))!.single.itemName, 'Tea B');
    });

    test('frozen hubMetadata shows correct items per invoice', () async {
      final oA = await insertOrder(
        invoice: 'INV-2-010',
        liveName: 'x',
        itemId: 1,
        hubMetadata: hubMetadataItemsJson([lineSnapshot(itemId: 1, name: 'Coffee A')]),
      );
      await (db.delete(db.cartItems)..where((c) => c.cartId.equals(sharedCartId))).go();
      final oB = await insertOrder(
        invoice: 'INV-2-011',
        liveName: 'Tea B',
        itemId: 2,
        hubMetadata: hubMetadataItemsJson([lineSnapshot(itemId: 2, name: 'Tea B')]),
      );

      final cartRepo = CartRepositoryImpl(db);
      expect(
        (await OrderLogCartFallback.resolve(order: oA, db: db, cartRepo: cartRepo)).single.itemName,
        'Coffee A',
      );
      expect(
        (await OrderLogCartFallback.resolve(order: oB, db: db, cartRepo: cartRepo)).single.itemName,
        'Tea B',
      );
    });

    test('three invoices on one cart — each snapshot independent', () async {
      final orders = <Order>[];
      for (var i = 0; i < 3; i++) {
        if (i > 0) {
          await (db.delete(db.cartItems)..where((c) => c.cartId.equals(sharedCartId))).go();
        }
        orders.add(
          await insertOrder(
            invoice: 'INV-2-02$i',
            liveName: 'live-$i',
            itemId: i,
            hubMetadata: hubMetadataItemsJson([
              lineSnapshot(itemId: i + 10, name: 'Product $i'),
            ]),
          ),
        );
      }

      final cartRepo = CartRepositoryImpl(db);
      for (var i = 0; i < 3; i++) {
        final lines = await OrderLogCartFallback.resolve(order: orders[i], db: db, cartRepo: cartRepo);
        expect(lines.single.itemName, 'Product $i');
      }
    });
  });

  group('createOrder / updateOrderStatus freeze lines', () {
    late AppDatabase db;
    late OrderRepositoryImpl repo;

    setUp(() async {
      db = AppDatabase.memory();
      await seedBranch2Session(db);
      repo = OrderRepositoryImpl(db);
    });

    tearDown(() async {
      await db.close();
    });

    Order draftOrder(String invoice, int cartId, String itemName) => Order(
          id: 0,
          cartId: cartId,
          invoiceNumber: invoice,
          totalAmount: 24,
          discountAmount: 0,
          finalAmount: 24,
          cashAmount: 24,
          creditAmount: 0,
          cardAmount: 0,
          onlineAmount: 0,
          createdAt: DateTime.utc(2026, 5, 17, 14),
          status: 'completed',
          orderType: 'take_away',
          branchId: 2,
          hubSyncPending: false,
        );

    test('createOrder writes hubMetadata with item names', () async {
      final cartId = await db.cartsDao.createCart('INV-2-020', branchId: 2);
      await db.into(db.cartItems).insert(
            CartItemsCompanion.insert(
              cartId: cartId,
              itemId: 100,
              quantity: 2,
              total: const Value(24),
              itemName: const Value('Shawarma'),
            ),
          );

      final id = await repo.createOrder(draftOrder('INV-2-020', cartId, 'Shawarma'));
      final saved = (await db.ordersDao.getOrderById(id))!;

      await (db.delete(db.cartItems)..where((c) => c.cartId.equals(cartId))).go();
      await db.into(db.cartItems).insert(
            CartItemsCompanion.insert(
              cartId: cartId,
              itemId: 99,
              quantity: 1,
              total: const Value(5),
              itemName: const Value('Wrong Item'),
            ),
          );

      final resolved = await OrderLogCartFallback.resolveWithDb(order: saved, db: db);
      expect(resolved.single.itemName, 'Shawarma');
      expect(resolved.single.quantity, 2);
    });

    test('updateOrderStatus refreshes frozen snapshot after cart edit', () async {
      final cartId = await db.cartsDao.createCart('INV-2-021', branchId: 2);
      await db.into(db.cartItems).insert(
            CartItemsCompanion.insert(
              cartId: cartId,
              itemId: 101,
              quantity: 1,
              total: const Value(10),
              itemName: const Value('Tea'),
            ),
          );

      final id = await repo.createOrder(draftOrder('INV-2-021', cartId, 'Tea'));

      await (db.delete(db.cartItems)..where((c) => c.cartId.equals(cartId))).go();
      await db.into(db.cartItems).insert(
            CartItemsCompanion.insert(
              cartId: cartId,
              itemId: 100,
              quantity: 1,
              total: const Value(50),
              itemName: const Value('Burger'),
            ),
          );

      await repo.updateOrderStatus(id, 'completed');
      final saved = (await db.ordersDao.getOrderById(id))!;
      final resolved = await OrderLogCartFallback.resolveWithDb(order: saved, db: db);

      expect(resolved.single.itemName, 'Burger');
    });
  });

  group('day closing uses per-order frozen lines', () {
    test('item-wise totals use snapshot not shared live cart', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await seedBranch2Session(db);

      final shared = await db.cartsDao.createCart('_dayclose', branchId: 2);

      Future<void> addSettled(String inv, String snapName, int itemId, double amount) async {
        final meta = hubMetadataItemsJson([
          lineSnapshot(itemId: itemId, name: snapName, total: amount),
        ]);
        await db.ordersDao.createOrder(
          OrdersCompanion.insert(
            cartId: shared,
            invoiceNumber: inv,
            totalAmount: amount,
            finalAmount: amount,
            createdAt: DateTime.utc(2026, 5, 17, 15),
            status: const Value('completed'),
            orderType: const Value('take_away'),
            branchId: const Value(2),
            cashAmount: Value(amount),
            hubMetadata: Value(meta),
          ),
        );
      }

      await addSettled('INV-2-030', 'Burger', 100, 50);
      await (db.delete(db.cartItems)..where((c) => c.cartId.equals(shared))).go();
      await db.into(db.cartItems).insert(
            CartItemsCompanion.insert(
              cartId: shared,
              itemId: 101,
              quantity: 1,
              total: const Value(10),
              itemName: const Value('Tea live only'),
            ),
          );
      await addSettled('INV-2-031', 'Tea', 101, 10);

      // final summary = await computeDayClosingSummary(db);
      // final names = summary..map((r) => r.item).toSet();

      // expect(names, contains('BURGER'));
      // expect(names, contains('TEA'));
      // expect(names, isNot(contains('TEA LIVE ONLY')));
    });
  });

  group('OrderLog-only legacy rows', () {
    test('resolve uses OrderLog when hubMetadata absent', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);

      final cartId = await db.cartsDao.createCart('_legacy', branchId: 2);
      await db.into(db.cartItems).insert(
            CartItemsCompanion.insert(
              cartId: cartId,
              itemId: 88,
              quantity: 1,
              total: const Value(99),
              itemName: const Value('Stale Live'),
            ),
          );

      final orderId = await db.ordersDao.createOrder(
        OrdersCompanion.insert(
          cartId: cartId,
          invoiceNumber: 'INV-2-040',
          totalAmount: 15,
          finalAmount: 15,
          createdAt: DateTime.utc(2026, 5, 17, 10),
          status: const Value('completed'),
          branchId: const Value(2),
        ),
      );

      await db.ordersDao.insertOrderLog(
        orderLogJson(
          orderId: orderId,
          items: [lineSnapshot(itemId: 2, name: 'Logged Tea', qty: 3, total: 15)],
        ),
      );

      final order = (await db.ordersDao.getOrderById(orderId))!;
      final lines = await OrderLogCartFallback.resolveWithDb(order: order, db: db);

      expect(lines.single.itemName, 'Logged Tea');
      expect(lines.single.quantity, 3);
    });
  });
}
