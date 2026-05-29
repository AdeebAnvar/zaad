import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository_impl/cart_repository_impl.dart';
import 'package:pos/data/repository_impl/order_repository_impl.dart';
import 'helpers/sales_integrity_fixtures.dart';

/// CRUD coverage for Drift DAOs and repositories used in sales flows.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    await seedBranch2Session(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('SessionDao', () {
    test('insert get update delete session', () async {
      await db.sessionDao.saveSession(1, 'counter', 2);
      var session = await db.sessionDao.getActiveSession();
      expect(session, isNotNull);
      expect(session!.userId, 1);
      expect(session.branchId, 2);
      expect(session.role, 'counter');

      await db.sessionDao.setActiveCartId(99);
      session = await db.sessionDao.getActiveSession();
      expect(await db.sessionDao.getActiveCartId(), 99);

      await db.sessionDao.setActiveCartId(null);
      expect(await db.sessionDao.getActiveCartId(), isNull);

      await db.sessionDao.clearSession();
      expect(await db.sessionDao.getActiveSession(), isNull);
    });

    test('saveSession replaces previous row (single active session)', () async {
      await db.sessionDao.saveSession(1, 'counter', 2);
      await db.sessionDao.saveSession(2, 'admin', 2);
      final session = await db.sessionDao.getActiveSession();
      expect(session?.userId, 2);
      expect(session?.role, 'admin');
      expect((await db.select(db.sessions).get()).length, 1);
    });

    test('requireActiveBranchId returns branch after save', () async {
      expect(await db.sessionDao.requireActiveBranchId(), 2);
    });
  });

  group('CustomersDao', () {
    test('getCustomersMapByServerIds and markAsSyncedBatch', () async {
      await db.customersDao.insertCustomer(
        CustomersCompanion.insert(
          name: 'BatchTest',
          serverId: const Value('srv-batch-1'),
          isSynced: const Value(false),
        ),
      );
      final map = await db.customersDao.getCustomersMapByServerIds({'srv-batch-1', 'missing'});
      expect(map['srv-batch-1'], isNotNull);
      expect(map.containsKey('missing'), isFalse);

      final id = map['srv-batch-1']!.id;
      await db.customersDao.markAsSyncedBatch([id]);
      expect((await db.customersDao.getCustomerById(id))?.isSynced, isTrue);
    });
  });

  group('CartsDao', () {
    test('insert get update delete cart', () async {
      final cartId = await db.cartsDao.createCart(
        'INV-2-100',
        orderType: 'take_away',
        branchId: 2,
      );

      final byId = await db.cartsDao.getCartByCartId(cartId);
      expect(byId?.invoiceNumber, 'INV-2-100');
      expect(byId?.branchId, 2);

      final byInvoice = await db.cartsDao.getCartByInvoice('INV-2-100');
      expect(byInvoice?.id, cartId);

      await db.cartsDao.updateCartOrderInfo(
        cartId,
        orderType: 'delivery',
        deliveryPartner: 'Swiggy',
      );
      final updated = await db.cartsDao.getCartByCartId(cartId);
      expect(updated?.orderType, 'delivery');
      expect(updated?.deliveryPartner, 'Swiggy');

      await db.cartsDao.deleteCart(cartId);
      expect(await db.cartsDao.getCartByCartId(cartId), isNull);
    });

    test('maxInvoiceNumericSuffixForPrefix tracks highest suffix', () async {
      await db.cartsDao.createCart('INV-2-001', branchId: 2);
      await db.cartsDao.createCart('INV-2-005', branchId: 2);
      final max = await db.cartsDao.maxInvoiceNumericSuffixForPrefix('INV', branchId: 2);
      expect(max, 5);
    });
  });

  group('CartItems (CartsDao)', () {
    late int cartId;

    setUp(() async {
      cartId = await db.cartsDao.createCart('INV-2-200', branchId: 2);
    });

    test('insert get update delete cart lines', () async {
      final lineId = await db.cartsDao.addCartItem(
        CartItemsCompanion.insert(
          cartId: cartId,
          itemId: 100,
          quantity: 2,
          total: const Value(40),
          itemName: const Value('Burger'),
        ),
      );

      var lines = await db.cartsDao.getItemsByCart(cartId);
      expect(lines, hasLength(1));
      expect(lines.single.id, lineId);
      expect(lines.single.itemName, 'Burger');
      expect(lines.single.quantity, 2);

      await db.cartsDao.updateCartItemTotal(lineId, 35);
      lines = await db.cartsDao.getItemsByCart(cartId);
      expect(lines.single.total, 35);

      await db.cartsDao.removeCartItem(lineId);
      expect(await db.cartsDao.getItemsByCart(cartId), isEmpty);
    });

    test('reassignCartItemsToCart moves lines to target cart', () async {
      final targetId = await db.cartsDao.createCart('INV-2-201', branchId: 2);
      final lineId = await db.cartsDao.addCartItem(
        CartItemsCompanion.insert(
          cartId: cartId,
          itemId: 101,
          quantity: 1,
          total: const Value(10),
          itemName: const Value('Tea'),
        ),
      );

      await db.cartsDao.reassignCartItemsToCart([lineId], targetId);

      expect(await db.cartsDao.getItemsByCart(cartId), isEmpty);
      final moved = await db.cartsDao.getItemsByCart(targetId);
      expect(moved.single.itemName, 'Tea');
    });

    test('countCartItemsByCartIds returns counts per cart', () async {
      final cartB = await db.cartsDao.createCart('INV-2-202', branchId: 2);
      await db.cartsDao.addCartItem(
        CartItemsCompanion.insert(
          cartId: cartId,
          itemId: 100,
          quantity: 1,
          total: const Value(10),
          itemName: const Value('A'),
        ),
      );
      await db.cartsDao.addCartItem(
        CartItemsCompanion.insert(
          cartId: cartB,
          itemId: 101,
          quantity: 1,
          total: const Value(5),
          itemName: const Value('B'),
        ),
      );
      await db.cartsDao.addCartItem(
        CartItemsCompanion.insert(
          cartId: cartB,
          itemId: 101,
          quantity: 1,
          total: const Value(5),
          itemName: const Value('C'),
        ),
      );

      final counts = await db.cartsDao.countCartItemsByCartIds([cartId, cartB]);
      expect(counts[cartId], 1);
      expect(counts[cartB], 2);
    });
  });

  group('OrdersDao', () {
    late int cartId;

    setUp(() async {
      cartId = await db.cartsDao.createCart('INV-2-300', branchId: 2);
    });

    Future<int> insertOrder({
      String invoice = 'INV-2-300',
      String status = 'completed',
      int branchId = 2,
      DateTime? createdAt,
      String? serverOrderId,
    }) {
      return db.ordersDao.createOrder(
        OrdersCompanion.insert(
          cartId: cartId,
          invoiceNumber: invoice,
          totalAmount: 50,
          finalAmount: 50,
          createdAt: createdAt ?? DateTime.utc(2026, 5, 17, 10),
          status: Value(status),
          orderType: const Value('take_away'),
          branchId: Value(branchId),
          cashAmount: const Value(50),
          serverOrderId: serverOrderId == null ? const Value.absent() : Value(serverOrderId),
        ),
      );
    }

    test('insert get order by id and server id', () async {
      final orderId = await insertOrder(serverOrderId: 'hub-abc');
      final row = await db.ordersDao.getOrderById(orderId);
      expect(row, isNotNull);
      expect(row!.invoiceNumber, 'INV-2-300');
      expect(row.branchId, 2);
      expect(row.serverOrderId, 'hub-abc');

      expect((await db.ordersDao.getOrderByServerId('hub-abc'))?.id, orderId);
      expect(await db.ordersDao.getOrderById(99999), isNull);
    });

    test('getAllOrders filters by branchId', () async {
      final cartB1 = await db.cartsDao.createCart('INV-1-001', branchId: 1);
      await insertOrder(invoice: 'INV-2-301', branchId: 2);
      await db.ordersDao.createOrder(
        OrdersCompanion.insert(
          cartId: cartB1,
          invoiceNumber: 'INV-1-001',
          totalAmount: 20,
          finalAmount: 20,
          createdAt: DateTime.utc(2026, 5, 17, 11),
          status: const Value('completed'),
          branchId: const Value(1),
        ),
      );

      final branch2 = await db.ordersDao.getAllOrders(branchId: 2);
      final branch1 = await db.ordersDao.getAllOrders(branchId: 1);
      expect(branch2.any((o) => o.invoiceNumber == 'INV-2-301'), isTrue);
      expect(branch2.any((o) => o.invoiceNumber == 'INV-1-001'), isFalse);
      expect(branch1.any((o) => o.invoiceNumber == 'INV-1-001'), isTrue);
    });

    test('updateOrderStatus and updateOrder modify row', () async {
      final orderId = await insertOrder(status: 'kot');
      await db.ordersDao.updateOrderStatus(orderId, 'completed');
      var row = await db.ordersDao.getOrderById(orderId);
      expect(row?.status, 'completed');

      await db.ordersDao.updateOrder(
        OrdersCompanion(
          id: Value(orderId),
          customerName: const Value('Ali'),
          finalAmount: const Value(45),
        ),
      );
      row = await db.ordersDao.getOrderById(orderId);
      expect(row?.customerName, 'Ali');
      expect(row?.finalAmount, 45);
    });

    test('deleteOrder removes row', () async {
      final orderId = await insertOrder(invoice: 'INV-2-302');
      await db.ordersDao.deleteOrder(orderId);
      expect(await db.ordersDao.getOrderById(orderId), isNull);
    });

    test('getOrdersByDateRange returns orders in window', () async {
      await insertOrder(
        invoice: 'INV-2-303',
        createdAt: DateTime.utc(2026, 5, 16, 12),
      );
      await insertOrder(
        invoice: 'INV-2-304',
        createdAt: DateTime.utc(2026, 5, 17, 14),
      );
      await insertOrder(
        invoice: 'INV-2-305b',
        createdAt: DateTime.utc(2026, 5, 18, 12),
      );

      final inRange = await db.ordersDao.getOrdersByDateRange(
        DateTime.utc(2026, 5, 17),
        DateTime.utc(2026, 5, 17, 23, 59, 59),
        branchId: 2,
      );
      expect(inRange.any((o) => o.invoiceNumber == 'INV-2-304'), isTrue);
      expect(inRange.any((o) => o.invoiceNumber == 'INV-2-303'), isFalse);
      expect(inRange.any((o) => o.invoiceNumber == 'INV-2-305b'), isFalse);
    });

    test('filterOrders by invoice status and orderType', () async {
      await insertOrder(invoice: 'INV-2-306a', status: 'completed');
      await insertOrder(invoice: 'INV-2-306', status: 'kot');

      final completed = await db.ordersDao.filterOrders(
        branchId: 2,
        status: 'completed',
        invoiceNumber: '306a',
      );
      expect(completed, hasLength(1));
      expect(completed.single.invoiceNumber, 'INV-2-306a');

      final kots = await db.ordersDao.filterOrders(branchId: 2, status: 'kot');
      expect(kots.any((o) => o.invoiceNumber == 'INV-2-306'), isTrue);
    });

    test('filterOrdersForList omits hubMetadata from memory', () async {
      final orderId = await insertOrder(invoice: 'INV-2-306b', status: 'completed');
      await (db.update(db.orders)..where((o) => o.id.equals(orderId))).write(
        const OrdersCompanion(
          hubMetadata: Value('{"snapshot":{"items":[]},"updatedAt":1}'),
        ),
      );
      final full = await db.ordersDao.getOrderById(orderId);
      expect(full?.hubMetadata, isNotNull);

      final listed = await db.ordersDao.filterOrdersForList(
        branchId: 2,
        status: 'completed',
        invoiceNumber: '306b',
      );
      expect(listed, hasLength(1));
      expect(listed.single.hubMetadata, isNull);
    });

    test('onlyRecentSaleSettled includes paid placed, excludes kot and unpaid placed', () async {
      await db.ordersDao.createOrder(
        OrdersCompanion.insert(
          cartId: cartId,
          invoiceNumber: 'INV-RS-PAID',
          totalAmount: 100,
          finalAmount: 100,
          cashAmount: const Value(100),
          creditAmount: const Value(0),
          cardAmount: const Value(0),
          onlineAmount: const Value(0),
          createdAt: DateTime.utc(2026, 5, 18, 12),
          status: const Value('placed'),
          branchId: const Value(2),
        ),
      );
      await db.ordersDao.createOrder(
        OrdersCompanion.insert(
          cartId: cartId,
          invoiceNumber: 'INV-RS-UP',
          totalAmount: 100,
          finalAmount: 100,
          cashAmount: const Value(0),
          createdAt: DateTime.utc(2026, 5, 18, 13),
          status: const Value('placed'),
          branchId: const Value(2),
        ),
      );
      await db.ordersDao.createOrder(
        OrdersCompanion.insert(
          cartId: cartId,
          invoiceNumber: 'INV-RS-KOT',
          totalAmount: 50,
          finalAmount: 50,
          createdAt: DateTime.utc(2026, 5, 18, 14),
          status: const Value('kot'),
          branchId: const Value(2),
        ),
      );

      final rows = await db.ordersDao.filterOrdersForList(
        branchId: 2,
        onlyRecentSaleSettled: true,
        invoiceNumber: 'INV-RS',
      );
      final invs = rows.map((e) => e.invoiceNumber).toSet();
      expect(invs.contains('INV-RS-PAID'), isTrue);
      expect(invs.contains('INV-RS-KOT'), isFalse);
      expect(invs.contains('INV-RS-UP'), isFalse);

      final cnt = await db.ordersDao.countOrdersForList(
        branchId: 2,
        onlyRecentSaleSettled: true,
        invoiceNumber: 'INV-RS',
      );
      expect(cnt, rows.length);
    });

    test('setHubCorrelationIfUnset writes serverOrderId once', () async {
      final orderId = await insertOrder(invoice: 'INV-2-307');
      await db.ordersDao.setHubCorrelationIfUnset(
        orderId: orderId,
        correlationId: 'hub-first',
      );
      await db.ordersDao.setHubCorrelationIfUnset(
        orderId: orderId,
        correlationId: 'hub-second',
      );
      final row = await db.ordersDao.getOrderById(orderId);
      expect(row?.serverOrderId, 'hub-first');
    });

    test('getDistinctCashierUserIdsForBranch', () async {
      await db.ordersDao.createOrder(
        OrdersCompanion.insert(
          cartId: cartId,
          invoiceNumber: 'INV-2-308',
          totalAmount: 10,
          finalAmount: 10,
          createdAt: DateTime.utc(2026, 5, 17),
          status: const Value('completed'),
          branchId: const Value(2),
          userId: const Value(1),
        ),
      );
      final ids = await db.ordersDao.getDistinctCashierUserIdsForBranch(2);
      expect(ids, contains(1));
    });
  });

  group('OrderLogs (OrdersDao)', () {
    test('insert get update delete order logs', () async {
      final cartId = await db.cartsDao.createCart('INV-2-400', branchId: 2);
      final orderId = await db.ordersDao.createOrder(
        OrdersCompanion.insert(
          cartId: cartId,
          invoiceNumber: 'INV-2-400',
          totalAmount: 10,
          finalAmount: 10,
          createdAt: DateTime.utc(2026, 5, 17),
          status: const Value('completed'),
          branchId: const Value(2),
        ),
      );

      final payload = jsonEncode({'order_id': orderId, 'items': []});
      final logId = await db.ordersDao.insertOrderLog(payload);

      final unsynced = await db.ordersDao.getUnsyncedOrderLogs();
      expect(unsynced.any((l) => l.id == logId), isTrue);

      final latest = await db.ordersDao.findLatestOrderLogByLocalOrderId(orderId);
      expect(latest?.orderJson, payload);

      final byLocal = await db.ordersDao.findUnsyncedLogByLocalOrderId(orderId);
      expect(byLocal?.id, logId);

      await db.ordersDao.updateOrderLogPayload(logId, '{"order_id":$orderId,"items":[{"item_name":"X"}]}');
      final updated = await db.ordersDao.findLatestOrderLogByLocalOrderId(orderId);
      expect(updated?.orderJson, contains('X'));

      await db.ordersDao.markOrderLogsSynced([logId]);
      expect((await db.ordersDao.getUnsyncedOrderLogs()).any((l) => l.id == logId), isFalse);

      await db.ordersDao.setOrderLogsSyncedState([logId], synced: false);
      expect((await db.ordersDao.getUnsyncedOrderLogs()).any((l) => l.id == logId), isTrue);

      await db.ordersDao.deleteOrderLogsForLocalOrderId(orderId);
      expect(await db.ordersDao.findLatestOrderLogByLocalOrderId(orderId), isNull);

      final logId2 = await db.ordersDao.insertOrderLog(payload);
      await db.ordersDao.deleteOrderLogById(logId2);
      expect(await db.ordersDao.findLatestOrderLogByLocalOrderId(orderId), isNull);
    });
  });

  group('CartRepositoryImpl', () {
    late CartRepositoryImpl repo;

    setUp(() {
      repo = CartRepositoryImpl(db);
    });

    test('create add get update delete cart and items', () async {
      final cartId = await repo.createCart('INV-2-500', branchId: 2);
      expect((await repo.getCartByInvoice('INV-2-500'))?.id, cartId);

      final lineId = await repo.addItemToCart(
        cartId,
        CartItem(
          id: 0,
          cartId: cartId,
          itemId: 100,
          itemName: 'Burger',
          quantity: 1,
          total: 50,
          discount: 0,
        ),
      );

      var lines = await repo.getCartItemsByCartId(cartId);
      expect(lines, hasLength(1));

      await repo.updateCartItemTotal(lineId, 48);
      lines = await repo.getCartItemsByCartId(cartId);
      expect(lines!.single.total, 48);

      await repo.updateCartItem(
        CartItem(
          id: lineId,
          cartId: cartId,
          itemId: 100,
          itemName: 'Burger XL',
          quantity: 2,
          total: 90,
          discount: 0,
        ),
      );
      lines = await repo.getCartItemsByCartId(cartId);
      expect(lines!.single.quantity, 2);
      expect(lines.single.itemName, 'Burger XL');

      await repo.removeCartItem(lineId);
      expect(await repo.getCartItemsByCartId(cartId), isEmpty);

      await repo.deleteCart(cartId);
      expect(await repo.getCartByCartId(cartId), isNull);
    });

    test('getAllCarts lists persisted carts', () async {
      await repo.createCart('INV-2-501', branchId: 2);
      await repo.createCart('INV-2-502', branchId: 2);
      final all = await repo.getAllCarts();
      expect(all.length, greaterThanOrEqualTo(2));
    });
  });

  group('OrderRepositoryImpl', () {
    late OrderRepositoryImpl repo;

    setUp(() {
      repo = OrderRepositoryImpl(db);
    });

    Future<({int cartId, String invoice})> newCartWithLine() async {
      final r = await repo.createCartWithReservedInvoice(orderType: 'take_away');
      await db.into(db.cartItems).insert(
            CartItemsCompanion.insert(
              cartId: r.cartId,
              itemId: 100,
              quantity: 1,
              total: const Value(25),
              itemName: const Value('Burger'),
            ),
          );
      return r;
    }

    test('createOrder insert and getOrderById', () async {
      final r = await newCartWithLine();
      final id = await repo.createOrder(
        Order(
          id: 0,
          cartId: r.cartId,
          invoiceNumber: r.invoice,
          totalAmount: 25,
          discountAmount: 0,
          finalAmount: 25,
          cashAmount: 25,
          creditAmount: 0,
          cardAmount: 0,
          onlineAmount: 0,
          createdAt: DateTime.utc(2026, 5, 17, 14),
          status: 'completed',
          orderType: 'take_away',
          branchId: 2,
          hubSyncPending: false,
        ),
      );

      final saved = await repo.getOrderById(id);
      expect(saved, isNotNull);
      expect(saved!.invoiceNumber, r.invoice);
      expect(saved.hubMetadata, isNotNull);
    });

    test('getAllOrders returns branch-scoped completed sales', () async {
      final r = await newCartWithLine();
      await repo.createOrder(
        Order(
          id: 0,
          cartId: r.cartId,
          invoiceNumber: r.invoice,
          totalAmount: 25,
          discountAmount: 0,
          finalAmount: 25,
          cashAmount: 25,
          creditAmount: 0,
          cardAmount: 0,
          onlineAmount: 0,
          createdAt: DateTime.utc(2026, 5, 17, 15),
          status: 'completed',
          orderType: 'take_away',
          branchId: 2,
          hubSyncPending: false,
        ),
      );

      final all = await repo.getAllOrders();
      expect(all.any((o) => o.invoiceNumber == r.invoice), isTrue);
    });

    test('updateOrder updates totals in database', () async {
      final r = await newCartWithLine();
      final id = await repo.createOrder(
        Order(
          id: 0,
          cartId: r.cartId,
          invoiceNumber: r.invoice,
          totalAmount: 25,
          discountAmount: 0,
          finalAmount: 25,
          cashAmount: 25,
          creditAmount: 0,
          cardAmount: 0,
          onlineAmount: 0,
          createdAt: DateTime.utc(2026, 5, 17, 14),
          status: 'completed',
          orderType: 'take_away',
          branchId: 2,
          hubSyncPending: false,
        ),
      );

      final existing = (await repo.getOrderById(id))!;
      await repo.updateOrder(
        Order(
          id: existing.id,
          cartId: existing.cartId,
          invoiceNumber: existing.invoiceNumber,
          totalAmount: 30,
          discountAmount: 5,
          discountType: 'amount',
          finalAmount: 25,
          cashAmount: 25,
          creditAmount: 0,
          cardAmount: 0,
          onlineAmount: 0,
          createdAt: existing.createdAt,
          status: existing.status,
          orderType: existing.orderType,
          branchId: existing.branchId,
          hubSyncPending: false,
          customerName: 'Sara',
        ),
      );

      final updated = await repo.getOrderById(id);
      expect(updated?.totalAmount, 30);
      expect(updated?.customerName, 'Sara');
    });

    test('updateOrderStatus changes status', () async {
      final r = await newCartWithLine();
      final id = await repo.createOrder(
        Order(
          id: 0,
          cartId: r.cartId,
          invoiceNumber: r.invoice,
          totalAmount: 25,
          discountAmount: 0,
          finalAmount: 25,
          cashAmount: 0,
          creditAmount: 0,
          cardAmount: 0,
          onlineAmount: 0,
          createdAt: DateTime.utc(2026, 5, 17, 14),
          status: 'kot',
          orderType: 'dine_in',
          branchId: 2,
          hubSyncPending: false,
        ),
      );

      await repo.updateOrderStatus(id, 'completed');
      expect((await repo.getOrderById(id))?.status, 'completed');
    });

    test('deleteOrder removes order from database', () async {
      final r = await newCartWithLine();
      final id = await repo.createOrder(
        Order(
          id: 0,
          cartId: r.cartId,
          invoiceNumber: r.invoice,
          totalAmount: 25,
          discountAmount: 0,
          finalAmount: 25,
          cashAmount: 25,
          creditAmount: 0,
          cardAmount: 0,
          onlineAmount: 0,
          createdAt: DateTime.utc(2026, 5, 17, 14),
          status: 'completed',
          orderType: 'take_away',
          branchId: 2,
          hubSyncPending: false,
        ),
      );

      await repo.deleteOrder(id);
      expect(await repo.getOrderById(id), isNull);
    });

    test('filterOrders and getOrdersByDateRange', () async {
      final r = await newCartWithLine();
      await repo.createOrder(
        Order(
          id: 0,
          cartId: r.cartId,
          invoiceNumber: r.invoice,
          totalAmount: 25,
          discountAmount: 0,
          finalAmount: 25,
          cashAmount: 25,
          creditAmount: 0,
          cardAmount: 0,
          onlineAmount: 0,
          createdAt: DateTime.utc(2026, 5, 17, 16),
          status: 'completed',
          orderType: 'take_away',
          branchId: 2,
          hubSyncPending: false,
          customerPhone: '0501234567',
        ),
      );

      final filtered = await repo.filterOrders(
        invoiceNumber: r.invoice.substring(r.invoice.length - 3),
        status: 'completed',
        customerPhone: '050123',
      );
      expect(filtered.any((o) => o.invoiceNumber == r.invoice), isTrue);

      final byDate = await repo.getOrdersByDateRange(
        DateTime.utc(2026, 5, 17),
        DateTime.utc(2026, 5, 17, 23, 59, 59),
      );
      expect(byDate.any((o) => o.invoiceNumber == r.invoice), isTrue);
    });

    test('getCreditSales returns orders with credit amount', () async {
      final r = await newCartWithLine();
      await repo.createOrder(
        Order(
          id: 0,
          cartId: r.cartId,
          invoiceNumber: r.invoice,
          totalAmount: 25,
          discountAmount: 0,
          finalAmount: 25,
          cashAmount: 0,
          creditAmount: 25,
          cardAmount: 0,
          onlineAmount: 0,
          createdAt: DateTime.utc(2026, 5, 17, 14),
          status: 'completed',
          orderType: 'take_away',
          branchId: 2,
          hubSyncPending: false,
        ),
      );

      final credit = await repo.getCreditSales();
      expect(credit.any((o) => o.invoiceNumber == r.invoice), isTrue);
    });

    test('getCreditSales includes inferred credit when credit_amount is zero', () async {
      final r = await newCartWithLine();
      await repo.createOrder(
        Order(
          id: 0,
          cartId: r.cartId,
          invoiceNumber: '${r.invoice}-INF',
          totalAmount: 40,
          discountAmount: 0,
          finalAmount: 40,
          cashAmount: 10,
          creditAmount: 0,
          cardAmount: 0,
          onlineAmount: 0,
          createdAt: DateTime.utc(2026, 5, 17, 15),
          status: 'completed',
          orderType: 'take_away',
          branchId: 2,
          hubSyncPending: false,
        ),
      );

      final credit = await repo.getCreditSales();
      expect(credit.any((o) => o.invoiceNumber == '${r.invoice}-INF'), isTrue);
    });
  });
}
