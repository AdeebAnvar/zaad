part of '../drift_database.dart';

class Orders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cartId => integer().references(Carts, #id)();
  TextColumn get invoiceNumber => text()();
  TextColumn get referenceNumber => text().nullable()();
  RealColumn get totalAmount => real()();
  RealColumn get discountAmount => real().withDefault(const Constant(0))();
  TextColumn get discountType => text().nullable()();
  RealColumn get finalAmount => real()();
  
  // Customer Details
  TextColumn get customerName => text().nullable()();
  TextColumn get customerEmail => text().nullable()();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get customerGender => text().nullable()();
  
  // Payment Details
  RealColumn get cashAmount => real().withDefault(const Constant(0))();
  RealColumn get creditAmount => real().withDefault(const Constant(0))();
  RealColumn get cardAmount => real().withDefault(const Constant(0))();
  RealColumn get onlineAmount => real().withDefault(const Constant(0))();
  
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('placed'))(); // placed, completed, cancelled, kot
  /// 'take_away' | 'delivery' | 'dine_in'
  TextColumn get orderType => text().nullable()();
  TextColumn get deliveryPartner => text().nullable()();
  IntColumn get driverId => integer().nullable().references(Drivers, #id)();
  TextColumn get driverName => text().nullable()();
  /// Cashier / staff who created the order (from session at save time).
  IntColumn get userId => integer().nullable().references(Users, #id)();

  /// Selling branch (active session at save time); filters logs & reports per branch.
  IntColumn get branchId => integer().withDefault(const Constant(1))();

  /// LAN hub authoritative order UUID (SQLite row id from Node server).
  TextColumn get serverOrderId => text().nullable()();

  /// Serialized hub payload / reconciliation extras (invoice lines snapshot, discounts, …).
  TextColumn get hubMetadata => text().nullable()();

  /// LOCAL offline: row exists locally but POST /orders not confirmed yet.
  BoolColumn get hubSyncPending =>
      boolean().withDefault(const Constant(false))();
}

class OrderLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get orderJson => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}

@DriftAccessor(tables: [
  Orders,
  OrderLogs,
  Carts,
  CartItems,
])
class OrdersDao extends DatabaseAccessor<AppDatabase> with _$OrdersDaoMixin {
  OrdersDao(super.db);

  /* ───────── ORDERS ───────── */

  Future<int> createOrder(OrdersCompanion order) {
    return into(orders).insert(order);
  }

  Future<List<Order>> getAllOrders({int? branchId}) {
    var q = select(orders);
    if (branchId != null) {
      q = q..where((o) => o.branchId.equals(branchId));
    }
    return (q..orderBy([(o) => OrderingTerm.desc(o.createdAt)])).get();
  }

  Future<Order?> getOrderById(int orderId) {
    return (select(orders)..where((o) => o.id.equals(orderId))).getSingleOrNull();
  }

  Future<Order?> getOrderByServerId(String serverId) {
    return (select(orders)..where((o) => o.serverOrderId.equals(serverId))).getSingleOrNull();
  }

  Future<List<Order>> getOrdersByDateRange(DateTime start, DateTime end, {int? branchId}) {
    var q = select(orders)
      ..where((o) => o.createdAt.isBiggerOrEqualValue(start))
      ..where((o) => o.createdAt.isSmallerOrEqualValue(end));
    if (branchId != null) {
      q = q..where((o) => o.branchId.equals(branchId));
    }
    return (q..orderBy([(o) => OrderingTerm.desc(o.createdAt)])).get();
  }

  Future<void> updateOrderStatus(int orderId, String status) {
    return (update(orders)..where((o) => o.id.equals(orderId)))
        .write(OrdersCompanion(status: Value(status)));
  }

  Future<void> deleteOrder(int orderId) {
    return (delete(orders)..where((o) => o.id.equals(orderId))).go();
  }

  Future<Order?> getKOTByReference(String referenceNumber, {required int branchId}) async {
    final query = select(orders)
      ..where((o) => o.referenceNumber.equals(referenceNumber))
      ..where((o) => o.branchId.equals(branchId))
      ..where((o) => o.status.equals('kot'))
      ..orderBy([(o) => OrderingTerm.desc(o.id)])
      ..limit(1);
    final list = await query.get();
    return list.isEmpty ? null : list.first;
  }

  /// Non-empty distinct `referenceNumber` values from recent orders (KOT autocomplete).
  Future<List<String>> getRecentDistinctReferenceNumbers({
    int limit = 40,
    required int branchId,
  }) async {
    final rows = await (select(orders)
          ..where((o) => o.referenceNumber.isNotNull())
          ..where((o) => o.branchId.equals(branchId))
          ..orderBy([(o) => OrderingTerm.desc(o.createdAt)])
          ..limit(400))
        .get();

    final seen = <String>{};
    final out = <String>[];
    for (final r in rows) {
      final s = (r.referenceNumber ?? '').trim();
      if (s.isEmpty) continue;
      if (seen.add(s.toLowerCase())) out.add(s);
      if (out.length >= limit) break;
    }
    return out;
  }

  /// Distinct non-null [Orders.userId] for [branchId] — aligns user filters with branch-scoped orders.
  Future<List<int>> getDistinctCashierUserIdsForBranch(int branchId) async {
    final rows = await (select(orders)
          ..where((o) => o.branchId.equals(branchId))
          ..where((o) => o.userId.isNotNull()))
        .get();
    final ids = <int>{};
    for (final r in rows) {
      final u = r.userId;
      if (u != null) ids.add(u);
    }
    final list = ids.toList();
    list.sort();
    return list;
  }

  Future<void> updateOrder(OrdersCompanion order) {
    return (update(orders)..where((o) => o.id.equals(order.id.value)))
        .write(order);
  }

