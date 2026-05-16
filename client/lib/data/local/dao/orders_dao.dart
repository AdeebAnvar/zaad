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
  TextColumn get customerAddress => text().nullable()();
  
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

  /// Daily pickup / queue number; resets after [DayClosingCheckpoint.lastSettledAt] for the branch.
  IntColumn get pickupToken => integer().nullable()();
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
    return (q
          ..orderBy([
            (o) => OrderingTerm.desc(o.createdAt),
            (o) => OrderingTerm.desc(o.id),
          ]))
        .get();
  }

  Future<Order?> getOrderById(int orderId) {
    return (select(orders)..where((o) => o.id.equals(orderId))).getSingleOrNull();
  }

  Future<Order?> getOrderByServerId(String serverId) {
    return (select(orders)..where((o) => o.serverOrderId.equals(serverId))).getSingleOrNull();
  }

  /// When still null, set [Orders.serverOrderId] to the LAN hub correlation (`orderId` in payloads) so DELETE / upserts match.
  Future<void> setHubCorrelationIfUnset({
    required int orderId,
    required String correlationId,
  }) async {
    final key = correlationId.trim();
    if (key.isEmpty) return;
    final row = await getOrderById(orderId);
    if (row == null) return;
    if ((row.serverOrderId ?? '').trim().isNotEmpty) return;
    await (update(orders)..where((o) => o.id.equals(orderId))).write(
      OrdersCompanion(serverOrderId: Value(key)),
    );
  }

  Future<List<Order>> getOrdersByDateRange(DateTime start, DateTime end, {int? branchId}) {
    var q = select(orders)
      ..where((o) => o.createdAt.isBiggerOrEqualValue(start))
      ..where((o) => o.createdAt.isSmallerOrEqualValue(end));
    if (branchId != null) {
      q = q..where((o) => o.branchId.equals(branchId));
    }
    return (q
          ..orderBy([
            (o) => OrderingTerm.desc(o.createdAt),
            (o) => OrderingTerm.desc(o.id),
          ]))
        .get();
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

  /// LAN hub upsert fallback when [serverOrderId] on the row is missing but invoice matches.
  Future<Order?> getKotByInvoiceAndBranch(String invoiceNumber, {required int branchId}) async {
    final inv = invoiceNumber.trim();
    if (inv.isEmpty) return null;
    final rows = await (select(orders)
          ..where((o) => o.invoiceNumber.equals(inv))
          ..where((o) => o.branchId.equals(branchId))
          ..where((o) => o.status.equals('kot'))
          ..orderBy([(o) => OrderingTerm.desc(o.id)]))
        .get();
    if (rows.isEmpty) return null;
    if (rows.length == 1) return rows.first;
    // Prefer a row already linked to the hub id when duplicates exist.
    final linked = rows.where((o) => (o.serverOrderId ?? '').trim().isNotEmpty).toList();
    return linked.isNotEmpty ? linked.first : rows.first;
  }

  /// Non-empty distinct `referenceNumber` values from recent orders (KOT autocomplete).
  Future<List<String>> getRecentDistinctReferenceNumbers({
    int limit = 40,
    required int branchId,
  }) async {
    final rows = await (select(orders)
          ..where((o) => o.referenceNumber.isNotNull())
          ..where((o) => o.branchId.equals(branchId))
          ..orderBy([
            (o) => OrderingTerm.desc(o.createdAt),
            (o) => OrderingTerm.desc(o.id),
          ])
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

  /// Max [Orders.pickupToken] for [branchId] with `created_at` strictly after [createdAfterExclusive]
  /// (when null, all time). Ignores null tokens.
  Future<int?> maxPickupTokenForBranchSince(int branchId, DateTime? createdAfterExclusive) async {
    final maxExpr = orders.pickupToken.max();
    final q = selectOnly(orders)..addColumns([maxExpr]);
    q.where(orders.branchId.equals(branchId));
    q.where(orders.pickupToken.isNotNull());
    if (createdAfterExclusive != null) {
      q.where(orders.createdAt.isBiggerThanValue(createdAfterExclusive));
    }
    final row = await q.map((r) => r.read(maxExpr)).getSingleOrNull();
    return row;
  }

  /// Latest order with a token (for counter display). Scoped to current business period when [createdAfterExclusive] is set.
  Stream<Order?> watchLatestOrderWithPickupToken({
    required int branchId,
    DateTime? createdAfterExclusive,
  }) {
    if (createdAfterExclusive != null) {
      final after = createdAfterExclusive;
      return (select(orders)
            ..where((o) => o.branchId.equals(branchId))
            ..where((o) => o.pickupToken.isNotNull())
            ..where((o) => o.createdAt.isBiggerThanValue(after))
            ..orderBy([(o) => OrderingTerm.desc(o.id)])
            ..limit(1))
          .watch()
          .map((rows) => rows.isEmpty ? null : rows.first);
    }
    return (select(orders)
          ..where((o) => o.branchId.equals(branchId))
          ..where((o) => o.pickupToken.isNotNull())
          ..orderBy([(o) => OrderingTerm.desc(o.id)])
          ..limit(1))
        .watch()
        .map((rows) => rows.isEmpty ? null : rows.first);
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
    return (q
          ..orderBy([
            (o) => OrderingTerm.desc(o.createdAt),
            (o) => OrderingTerm.desc(o.id),
          ]))
        .get();
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
    int? pickupToken,
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

    if (pickupToken != null) {
      query = query..where((o) => o.pickupToken.equals(pickupToken));
    }

    return (query
          ..orderBy([
            (o) => OrderingTerm.desc(o.createdAt),
            (o) => OrderingTerm.desc(o.id),
          ]))
        .get();
  }

  /// Highest numeric suffix for invoices in [branchId] and [prefix].
  ///
  /// Supports:
  /// - Current format: `PREFIX-branchId-###` (e.g. `INV-1-002`)
  /// - Legacy format: `PREFIX##` (e.g. `INV02`)
  Future<int> maxInvoiceNumericSuffixForPrefix(String prefix, {required int branchId}) async {
    final rows = await (select(orders)
          ..where((o) => o.invoiceNumber.like('$prefix%'))
          ..where((o) => o.branchId.equals(branchId)))
        .get();
    var max = 0;
    final escapedPrefix = RegExp.escape(prefix);
    final currentFormat = RegExp('^$escapedPrefix-$branchId-(\\d+)\$');
    final legacyFormat = RegExp('^$escapedPrefix(\\d+)\$');

    for (final o in rows) {
      final inv = o.invoiceNumber;
      int? v;
      final currentMatch = currentFormat.firstMatch(inv);
      if (currentMatch != null) {
        v = int.tryParse(currentMatch.group(1)!);
      } else {
        final legacyMatch = legacyFormat.firstMatch(inv);
        if (legacyMatch != null) {
          v = int.tryParse(legacyMatch.group(1)!);
        }
      }
      if (v != null && v > max) max = v;
    }
    return max;
  }
}
