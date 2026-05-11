import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:pos/data/local/drift_database.dart';
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
      expect(summary.shortAmount, 0.0);
      expect(summary.excessAmount, closeTo(0, 0.02));
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
      expect(summary.excessAmount, closeTo(0, 0.02));
      expect(summary.shortAmount, closeTo(0, 0.02));
    },
  );
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
