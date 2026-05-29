import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/utils/order_log_cart_fallback.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository_impl/cart_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'helpers/sales_integrity_fixtures.dart';

void main() {
  group('OrderLogCartFallback.resolve priority', () {
    late AppDatabase db;
    late CartRepositoryImpl cartRepo;

    setUp(() {
      db = AppDatabase.memory();
      cartRepo = CartRepositoryImpl(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<Order> orderWith({
      required int cartId,
      String? hubMetadata,
      int id = 1,
    }) async {
      final oid = await db.ordersDao.createOrder(
        OrdersCompanion.insert(
          cartId: cartId,
          invoiceNumber: 'INV-2-001',
          totalAmount: 10,
          finalAmount: 10,
          createdAt: DateTime.utc(2026, 5, 17),
          status: const Value('completed'),
          branchId: const Value(2),
          hubMetadata: hubMetadata == null ? const Value.absent() : Value(hubMetadata),
        ),
      );
      return (await db.ordersDao.getOrderById(oid))!;
    }

    test('hubMetadata beats live cart and OrderLog', () async {
      final cartId = await db.cartsDao.createCart('c1', branchId: 2);
      await db.into(db.cartItems).insert(
            CartItemsCompanion.insert(
              cartId: cartId,
              itemId: 9,
              quantity: 1,
              total: const Value(1),
              itemName: const Value('Live Wrong'),
            ),
          );
      final o = await orderWith(
        cartId: cartId,
        hubMetadata: hubMetadataItemsJson([lineSnapshot(itemId: 1, name: 'From Hub')]),
      );
      await db.ordersDao.insertOrderLog(
        orderLogJson(orderId: o.id, items: [lineSnapshot(itemId: 2, name: 'From Log')]),
      );

      final lines = await OrderLogCartFallback.resolve(order: o, db: db, cartRepo: cartRepo);
      expect(lines.single.itemName, 'From Hub');
    });

    test('OrderLog beats live cart when hubMetadata empty', () async {
      final cartId = await db.cartsDao.createCart('c2', branchId: 2);
      await db.into(db.cartItems).insert(
            CartItemsCompanion.insert(
              cartId: cartId,
              itemId: 9,
              quantity: 1,
              total: const Value(1),
              itemName: const Value('Live Wrong'),
            ),
          );
      final o = await orderWith(cartId: cartId);
      await db.ordersDao.insertOrderLog(
        orderLogJson(orderId: o.id, items: [lineSnapshot(itemId: 2, name: 'From Log')]),
      );

      final lines = await OrderLogCartFallback.resolve(order: o, db: db, cartRepo: cartRepo);
      expect(lines.single.itemName, 'From Log');
    });

    test('unique cart uses live lines when no snapshot', () async {
      final cartId = await db.cartsDao.createCart('c3', branchId: 2);
      await db.into(db.cartItems).insert(
            CartItemsCompanion.insert(
              cartId: cartId,
              itemId: 5,
              quantity: 1,
              total: const Value(20),
              itemName: const Value('Live OK'),
            ),
          );
      final o = await orderWith(cartId: cartId);
      final lines = await OrderLogCartFallback.resolve(order: o, db: db, cartRepo: cartRepo);
      expect(lines.single.itemName, 'Live OK');
    });

    test('shadow cart skips live cart when snapshots missing', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final settings = LocalHubSettings(prefs);

      final cartId = await db.cartsDao.createCart('_shadow', branchId: 2);
      await settings.cacheShadowCartId(cartId);
      GetIt.instance.registerSingleton<LocalHubSettings>(settings);
      addTearDown(() async {
        if (GetIt.instance.isRegistered<LocalHubSettings>()) {
          await GetIt.instance.unregister<LocalHubSettings>();
        }
      });

      await db.into(db.cartItems).insert(
            CartItemsCompanion.insert(
              cartId: cartId,
              itemId: 9,
              quantity: 1,
              total: const Value(1),
              itemName: const Value('Shadow Live'),
            ),
          );
      final o = await orderWith(cartId: cartId);

      final lines = await OrderLogCartFallback.resolve(order: o, db: db, cartRepo: cartRepo);
      expect(lines, isEmpty);
    });
  });

  group('OrderLogCartFallback.decode payloads', () {
    const cartId = 42;

    test('snapshot.items envelope', () {
      final json = hubMetadataItemsJson([lineSnapshot(itemId: 1, name: 'A')]);
      final lines = OrderLogCartFallback.decodeCartItemsFromPayloadJson(json, cartId);
      expect(lines.single.itemName, 'A');
      expect(lines.single.cartId, cartId);
    });

    test('top-level items array', () {
      final json = jsonEncode(<String, dynamic>{
        'items': [lineSnapshot(itemId: 2, name: 'B')],
      });
      final lines = OrderLogCartFallback.decodeCartItemsFromPayloadJson(json, cartId);
      expect(lines.single.itemName, 'B');
    });

    test('metadata.cart_lines', () {
      final json = jsonEncode(<String, dynamic>{
        'metadata': <String, dynamic>{
          'cart_lines': [
            <String, dynamic>{'itemId': 3, 'itemName': 'C', 'quantity': 2, 'total': 20},
          ],
        },
      });
      final lines = OrderLogCartFallback.decodeCartItemsFromPayloadJson(json, cartId);
      expect(lines.single.itemName, 'C');
      expect(lines.single.quantity, 2);
    });

    test('metadata.flutter.items', () {
      final json = jsonEncode(<String, dynamic>{
        'metadata': <String, dynamic>{
          'flutter': <String, dynamic>{
            'items': [lineSnapshot(itemId: 4, name: 'D')],
          },
        },
      });
      final lines = OrderLogCartFallback.decodeCartItemsFromPayloadJson(json, cartId);
      expect(lines.single.itemName, 'D');
    });

    test('unitPriceCents computes total when total missing', () {
      final line = OrderLogCartFallback.snapshotLineToCartItem(
        <String, dynamic>{
          'item_name': 'Cents Item',
          'quantity': 2,
          'unit_price_cents': 150,
        },
        cartId,
        -1,
      );
      expect(line.total, closeTo(3.0, 0.001));
      expect(line.itemName, 'Cents Item');
    });

    test('malformed json returns empty list', () {
      expect(OrderLogCartFallback.decodeCartItemsFromPayloadJson('not-json', cartId), isEmpty);
    });
  });
}
