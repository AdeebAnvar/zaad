import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/core/utils/image_utils.dart';
import 'package:pos/core/utils/invoice_suffix_max_sql.dart';
import 'package:pos/domain/models/branch_model.dart';
import 'package:pos/domain/models/settings_model.dart';
import 'package:pos/domain/models/user_model.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite;

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
part 'dao/pending_actions_dao.dart';
part 'dao/sync_queue_dao.dart';
part 'dao/settle_sales_outbox_dao.dart';
part 'dao/day_closing_checkpoint_dao.dart';
part 'dao/financial_records_dao.dart';

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
    PendingActions,
    SyncOutbox,
    SyncInbox,
    SettleSalesOutbox,
    DayClosingCheckpoint,
    FinancialRecords,
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
    PendingActionsDao,
    SyncQueueDao,
    SettleSalesOutboxDao,
    DayClosingCheckpointDao,
    FinancialRecordsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_open());

  /// On-disk SQLite at [file] (unit/integration tests). Not for production.
  AppDatabase.file(File file) : super(_openFile(file));

  /// In-memory SQLite for unit tests (`flutter test`). Not for production.
  AppDatabase.memory() : super(_openMemory());

  @override
  int get schemaVersion => 58;

  /// After [beforeOpen] / [ensureLegacySchemaColumnsOnce]; avoids PRAGMA+ALTER on every branch/order read.
  bool _legacySchemaRepairDone = false;

  Future<void> _safeAlterAddColumn(String sql) async {
    try {
      await customStatement(sql);
    } on SqliteException catch (e) {
      final m = e.message.toLowerCase();
      if (m.contains('duplicate column')) return;
      rethrow;
    }
  }

  bool _tableHasColumn(List<QueryRow> pragmaRows, String columnName) {
    return pragmaRows.any((r) => r.read<String>('name') == columnName);
  }

  /// One-shot repair for recovered DBs (schema v57 in Drift but missing columns on disk).
  /// v92 builds did not run this on every [BranchesDao.getBranchById] — that caused startup
  /// ALTER noise and UI stalls on upgraded installs.
  Future<void> ensureLegacySchemaColumnsOnce() async {
    if (_legacySchemaRepairDone) return;

    final branchInfo = await customSelect('PRAGMA table_info(branches)').get();
    if (!_tableHasColumn(branchInfo, 'default_opening_cash')) {
      await _safeAlterAddColumn(
        'ALTER TABLE branches ADD COLUMN default_opening_cash INTEGER NOT NULL DEFAULT 0',
      );
      try {
        await customStatement(
          'UPDATE branches SET default_opening_cash = COALESCE(opening_cash, 0)',
        );
      } on SqliteException catch (_) {
        /* opening_cash may be absent on very old rows */
      }
    }
    final branchInfoAfter = await customSelect('PRAGMA table_info(branches)').get();
    if (!_tableHasColumn(branchInfoAfter, 'last_token_no')) {
      await _safeAlterAddColumn('ALTER TABLE branches ADD COLUMN last_token_no INTEGER');
    }

    await ensureOrdersPickupTokenColumn();
    await ensureOrdersCustomerAddressColumn();
    await ensureOrdersSalePushUuidColumn();
    await _repairLegacyBranchRowData();

    _legacySchemaRepairDone = true;
  }

  /// Recovered / partially migrated DBs can have [schemaVersion] bumped without new columns.
  Future<void> ensureBranchesDefaultOpeningCashColumn() async {
    await ensureLegacySchemaColumnsOnce();
  }

  /// Recovered DBs may lack [Branches.lastTokenNo] used for pickup token seeding on SUB.
  Future<void> ensureBranchesLastTokenNoColumn() async {
    await ensureLegacySchemaColumnsOnce();
  }

  /// Removes carts/orders seeded with TEXT [created_at] (Drift expects INTEGER ms).
  Future<void> repairTextTimestampRows() async {
    try {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement(
        "DELETE FROM cart_items WHERE cart_id IN (SELECT id FROM carts WHERE typeof(created_at)='text')",
      );
      await customStatement(
        "DELETE FROM orders WHERE cart_id IN (SELECT id FROM carts WHERE typeof(created_at)='text')",
      );
      await customStatement("DELETE FROM carts WHERE typeof(created_at)='text'");
      await customStatement("DELETE FROM orders WHERE typeof(created_at)='text'");
    } on SqliteException catch (e) {
      final m = e.message.toLowerCase();
      if (m.contains('no such table')) return;
      rethrow;
    }
  }

  /// Fixes legacy [branches] rows where NOT NULL columns are NULL (Drift map crashes on read).
  /// Recovered DBs may have schema v52+ without [Orders.pickupToken] on disk.
  Future<void> ensureOrdersPickupTokenColumn() async {
    try {
      final rows = await customSelect("PRAGMA table_info('orders')").get();
      final hasColumn = rows.any((r) => r.read<String>('name') == 'pickup_token');
      if (hasColumn) return;
      await _safeAlterAddColumn('ALTER TABLE orders ADD COLUMN pickup_token INTEGER');
    } on SqliteException catch (e) {
      final m = e.message.toLowerCase();
      if (m.contains('no such table')) return;
      rethrow;
    }
  }

  /// Recovered DBs may have schema v53+ without [Orders.customerAddress] on disk.
  Future<void> ensureOrdersCustomerAddressColumn() async {
    try {
      final rows = await customSelect("PRAGMA table_info('orders')").get();
      if (_tableHasColumn(rows, 'customer_address')) return;
      await _safeAlterAddColumn('ALTER TABLE orders ADD COLUMN customer_address TEXT');
    } on SqliteException catch (e) {
      final m = e.message.toLowerCase();
      if (m.contains('no such table')) return;
      rethrow;
    }
  }

  /// Recovered DBs may have schema v57+ without [Orders.salePushUuid] on disk.
  Future<void> ensureOrdersSalePushUuidColumn() async {
    try {
      final rows = await customSelect("PRAGMA table_info('orders')").get();
      if (_tableHasColumn(rows, 'sale_push_uuid')) return;
      await _safeAlterAddColumn('ALTER TABLE orders ADD COLUMN sale_push_uuid TEXT');
    } on SqliteException catch (e) {
      final m = e.message.toLowerCase();
      if (m.contains('no such table')) return;
      rethrow;
    }
  }

  Future<void> _repairLegacyBranchRowData() async {
    try {
      await customStatement(
        'UPDATE branches SET default_opening_cash = COALESCE(default_opening_cash, opening_cash, 0) '
        'WHERE default_opening_cash IS NULL',
      );
      await customStatement(
        'UPDATE branches SET opening_cash = COALESCE(opening_cash, default_opening_cash, 0) '
        'WHERE opening_cash IS NULL',
      );
      await customStatement(
        "UPDATE branches SET local_image = '' WHERE local_image IS NULL",
      );
    } on SqliteException catch (e) {
      final m = e.message.toLowerCase();
      if (!m.contains('no such column')) rethrow;
    }
  }

  Future<void> repairLegacyBranchRows() async {
    await ensureLegacySchemaColumnsOnce();
  }

  /// Speeds Recent Sales / logs — filters by branch + sort by created_at.
  Future<void> ensureOrderListIndexes() async {
    try {
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_orders_branch_created_id '
        'ON orders (branch_id, created_at DESC, id DESC)',
      );
    } on SqliteException catch (e) {
      final m = e.message.toLowerCase();
      if (m.contains('no such table')) return;
      rethrow;
    }
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (m, from, to) async {
        Future<void> safeAddColumn(dynamic table, GeneratedColumn column) async {
          final tableName = table.actualTableName as String;
          final columnName = column.name;
          final info = await customSelect('PRAGMA table_info($tableName)').get();
          if (_tableHasColumn(info, columnName)) return;
          try {
            await m.addColumn(table, column);
          } on Object catch (e) {
            final msg = e.toString().toLowerCase();
            if (msg.contains('duplicate column')) return;
            rethrow;
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
        if (from < 26) {
          await safeAddColumn(cartItems, cartItems.itemName);
        }
        if (from < 27) {
          await safeAddColumn(itemToppings, itemToppings.toppingsCategoryId);
        }
        if (from < 30) {
          await safeAddColumn(orders, orders.userId);
        }
        if (from < 32) {
          await safeAddColumn(orders, orders.serverOrderId);
          await safeAddColumn(orders, orders.hubMetadata);
        }
        if (from < 33) {
          await m.createTable(pendingActions);
          await safeAddColumn(orders, orders.hubSyncPending);
        }
        if (from < 34) {
          await m.createTable(syncOutbox);
          await m.createTable(syncInbox);
        }
        if (from < 35) {
          await safeAddColumn(items, items.allowedOrderChannels);
        }
        if (from < 38) {
          await safeAddColumn(orders, orders.branchId);
          await safeAddColumn(carts, carts.branchId);
          try {
            await customStatement(
              'UPDATE orders SET branch_id = COALESCE((SELECT branch_id FROM users WHERE users.id = orders.user_id), 1) '
              'WHERE branch_id IS NULL OR branch_id <= 0',
            );
          } on SqliteException catch (_) {
            /* best-effort backfill */
          }
        }
        if (from < 41) {
          await m.createTable(settleSalesOutbox);
        }
        if (from < 42) {
          await m.createTable(dayClosingCheckpoint);
        }
        if (from < 51) {
          await safeAddColumn(branches, branches.defaultOpeningCash);
          await customStatement(
            'UPDATE branches SET default_opening_cash = opening_cash '
            'WHERE (default_opening_cash IS NULL OR default_opening_cash = 0) AND opening_cash > 0',
          );
          await customStatement(
            'UPDATE branches SET opening_cash = default_opening_cash '
            'WHERE default_opening_cash > 0 AND (opening_cash IS NULL OR opening_cash = 0)',
          );
          await customStatement(
            'UPDATE branches SET default_opening_cash = COALESCE(opening_cash, 0) '
            'WHERE default_opening_cash IS NULL',
          );
        }
        if (from < 52) {
          await safeAddColumn(orders, orders.pickupToken);
        }
        if (from < 53) {
          await safeAddColumn(orders, orders.customerAddress);
        }
        if (from < 54) {
          await m.createTable(financialRecords);
        }
        if (from < 55) {
          await _repairLegacyBranchRowData();
        }
        if (from < 56) {
          await safeAddColumn(branches, branches.lastTokenNo);
        }
        if (from < 57) {
          await safeAddColumn(orders, orders.salePushUuid);
        }
        if (from < 58) {
          await ensureOrderListIndexes();
        }
        // Align Drift version when columns were added by a prior partial open / hot-path repair.
        await customStatement('PRAGMA user_version = $schemaVersion');
      },
      // Legacy rows (or partial inserts) can leave NULL in NOT NULL columns; Drift’s
      // generated Session.map would null-check and crash on read.
      // Skip if a column is missing (migrations are responsible for adding columns).
      beforeOpen: (details) async {
        await customStatement('PRAGMA journal_mode = WAL;');
        // FULL + OneDrive Documents caused multi-second UI stalls on every fsync.
        await customStatement('PRAGMA synchronous = NORMAL;');
        try {
          await customStatement(
            "DELETE FROM sessions WHERE branch_id IS NULL OR user_id IS NULL OR role IS NULL",
          );
        } on SqliteException catch (e) {
          final m = e.message.toLowerCase();
          if (!m.contains('no such column')) rethrow;
        }
        await ensureLegacySchemaColumnsOnce();
        await ensureOrderListIndexes();
        // repairTextTimestampRows runs from ZaadDI.runDeferredBackgroundServices.
      },
    );
  }
}

