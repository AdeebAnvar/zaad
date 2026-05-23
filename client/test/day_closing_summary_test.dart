import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository_impl/settle_sale_push_mapper.dart';
import 'package:pos/presentation/day_closing/day_closing_summary.dart';

void main() {
  test(
    'computeDayClosingSummary: line item discount does not inflate excess vs payments',
    () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);

      await _seedMinimalCatalogAndSession(db);

      final cartId = await db.cartsDao.createCart('INV-T1', branchId: 1);
      await db.into(db.cartItems).insert(
            CartItemsCompanion.insert(
              cartId: cartId,
              itemId: 1,
              quantity: 1,
              total: const Value(90),
              discount: const Value(10),
              itemName: const Value('Burger'),
            ),
          );

      await db.ordersDao.createOrder(
        OrdersCompanion.insert(
          cartId: cartId,
          invoiceNumber: 'INV-T1',
          totalAmount: 90,
          finalAmount: 90,
          discountAmount: const Value(0),
          discountType: const Value(null),
          createdAt: DateTime(2026, 1, 15, 10),
          status: const Value('completed'),
          orderType: const Value('take_away'),
          branchId: const Value(1),
          cashAmount: const Value(90),
          cardAmount: const Value(0),
          creditAmount: const Value(0),
          onlineAmount: const Value(0),
          userId: const Value(1),
        ),
      );

      final summary = await computeDayClosingSummary(db);
      expect(summary.netTotal, closeTo(90, 0.01));
      expect(summary.discount, closeTo(10, 0.01));
      expect(summary.grossTotal, closeTo(100, 0.01));
      expect(summary.categoryRows, hasLength(1));
      expect(summary.categoryRows.single.qty, 1);
      expect(summary.categoryRows.single.amount, closeTo(90, 0.01));
      expect(summary.shortAmount, 0.0);
      expect(summary.excessAmount, closeTo(0, 0.02));

      final payload = SettleSalePushMapper.buildSettleSalePayload(
        summary,
        uuid: 'test-uuid',
        branchId: 1,
        userId: 1,
        at: DateTime.utc(2026, 1, 15, 10),
      );
      final catDecoded = (jsonDecode(payload['category_wise_product_list'] as String) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(catDecoded, hasLength(1));
      expect(catDecoded.single['qty'], 1);
      expect(catDecoded.single['amount'], closeTo(90, 0.01));
      expect(payload.containsKey('item_wise_product_list'), isFalse);
    },
  );

  test(
    'computeDayClosingSummary: line discount plus cart-level discount matches payment',
    () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);

      await _seedMinimalCatalogAndSession(db);

      final cartId = await db.cartsDao.createCart('INV-T2', branchId: 1);
      await db.into(db.cartItems).insert(
            CartItemsCompanion.insert(
              cartId: cartId,
              itemId: 1,
              quantity: 1,
              total: const Value(90),
              discount: const Value(10),
              itemName: const Value('Burger'),
            ),
          );

      await db.ordersDao.createOrder(
        OrdersCompanion.insert(
          cartId: cartId,
          invoiceNumber: 'INV-T2',
          totalAmount: 90,
          finalAmount: 81,
          discountAmount: const Value(9),
          discountType: const Value('amount'),
          createdAt: DateTime(2026, 1, 15, 11),
          status: const Value('completed'),
          orderType: const Value('take_away'),
          branchId: const Value(1),
          cashAmount: const Value(81),
          cardAmount: const Value(0),
          creditAmount: const Value(0),
          onlineAmount: const Value(0),
          userId: const Value(1),
        ),
      );

      final summary = await computeDayClosingSummary(db);
      expect(summary.netTotal, closeTo(81, 0.01));
      expect(summary.discount, closeTo(19, 0.01));
      expect(summary.grossTotal, closeTo(100, 0.01));
      expect(summary.excessAmount, closeTo(0, 0.02));
      expect(summary.shortAmount, closeTo(0, 0.02));
    },
  );

  test(
    'computeDayClosingSummary: credit collected after day close appears in cash sale',
    () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);

      await _seedMinimalCatalogAndSession(db);

      final closedAt = DateTime(2026, 1, 15, 18);
      await db.dayClosingCheckpointDao.upsertLastSettledAt(1, closedAt);

      final cartId = await db.cartsDao.createCart('INV-CR', branchId: 1);
      await db.into(db.cartItems).insert(
            CartItemsCompanion.insert(
              cartId: cartId,
              itemId: 1,
              quantity: 1,
              total: const Value(100),
              itemName: const Value('Burger'),
            ),
          );

      final saleAt = DateTime(2026, 1, 15, 10);
      final paidAt = DateTime(2026, 1, 15, 19);
      final orderId = await db.ordersDao.createOrder(
        OrdersCompanion.insert(
          cartId: cartId,
          invoiceNumber: 'INV-CR',
          totalAmount: 100,
          finalAmount: 100,
          createdAt: saleAt,
          status: const Value('completed'),
          orderType: const Value('take_away'),
          branchId: const Value(1),
          cashAmount: const Value(0),
          cardAmount: const Value(0),
          creditAmount: const Value(100),
          onlineAmount: const Value(0),
          userId: const Value(1),
        ),
      );

      await db.ordersDao.updateOrder(
        OrdersCompanion(
          id: Value(orderId),
          cashAmount: const Value(100),
          creditAmount: const Value(0),
          hubMetadata: Value(
            jsonEncode(<String, dynamic>{
              'updatedAt': paidAt.millisecondsSinceEpoch,
              'creditPayments': [
                <String, dynamic>{
                  'at': paidAt.millisecondsSinceEpoch,
                  'amount': 100,
                  'type': 'cash',
                },
              ],
            }),
          ),
        ),
      );

      final summary = await computeDayClosingSummary(db);
      expect(summary.cashSale, closeTo(100, 0.01));
      expect(summary.creditRecovery, closeTo(100, 0.01));
      expect(summary.creditSale, 0.0);
      expect(summary.netTotal, 0.0);
    },
  );

  test(
    'computeDayClosingSummary: billed gap includes offer when discount_amount under-reports',
    () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);

      await _seedMinimalCatalogAndSession(db);

      final cartId = await db.cartsDao.createCart('INV-T3', branchId: 1);
      await db.into(db.cartItems).insert(
            CartItemsCompanion.insert(
              cartId: cartId,
              itemId: 1,
              quantity: 1,
              total: const Value(100),
              discount: const Value(0),
              itemName: const Value('Burger'),
            ),
          );

      // totalAmount 100, stored discount_amount too small (e.g. manual only), final reflects offer too.
      await db.ordersDao.createOrder(
        OrdersCompanion.insert(
          cartId: cartId,
          invoiceNumber: 'INV-T3',
          totalAmount: 100,
          finalAmount: 80,
          discountAmount: const Value(5),
          discountType: const Value('amount'),
          createdAt: DateTime(2026, 1, 15, 12),
          status: const Value('completed'),
          orderType: const Value('take_away'),
          branchId: const Value(1),
          cashAmount: const Value(80),
          cardAmount: const Value(0),
          creditAmount: const Value(0),
          onlineAmount: const Value(0),
          userId: const Value(1),
        ),
      );

      final summary = await computeDayClosingSummary(db);
      expect(summary.netTotal, closeTo(80, 0.01));
      expect(summary.discount, closeTo(20, 0.01));
      expect(summary.grossTotal, closeTo(100, 0.01));
      expect(summary.excessAmount, closeTo(0, 0.02));
      expect(summary.shortAmount, closeTo(0, 0.02));
    },
  );

  test('computeDayClosingSummary: fully paid delivery pending is not unpaid', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await _seedMinimalCatalogAndSession(db);

    final cartId = await db.cartsDao.createCart('INV-D1', branchId: 1);
    await db.ordersDao.createOrder(
      OrdersCompanion.insert(
        cartId: cartId,
        invoiceNumber: 'INV-D1',
        totalAmount: 80,
        finalAmount: 80,
        discountAmount: const Value(0),
        createdAt: DateTime(2026, 1, 15, 14),
        status: const Value('pending'),
        orderType: const Value('delivery'),
        branchId: const Value(1),
        cashAmount: const Value(80),
        cardAmount: const Value(0),
        creditAmount: const Value(0),
        onlineAmount: const Value(0),
        userId: const Value(1),
      ),
    );

    final summary = await computeDayClosingSummary(db);
    expect(summary.unpaidAmount, closeTo(0, 0.02));
    expect(summary.openBills, isEmpty);
  });

  test('computeDayClosingSummary: unpaid delivery pending blocks unpaid total', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);
    await _seedMinimalCatalogAndSession(db);

    final cartId = await db.cartsDao.createCart('INV-D2', branchId: 1);
    await db.ordersDao.createOrder(
      OrdersCompanion.insert(
        cartId: cartId,
        invoiceNumber: 'INV-D2',
        totalAmount: 50,
        finalAmount: 50,
        discountAmount: const Value(0),
        createdAt: DateTime(2026, 1, 15, 14),
        status: const Value('pending'),
        orderType: const Value('delivery'),
        branchId: const Value(1),
        cashAmount: const Value(0),
        cardAmount: const Value(0),
        creditAmount: const Value(0),
        onlineAmount: const Value(0),
        userId: const Value(1),
      ),
    );

    final summary = await computeDayClosingSummary(db);
    expect(summary.unpaidAmount, closeTo(50, 0.02));
    expect(summary.openBills, hasLength(1));
  });

  test('computeSystemPaymentVariances splits collected-vs-net across channels', () {
    final variances = computeSystemPaymentVariances(
      cashExpected: 60,
      cardExpected: 40,
      creditExpected: 0,
      onlineExpected: 0,
      netTotal: 90,
    );
    expect(variances, hasLength(4));
    expect(variances.fold<double>(0, (s, v) => s + v.excess), closeTo(10, 0.02));
    expect(variances.fold<double>(0, (s, v) => s + v.short), closeTo(0, 0.02));
    final cash = variances.firstWhere((v) => v.channel == 'CASH');
    final card = variances.firstWhere((v) => v.channel == 'CARD');
    expect(cash.excess, closeTo(6, 0.02));
    expect(card.excess, closeTo(4, 0.02));
  });

  test('SettleSalePushMapper: close reconciliation overrides sales and drawer fields', () async {
    final db = AppDatabase.memory();
    addTearDown(db.close);

    await _seedMinimalCatalogAndSession(db);

    final cartId = await db.cartsDao.createCart('INV-R1', branchId: 1);
    await db.into(db.cartItems).insert(
          CartItemsCompanion.insert(
            cartId: cartId,
            itemId: 1,
            quantity: 1,
            total: const Value(90),
            discount: const Value(10),
            itemName: const Value('Burger'),
          ),
        );
    await db.ordersDao.createOrder(
      OrdersCompanion.insert(
        cartId: cartId,
        invoiceNumber: 'INV-R1',
        totalAmount: 90,
        finalAmount: 90,
        discountAmount: const Value(0),
        discountType: const Value(null),
        createdAt: DateTime(2026, 1, 15, 10),
        status: const Value('completed'),
        orderType: const Value('take_away'),
        branchId: const Value(1),
        cashAmount: const Value(90),
        cardAmount: const Value(0),
        creditAmount: const Value(0),
        onlineAmount: const Value(0),
        userId: const Value(1),
      ),
    );

    final summary = await computeDayClosingSummary(db);
    expect(summary.cashSaleAfterDiscount, closeTo(90, 0.01));

    final recon = DayClosingCloseReconciliation(
      cashExpected: summary.cashSaleAfterDiscount,
      cashExcess: 10,
      cashShort: 2,
      cardExpected: summary.cardSale,
      cardExcess: 0,
      cardShort: 0,
      creditExpected: summary.creditSale,
      creditExcess: 0,
      creditShort: 0,
      onlineExpected: summary.onlineSale,
      onlineExcess: 0,
      onlineShort: 0,
    );
    final payload = SettleSalePushMapper.buildSettleSalePayload(
      summary,
      uuid: 'u',
      branchId: 1,
      userId: 1,
      at: DateTime.utc(2026, 1, 15, 10),
      closeReconciliation: recon,
    );
    expect((payload['cash_sale'] as num).toDouble(), closeTo(98, 0.01));
    expect((payload['excess'] as num).toDouble(), 10);
    expect((payload['short'] as num).toDouble(), 2);
    expect(payload['payment_reconciliation'], isNotNull);
    expect((payload['cash_in'] as num).toDouble(), closeTo(98, 0.01));
    expect(double.parse(payload['cash_drawer'] as String), closeTo(98, 0.01));
  });
}

