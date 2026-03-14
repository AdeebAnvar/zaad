import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'drift_database.g.dart';
part 'dao/users_dao.dart';
part 'dao/category_dao.dart';
part 'dao/item_dao.dart';
part 'dao/session_dao.dart';
part 'dao/cart_dao.dart';
part 'dao/orders_dao.dart';
part 'dao/customers_dao.dart';

@DriftDatabase(
  tables: [
    Users,
    Categories,
    Kitchens,
    KitchenPrinters,
    Items,
    ItemVariants,
    ItemToppings,
    ToppingGroups,
    Sessions,
    Carts,
    CartItems,
    Orders,
    Customers,
  ],
  daos: [
    UsersDao,
    CategoryDao,
    CartsDao,
    ItemDao,
    SessionDao,
    OrdersDao,
    CustomersDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        Future<void> safeAddColumn(dynamic table, dynamic column) async {
          try {
            await m.addColumn(table, column);
          } on SqliteException catch (e) {
            if (e.resultCode != 1 ||
                !e.message.toLowerCase().contains('duplicate column')) {
              rethrow;
            }
          }
        }
        if (from < 2) {
          // Add Orders table
          await m.createTable(orders);
        }
        if (from < 3) {
          // Add new columns to Orders table
          await m.addColumn(orders, orders.discountAmount);
          await m.addColumn(orders, orders.discountType);
          await m.addColumn(orders, orders.finalAmount);
          await m.addColumn(orders, orders.customerName);
          await m.addColumn(orders, orders.customerEmail);
          await m.addColumn(orders, orders.customerPhone);
          await m.addColumn(orders, orders.customerGender);
          await m.addColumn(orders, orders.cashAmount);
          await m.addColumn(orders, orders.creditAmount);
          await m.addColumn(orders, orders.cardAmount);
        }
        if (from < 4) {
          // Add notes and discountType to CartItems table
          await m.addColumn(cartItems, cartItems.discountType);
          await m.addColumn(cartItems, cartItems.notes);
        }
        if (from < 5) {
          // Add maximum column to ItemToppings table
          await m.addColumn(itemToppings, itemToppings.maximum);
        }
        if (from < 6) {
          // Add Customers table
          await m.createTable(customers);
        }
        if (from < 7) {
          // Persist active cart id in session (so cart survives navigation/reload)
          await safeAddColumn(sessions, sessions.activeCartId);
        }
        if (from < 8) {
          // Add Kitchens table and kitchen columns to Items
          await m.createTable(kitchens);
          await safeAddColumn(items, items.kitchenId);
          await safeAddColumn(items, items.kitchenName);
        }
        if (from < 9) {
          // Add KitchenPrinters table for printer IP/port per kitchen (kitchen_id=0 = bill printer)
          await m.createTable(kitchenPrinters);
        }
        if (from < 10) {
          // Add printer IP/port to Kitchens table for device–printer connection
          await safeAddColumn(kitchens, kitchens.printerIp);
          await safeAddColumn(kitchens, kitchens.printerPort);
        }
      },
    );
  }
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'pos.sqlite'));
    return NativeDatabase(file);
  });
}
