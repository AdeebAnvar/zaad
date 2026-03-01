import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
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
    Items,
    ItemVariants,
    ItemToppings,
    ToppingGroups,
    Sessions, // ✅ ADD
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
    SessionDao, // ✅ ADD
    OrdersDao,
    CustomersDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
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
          await m.addColumn(sessions, sessions.activeCartId);
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