  Future<int> insertOrderLog(String orderJson) {
    return into(orderLogs).insert(
      OrderLogsCompanion.insert(
        orderJson: orderJson,
      ),
    );
  }

  Future<List<OrderLog>> getUnsyncedOrderLogs() {
    return (select(orderLogs)
          ..where((t) => t.synced.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> markOrderLogsSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    await (update(orderLogs)..where((t) => t.id.isIn(ids))).write(
      const OrderLogsCompanion(synced: Value(true)),
    );
  }

  /// Unsynced log whose JSON payload includes `order_id` (push_records snapshot).
  Future<OrderLog?> findUnsyncedLogByLocalOrderId(int localOrderId) async {
    final logs = await getUnsyncedOrderLogs();
    for (final log in logs) {
      try {
        final decoded = jsonDecode(log.orderJson);
        if (decoded is Map && decoded['order_id'] == localOrderId) {
          return log;
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> updateOrderLogPayload(int logId, String orderJson) {
    return (update(orderLogs)..where((t) => t.id.equals(logId))).write(
      OrderLogsCompanion(orderJson: Value(orderJson)),
    );
  }

  Future<void> deleteOrderLogById(int logId) {
    return (delete(orderLogs)..where((t) => t.id.equals(logId))).go();
  }

  Future<OrderLog?> findLatestOrderLogByLocalOrderId(int localOrderId) async {
    final logs =
        await (select(orderLogs)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
    for (final log in logs) {
      try {
        final decoded = jsonDecode(log.orderJson);
        if (decoded is Map && decoded['order_id'] == localOrderId) {
          return log;
        }
      } catch (_) {
        /* ignore */
      }
    }
    return null;
  }

  Future<void> setOrderLogsSyncedState(List<int> ids, {required bool synced}) async {
    if (ids.isEmpty) return;
    await (update(orderLogs)..where((t) => t.id.isIn(ids))).write(
      OrderLogsCompanion(synced: Value(synced)),
    );
  }

  Future<void> deleteOrderLogsForLocalOrderId(int localOrderId) async {
    final logs = await select(orderLogs).get();
    final toDelete = <int>[];
    for (final log in logs) {
      try {
        final decoded = jsonDecode(log.orderJson);
        if (decoded is Map && decoded['order_id'] == localOrderId) {
          toDelete.add(log.id);
        }
      } catch (_) {
        /* ignore */
      }
    }
    if (toDelete.isEmpty) return;
    await (delete(orderLogs)..where((t) => t.id.isIn(toDelete))).go();
  }

  /// Normal delivery orders that have a driver assigned (for driver log).
  Future<List<Order>> getDeliveryOrdersWithDriver({int? branchId}) {
    var q = select(orders)
      ..where((o) => o.orderType.equals('delivery'))
      ..where((o) => o.driverId.isNotNull());
    if (branchId != null) {
      q = q..where((o) => o.branchId.equals(branchId));
    }
    return (q..orderBy([(o) => OrderingTerm.desc(o.createdAt)])).get();
  }

  Future<List<Order>> filterOrders({
    String? invoiceNumber,
    String? referenceNumber,
    String? status,
    List<String>? statusAnyOf,
    String? orderType,
    String? deliveryPartner,
    String? customerPhone,
    DateTime? startDate,
    DateTime? endDate,
    int? driverId,
    int? userId,
    int? branchId,
  }) {
    var query = select(orders);

    if (branchId != null) {
      query = query..where((o) => o.branchId.equals(branchId));
    }

    if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
      query = query..where((o) => o.invoiceNumber.like('%$invoiceNumber%'));
    }

    if (referenceNumber != null && referenceNumber.isNotEmpty) {
      query = query..where((o) => o.referenceNumber.like('%$referenceNumber%'));
    }

    if (statusAnyOf != null && statusAnyOf.isNotEmpty) {
      query = query..where((o) => o.status.isIn(statusAnyOf));
    } else if (status != null && status.isNotEmpty) {
      query = query..where((o) => o.status.equals(status));
    }

    if (orderType != null && orderType.isNotEmpty) {
      if (orderType == 'take_away') {
        query = query..where((o) => o.orderType.isNull() | o.orderType.equals('take_away'));
      } else {
        query = query..where((o) => o.orderType.equals(orderType));
      }
    }

    if (deliveryPartner != null && deliveryPartner.isNotEmpty) {
      query = query..where((o) => o.deliveryPartner.like('%$deliveryPartner%'));
    }

    if (customerPhone != null && customerPhone.isNotEmpty) {
      query = query..where((o) => o.customerPhone.like('%$customerPhone%'));
    }

    if (startDate != null) {
      query = query..where((o) => o.createdAt.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      // Add one day to include the entire end date
      final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query = query..where((o) => o.createdAt.isSmallerOrEqualValue(endDateTime));
    }

    if (driverId != null) {
      query = query..where((o) => o.driverId.equals(driverId));
    }

    if (userId != null) {
      query = query..where((o) => o.userId.equals(userId));
    }

    return (query..orderBy([(o) => OrderingTerm.desc(o.createdAt)])).get();
  }

  /// Highest numeric suffix for invoices starting with [prefix] (e.g. `TA` → `TA01` → 1).
  Future<int> maxInvoiceNumericSuffixForPrefix(String prefix, {required int branchId}) async {
    final rows = await (select(orders)
          ..where((o) => o.invoiceNumber.like('$prefix%'))
          ..where((o) => o.branchId.equals(branchId)))
        .get();
    var max = 0;
    for (final o in rows) {
      final inv = o.invoiceNumber;
      if (!inv.startsWith(prefix)) continue;
      final tail = inv.substring(prefix.length);
      final v = int.tryParse(tail);
      if (v != null && v > max) max = v;
    }
    return max;
  }
}
