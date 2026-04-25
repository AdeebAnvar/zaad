import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:pos/core/constants/enums.dart';
import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/core/utils/image_utils.dart';
import 'package:pos/domain/models/branch_model.dart';
import 'package:pos/domain/models/settings_model.dart';
import 'package:pos/domain/models/user_model.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:path/path.dart' as p;

part 'drift_database.g.dart';
part 'dao/users_dao.dart';
part 'dao/category_dao.dart';
part 'dao/item_dao.dart';
part 'dao/session_dao.dart';
part 'dao/cart_dao.dart';
part 'dao/drivers_dao.dart';
part 'dao/orders_dao.dart';
part 'dao/customers_dao.dart';
part 'dao/delivery_partners_dao.dart';
part 'dao/dining_tables_dao.dart';
part 'dao/branches_dao.dart';
part 'dao/settings_dao.dart';
part 'dao/pull_data_dao.dart';

/// Used from `branches_dao` part; wraps [ImageUtils.downloadImage].
Future<String?> _downloadBranchImage(String url, String fileName) => ImageUtils.downloadImage(url, fileName);

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
    Drivers,
    Orders,
    OrderLogs,
    Customers,
    DeliveryPartners,
    DiningFloors,
    DiningTables,
    Branches,
    Settings,
    PullCategoryRows,
    PullFloorRows,
    PullDeliveryServiceRows,
    PullItemRows,
    SyncPaginationStates,
  ],
  daos: [
    UsersDao,
    CategoryDao,
    CartsDao,
    ItemDao,
    SessionDao,
    OrdersDao,
    CustomersDao,
    DeliveryPartnersDao,
    DriversDao,
    DiningTablesDao,
    BranchesDao,
    SettingsDao,
    PullDataDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  @override
  int get schemaVersion => 25;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        Future<void> safeAddColumn(dynamic table, dynamic column) async {
          try {
            await m.addColumn(table, column);
          } on SqliteException catch (e) {
            if (e.resultCode != 1 || !e.message.toLowerCase().contains('duplicate column')) {
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
        if (from < 11) {
          // Delivery: orderType, deliveryPartner on Carts & Orders; deliveryPartner on Items
          await m.addColumn(carts, carts.orderType);
          await m.addColumn(carts, carts.deliveryPartner);
          await m.addColumn(orders, orders.orderType);
          await m.addColumn(orders, orders.deliveryPartner);
          await m.addColumn(items, items.deliveryPartner);
        }
        if (from < 12) {
          // Delivery partners table - synced from server
          await m.createTable(deliveryPartners);
        }
        if (from < 13) {
          // Online payment for delivery orders
          await m.addColumn(orders, orders.onlineAmount);
        }
        if (from < 14) {
          await m.createTable(drivers);
          await safeAddColumn(orders, orders.driverId);
          await safeAddColumn(orders, orders.driverName);
        }
        if (from < 15) {
          await m.createTable(diningFloors);
          await m.createTable(diningTables);
        }
        if (from < 16) {
          await safeAddColumn(items, items.stockEnabled);
        }
        if (from < 19) {
          // Branches: cached logo path (see BranchesDao); column has SQL default in schema
          await safeAddColumn(branches, branches.localImage);
        }
        if (from < 20) {
          // Old installs had `sessions` without `branch_id`; Drift model always expected it.
          await safeAddColumn(sessions, sessions.branchId);
        }
        if (from < 21) {
          await safeAddColumn(customers, customers.address);
          await safeAddColumn(customers, customers.cardNo);
        }
        if (from < 22) {
          // [PullDataModel] — mirror tables + extra columns for API alignment
          await m.createTable(pullCategoryRows);
          await m.createTable(pullFloorRows);
          await m.createTable(pullDeliveryServiceRows);
          await m.createTable(pullItemRows);
          await m.createTable(syncPaginationStates);
          await safeAddColumn(categories, categories.recordUuid);
          await safeAddColumn(categories, categories.branchId);
          await safeAddColumn(categories, categories.categorySlug);
          await safeAddColumn(categories, categories.deletedAt);
          await safeAddColumn(kitchens, kitchens.recordUuid);
          await safeAddColumn(kitchens, kitchens.branchId);
          await safeAddColumn(kitchens, kitchens.printerDetails);
          await safeAddColumn(kitchens, kitchens.printerType);
          await safeAddColumn(kitchens, kitchens.deletedAt);
          await safeAddColumn(customers, customers.recordUuid);
          await safeAddColumn(customers, customers.branchId);
          await safeAddColumn(customers, customers.customerNumber);
          await safeAddColumn(diningFloors, diningFloors.recordUuid);
          await safeAddColumn(diningFloors, diningFloors.branchId);
          await safeAddColumn(diningFloors, diningFloors.floorSlug);
          await safeAddColumn(diningFloors, diningFloors.deletedAt);
          await safeAddColumn(diningTables, diningTables.recordUuid);
          await safeAddColumn(diningTables, diningTables.branchId);
          await safeAddColumn(diningTables, diningTables.pulledTableName);
          await safeAddColumn(diningTables, diningTables.pulledTableSlug);
          await safeAddColumn(diningTables, diningTables.orderCount);
          await safeAddColumn(diningTables, diningTables.deletedAt);
        }
        if (from < 24) {
          await m.createTable(orderLogs);
        }
      },
      // Legacy rows (or partial inserts) can leave NULL in NOT NULL columns; Drift’s
      // generated Session.map would null-check and crash on read.
      // Skip if a column is missing (migrations are responsible for adding columns).
      beforeOpen: (details) async {
        await customStatement('PRAGMA journal_mode = WAL;');
        await customStatement('PRAGMA synchronous = FULL;');
        try {
          await customStatement(
            "DELETE FROM sessions WHERE branch_id IS NULL OR user_id IS NULL OR role IS NULL",
          );
        } on SqliteException catch (e) {
          final m = e.message.toLowerCase();
          if (!m.contains('no such column')) rethrow;
        }
      },
    );
  }
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await AppDirectories.local();
    final file = File(p.join(dir.path, 'pos.sqlite'));
    return NativeDatabase(file);
  });
}