Future<void> _seedMinimalCatalogAndSession(AppDatabase db) async {
  final now = DateTime(2020, 1, 1);
  await db.into(db.branches).insert(
        BranchesCompanion.insert(
          id: const Value(1),
          branchName: 'Test',
          location: '-',
          contactNo: '-',
          vat: 'no_vat',
          prefixInv: 'T',
          invoiceHeader: 'Test',
          image: '',
          installationDate: now,
          expiryDate: now,
          openingCash: 0,
        ),
      );

  await db.into(db.categories).insert(
        CategoriesCompanion.insert(
          id: const Value(1),
          name: 'Food',
          otherName: 'Food',
          branchId: const Value(1),
        ),
      );

  await db.into(db.users).insert(
        UsersCompanion.insert(
          id: const Value(1),
          branchId: 1,
          name: 'Tester',
          usertype: 'staff',
          mobilePassword: '',
          permissions: '[]',
        ),
      );

  await db.sessionDao.saveSession(1, 'admin', 1);

  await db.into(db.items).insert(
        ItemsCompanion.insert(
          id: const Value(1),
          name: 'Burger',
          otherName: 'Burger',
          sku: 'SKU1',
          price: 100,
          stock: 99,
          categoryName: 'Food',
          categoryOtherName: 'Food',
          barcode: '',
          categoryId: 1,
        ),
      );
}