void _configureSqlitePragmas(sqlite.Database rawDb) {
  rawDb.execute('PRAGMA journal_mode = WAL;');
  rawDb.execute('PRAGMA synchronous = NORMAL;');
  // Match [PosSqliteOpen] probe window — slow OneDrive paths need longer waits.
  rawDb.execute('PRAGMA busy_timeout = 30000;');
}

/// Android public Documents paths fail in Drift's background isolate (SQLite 14).
/// Windows keeps [NativeDatabase.createInBackground] for OneDrive responsiveness.
QueryExecutor _openNativeExecutor(File file) {
  void setup(sqlite.Database rawDb) => _configureSqlitePragmas(rawDb);

  if (Platform.isAndroid) {
    return NativeDatabase(file, setup: setup);
  }
  return NativeDatabase.createInBackground(file, setup: setup);
}

LazyDatabase _open() {
  return LazyDatabase(() async {
    final dir = await AppDirectories.local();
    final file = File(p.join(dir.path, 'pos.sqlite'));
    return _openNativeExecutor(file);
  });
}

LazyDatabase _openFile(File file) {
  return LazyDatabase(() async {
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    return _openNativeExecutor(file);
  });
}

LazyDatabase _openMemory() {
  return LazyDatabase(() async => NativeDatabase.memory());
}
