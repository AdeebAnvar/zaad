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
  BoolColumn get hubSyncPending => boolean().withDefault(const Constant(false))();

  /// Daily pickup / queue number; resets after [DayClosingCheckpoint.lastSettledAt] for the branch.
  IntColumn get pickupToken => integer().nullable()();

  /// Stable cloud `push_records` sale uuid — assigned once at order creation, never recomputed.
  TextColumn get salePushUuid => text().nullable()();
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
  bool? _hasPickupTokenColumnCache;

  /* ───────── ORDERS ───────── */

  Future<int> createOrder(OrdersCompanion order) async {
    return into(orders).insert(order);
  }

  Future<void> setSalePushUuid(int orderId, String uuid) async {
    final trimmed = uuid.trim();
    if (trimmed.isEmpty) return;
    await (update(orders)..where((o) => o.id.equals(orderId))).write(
      OrdersCompanion(salePushUuid: Value(trimmed)),
    );
  }

  /// Writes [uuid] only when the row has no sale push uuid yet.
  Future<bool> setSalePushUuidIfUnset(int orderId, String uuid) async {
    final trimmed = uuid.trim();
    if (trimmed.isEmpty) return false;
    final row = await getOrderById(orderId);
    if (row == null) return false;
    final existing = row.salePushUuid?.trim();
    if (existing != null && existing.isNotEmpty) return false;
    await setSalePushUuid(orderId, trimmed);
    return true;
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

  /// Returns only [status='completed'] orders — avoids loading all rows when callers
  /// only need completed sales (e.g. [OrdersCubit]).
  Future<List<Order>> getCompletedOrders({int? branchId}) {
    var q = select(orders)..where((o) => o.status.equals('completed'));
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

  /// Placed + completed rows for cloud upload ([SyncService]) — excludes kot/cancelled in SQL.
  Future<List<Order>> getPlacedOrCompletedOrders({int? branchId}) {
    var q = select(orders)..where((o) => o.status.isIn(const ['placed', 'completed']));
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
    await (update(orders)
          ..where((o) => o.id.equals(orderId))
          ..where(
            (o) => o.serverOrderId.isNull() | o.serverOrderId.equals(''),
          ))
        .write(OrdersCompanion(serverOrderId: Value(key)));
  }

  /// Open KOT qty edits — totals only; skips hub freeze / order_logs / cloud enqueue.
  Future<void> updateKotOrderTotals({
    required int orderId,
    required double totalAmount,
    required double finalAmount,
    required int cartId,
    Value<String?> referenceNumber = const Value.absent(),
    Value<String?> hubMetadata = const Value.absent(),
  }) {
    return (update(orders)..where((o) => o.id.equals(orderId))).write(
      OrdersCompanion(
        totalAmount: Value(totalAmount),
        finalAmount: Value(finalAmount),
        cartId: Value(cartId),
        referenceNumber: referenceNumber,
        hubMetadata: hubMetadata,
      ),
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
    return (update(orders)..where((o) => o.id.equals(orderId))).write(OrdersCompanion(status: Value(status)));
  }

  Future<void> deleteOrder(int orderId) {
    return (delete(orders)..where((o) => o.id.equals(orderId))).go();
  }

  /// Any order row for [invoiceNumber] on [branchId] (e.g. token counter sentinel).
  Future<Order?> getOrderByInvoiceAndBranch(
    String invoiceNumber, {
    required int branchId,
  }) async {
    final inv = invoiceNumber.trim();
    if (inv.isEmpty) return null;
    return (select(orders)
          ..where((o) => o.invoiceNumber.equals(inv))
          ..where((o) => o.branchId.equals(branchId))
          ..orderBy([(o) => OrderingTerm.desc(o.id)])
          ..limit(1))
        .getSingleOrNull();
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

  /// SUB/MAIN row with same invoice but no hub correlation yet (delivery pending, KOT, etc.).
  /// Used before inserting a mirrored hub row so we do not duplicate invoice + time labels.
  Future<Order?> findLocalOrderAwaitingHubLinkByInvoice(
    String invoiceNumber, {
    required int branchId,
  }) async {
    final inv = invoiceNumber.trim();
    if (inv.isEmpty) return null;
    final rows = await (select(orders)
          ..where((o) => o.invoiceNumber.equals(inv))
          ..where((o) => o.branchId.equals(branchId))
          ..where((o) => o.serverOrderId.isNull() | o.serverOrderId.equals(''))
          ..orderBy([(o) => OrderingTerm.desc(o.id)]))
        .get();
    for (final r in rows) {
      final s = r.status.toLowerCase();
      if (s == 'completed' || s == 'cancelled') continue;
      return r;
    }
    return null;
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
    final rows = await customSelect(
      'SELECT DISTINCT user_id AS uid FROM orders '
      'WHERE branch_id = ? AND user_id IS NOT NULL '
      'ORDER BY uid',
      variables: [Variable.withInt(branchId)],
      readsFrom: {orders},
    ).get();
    return rows.map((r) => r.read<int>('uid')).toList();
  }

  Future<List<GeneratedColumn<Object>>> _listOrderColumnsForQuery() async {
    final cols = <GeneratedColumn<Object>>[
      orders.id,
      orders.cartId,
      orders.invoiceNumber,
      orders.referenceNumber,
      orders.totalAmount,
      orders.discountAmount,
      orders.discountType,
      orders.finalAmount,
      orders.customerName,
      orders.customerEmail,
      orders.customerPhone,
      orders.customerGender,
      orders.cashAmount,
      orders.creditAmount,
      orders.cardAmount,
      orders.onlineAmount,
      orders.createdAt,
      orders.status,
      orders.orderType,
      orders.deliveryPartner,
      orders.driverId,
      orders.driverName,
      orders.userId,
      orders.branchId,
      orders.serverOrderId,
      orders.hubSyncPending,
    ];
    if (await _hasPickupTokenColumn()) {
      cols.add(orders.pickupToken);
    }
    return cols;
  }

  /// Mirrors [orderCountsAsRecentSale] (Recent Sales default list) — keep SQL in sync with that helper.
  static final Expression<bool> _recentSaleSettledSql = CustomExpression(
    '(NOT (LOWER(TRIM(status)) IN (\'cancelled\', \'kot\')) AND '
    '(LOWER(TRIM(status)) IN (\'completed\', \'delivered\') OR '
    '((CASE WHEN final_amount > 0.009 THEN final_amount ELSE total_amount END) > 0.009 '
    'AND (cash_amount + card_amount + credit_amount + online_amount + 0.02) >= '
    '(CASE WHEN final_amount > 0.009 THEN final_amount ELSE total_amount END))))',
  );

  Expression<bool>? _listPaymentPredicate(String? raw) {
    if (raw == null) return null;
    final k = raw.trim().toLowerCase();
    switch (k) {
      case 'cash':
        return orders.cashAmount.isBiggerThanValue(0.004);
      case 'card':
        return orders.cardAmount.isBiggerThanValue(0.004);
      case 'credit':
        return orders.creditAmount.isBiggerThanValue(0.004);
      case 'online':
        return orders.onlineAmount.isBiggerThanValue(0.004);
      default:
        return null;
    }
  }

  Order _orderFromListRow(TypedResult row) {
    return Order(
      id: row.read(orders.id)!,
      cartId: row.read(orders.cartId)!,
      invoiceNumber: row.read(orders.invoiceNumber)!,
      referenceNumber: row.read(orders.referenceNumber),
      totalAmount: row.read(orders.totalAmount)!,
      discountAmount: row.read(orders.discountAmount)!,
      discountType: row.read(orders.discountType),
      finalAmount: row.read(orders.finalAmount)!,
      customerName: row.read(orders.customerName),
      customerEmail: row.read(orders.customerEmail),
      customerPhone: row.read(orders.customerPhone),
      customerGender: row.read(orders.customerGender),
      cashAmount: row.read(orders.cashAmount)!,
      creditAmount: row.read(orders.creditAmount)!,
      cardAmount: row.read(orders.cardAmount)!,
      onlineAmount: row.read(orders.onlineAmount)!,
      createdAt: row.read(orders.createdAt)!,
      status: row.read(orders.status)!,
      orderType: row.read(orders.orderType),
      deliveryPartner: row.read(orders.deliveryPartner),
      driverId: row.read(orders.driverId),
      driverName: row.read(orders.driverName),
      userId: row.read(orders.userId),
      branchId: row.read(orders.branchId)!,
      serverOrderId: row.read(orders.serverOrderId),
      hubMetadata: null,
      hubSyncPending: row.read(orders.hubSyncPending)!,
      pickupToken: _readPickupTokenFromRow(row),
    );
  }

  int? _readPickupTokenFromRow(TypedResult row) {
    try {
      return row.read(orders.pickupToken);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateOrder(OrdersCompanion order) async {
    await (update(orders)..where((o) => o.id.equals(order.id.value))).write(order);
  }

  /// Max [Orders.pickupToken] for [branchId] with `created_at` strictly after [createdAfterExclusive]
  /// (when null, all time). Ignores null tokens.
  Future<int?> maxPickupTokenForBranchSince(int branchId, DateTime? createdAfterExclusive) async {
    if (!await _hasPickupTokenColumn()) return null;
    final maxExpr = orders.pickupToken.max();
    final q = selectOnly(orders)..addColumns([maxExpr]);
    q.where(orders.branchId.equals(branchId));
    q.where(orders.pickupToken.isNotNull());
    if (createdAfterExclusive != null) {
      q.where(orders.createdAt.isBiggerThanValue(createdAfterExclusive));
    }
    try {
      final row = await q.getSingleOrNull();
      return row?.read(maxExpr);
    } on SqliteException catch (e) {
      if (_isMissingColumnSqliteError(e, 'pickup_token')) return null;
      rethrow;
    } catch (_) {
      return null;
    }
  }

  /// Latest order with a token (for counter display). Scoped to current business period when [createdAfterExclusive] is set.
  Stream<Order?> watchLatestOrderWithPickupToken({
    required int branchId,
    DateTime? createdAfterExclusive,
  }) {
    return Stream.fromFuture(_hasPickupTokenColumn()).asyncExpand((hasColumn) {
      if (!hasColumn) return Stream.value(null);
      return _watchLatestOrderWithPickupTokenUnsafe(
        branchId: branchId,
        createdAfterExclusive: createdAfterExclusive,
      ).handleError(
        (_, __) => _hasPickupTokenColumnCache = false,
        test: (error) => error is SqliteException && _isMissingColumnSqliteError(error, 'pickup_token'),
      );
    });
  }

  Stream<Order?> _watchLatestOrderWithPickupTokenUnsafe({
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

  Future<bool> _hasPickupTokenColumn() async {
    final cached = _hasPickupTokenColumnCache;
    if (cached != null) return cached;
    try {
      final info = await customSelect("PRAGMA table_info('orders')").get();
      final hasColumn = info.any(
        (r) => (r.read<String>('name')).toLowerCase() == 'pickup_token',
      );
      _hasPickupTokenColumnCache = hasColumn;
      if (!hasColumn) {
        await attachedDatabase.ensureLegacySchemaColumnsOnce();
        final retry = await customSelect("PRAGMA table_info('orders')").get();
        final repaired = retry.any(
          (r) => (r.read<String>('name')).toLowerCase() == 'pickup_token',
        );
        if (repaired) {
          _hasPickupTokenColumnCache = true;
          return true;
        }
      }
      return hasColumn;
    } on SqliteException catch (_) {
      _hasPickupTokenColumnCache = false;
      return false;
    }
  }

  bool _isMissingColumnSqliteError(SqliteException e, String columnName) {
    final msg = e.message.toLowerCase();
    return msg.contains('no such column') && msg.contains(columnName.toLowerCase());
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
    try {
      final jsonHit = await _findOrderLogByJsonExtract(
        localOrderId: localOrderId,
        syncedClause: 'synced = 0 AND ',
        orderDir: 'ASC',
      );
      if (jsonHit != null) return jsonHit;
    } on SqliteException {
      return _findUnsyncedLogByLocalOrderIdScan(localOrderId);
    }
    return _findUnsyncedLogByLocalOrderIdScan(localOrderId);
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
    try {
      final jsonHit = await _findOrderLogByJsonExtract(
        localOrderId: localOrderId,
        syncedClause: '',
        orderDir: 'DESC',
      );
      if (jsonHit != null) return jsonHit;
    } on SqliteException {
      return _findLatestOrderLogByLocalOrderIdScan(localOrderId);
    }
    return _findLatestOrderLogByLocalOrderIdScan(localOrderId);
  }

  Future<void> setOrderLogsSyncedState(List<int> ids, {required bool synced}) async {
    if (ids.isEmpty) return;
    await (update(orderLogs)..where((t) => t.id.isIn(ids))).write(
      OrderLogsCompanion(synced: Value(synced)),
    );
  }

  Future<OrderLog?> _findOrderLogByJsonExtract({
    required int localOrderId,
    required String syncedClause,
    required String orderDir,
  }) async {
    final rows = await customSelect(
      'SELECT id, order_json, created_at, synced FROM order_logs WHERE '
      "${syncedClause}CAST(json_extract(order_json, '\$.order_id') AS INTEGER) = ? "
      'ORDER BY created_at $orderDir LIMIT 1',
      variables: [Variable.withInt(localOrderId)],
      readsFrom: {orderLogs},
    ).get();
    if (rows.isEmpty) return null;
    final r = rows.single;
    return OrderLog(
      id: r.read<int>('id'),
      orderJson: r.read<String>('order_json'),
      createdAt: r.read<DateTime>('created_at'),
      synced: r.read<bool>('synced'),
    );
  }

  Future<OrderLog?> _findUnsyncedLogByLocalOrderIdScan(int localOrderId) async {
    final logs = await getUnsyncedOrderLogs();
    for (final log in logs) {
      if (_orderLogMapsToLocalOrderId(log, localOrderId)) return log;
    }
    return null;
  }

  Future<OrderLog?> _findLatestOrderLogByLocalOrderIdScan(int localOrderId) async {
    final logs = await (select(orderLogs)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
    for (final log in logs) {
      if (_orderLogMapsToLocalOrderId(log, localOrderId)) return log;
    }
    return null;
  }

  bool _orderLogMapsToLocalOrderId(OrderLog log, int localOrderId) {
    try {
      final decoded = jsonDecode(log.orderJson);
      if (decoded is! Map) return false;
      final oid = decoded['order_id'];
      return oid == localOrderId || oid?.toString() == localOrderId.toString();
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteOrderLogsForLocalOrderId(int localOrderId) async {
    try {
      await customStatement(
        "DELETE FROM order_logs WHERE CAST(json_extract(order_json, '\$.order_id') AS INTEGER) = ?",
        [localOrderId],
      );
    } on SqliteException {
      await _deleteOrderLogsForLocalOrderIdScan(localOrderId);
    }
  }

  Future<void> _deleteOrderLogsForLocalOrderIdScan(int localOrderId) async {
    final logs = await select(orderLogs).get();
    final toDelete = <int>[];
    for (final log in logs) {
      if (_orderLogMapsToLocalOrderId(log, localOrderId)) {
        toDelete.add(log.id);
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
    int? limit,
    List<String>? excludeStatusAnyOf,
  }) async {
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

    if (excludeStatusAnyOf != null && excludeStatusAnyOf.isNotEmpty) {
      query = query..where((o) => o.status.isNotIn(excludeStatusAnyOf));
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

    if (pickupToken != null && await _hasPickupTokenColumn()) {
      query = query..where((o) => o.pickupToken.equals(pickupToken));
    }

    query = query
      ..orderBy([
        (o) => OrderingTerm.desc(o.createdAt),
        (o) => OrderingTerm.desc(o.id),
      ]);
    if (limit != null && limit > 0) {
      query = query..limit(limit);
    }
    return query.get();
  }

  /// Same filters as [filterOrders] but omits [Orders.hubMetadata] from SQLite reads (log UIs).
  Future<List<Order>> filterOrdersForList({
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
    int? limit,
    int offset = 0,
    bool onlyRecentSaleSettled = false,
    String? paymentMethodKey,
    bool excludeKotStatus = false,
  }) async {
    final listCols = await _listOrderColumnsForQuery();
    var query = selectOnly(orders)..addColumns(listCols);

    if (branchId != null) {
      query = query..where(orders.branchId.equals(branchId));
    }

    if (excludeKotStatus) {
      query = query..where(orders.status.equals('kot').not());
    }

    if (onlyRecentSaleSettled) {
      query = query..where(_recentSaleSettledSql);
    }

    final payPred = _listPaymentPredicate(paymentMethodKey);
    if (payPred != null) {
      query = query..where(payPred);
    }

    if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
      query = query..where(orders.invoiceNumber.like('%$invoiceNumber%'));
    }

    if (referenceNumber != null && referenceNumber.isNotEmpty) {
      query = query..where(orders.referenceNumber.like('%$referenceNumber%'));
    }

    if (statusAnyOf != null && statusAnyOf.isNotEmpty) {
      query = query..where(orders.status.isIn(statusAnyOf));
    } else if (status != null && status.isNotEmpty) {
      query = query..where(orders.status.equals(status));
    }

    if (orderType != null && orderType.isNotEmpty) {
      if (orderType == 'take_away') {
        query = query..where(orders.orderType.isNull() | orders.orderType.equals('take_away'));
      } else {
        query = query..where(orders.orderType.equals(orderType));
      }
    }

    if (deliveryPartner != null && deliveryPartner.isNotEmpty) {
      query = query..where(orders.deliveryPartner.like('%$deliveryPartner%'));
    }

    if (customerPhone != null && customerPhone.isNotEmpty) {
      query = query..where(orders.customerPhone.like('%$customerPhone%'));
    }

    if (startDate != null) {
      query = query..where(orders.createdAt.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query = query..where(orders.createdAt.isSmallerOrEqualValue(endDateTime));
    }

    if (driverId != null) {
      query = query..where(orders.driverId.equals(driverId));
    }

    if (userId != null) {
      query = query..where(orders.userId.equals(userId));
    }

    if (pickupToken != null && await _hasPickupTokenColumn()) {
      query = query..where(orders.pickupToken.equals(pickupToken));
    }

    query = query
      ..orderBy([
        OrderingTerm.desc(orders.createdAt),
        OrderingTerm.desc(orders.id),
      ]);
    if (limit != null && limit > 0) {
      query = query..limit(limit, offset: offset);
    }
    return query.map(_orderFromListRow).get();
  }

  /// Row count for [filterOrdersForList] with the same filters.
  Future<int> countOrdersForList({
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
    bool onlyRecentSaleSettled = false,
    String? paymentMethodKey,
    bool excludeKotStatus = false,
  }) async {
    final countExp = orders.id.count();
    var query = selectOnly(orders)..addColumns([countExp]);

    if (branchId != null) {
      query = query..where(orders.branchId.equals(branchId));
    }

    if (excludeKotStatus) {
      query = query..where(orders.status.equals('kot').not());
    }

    if (onlyRecentSaleSettled) {
      query = query..where(_recentSaleSettledSql);
    }

    final payPred = _listPaymentPredicate(paymentMethodKey);
    if (payPred != null) {
      query = query..where(payPred);
    }

    if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
      query = query..where(orders.invoiceNumber.like('%$invoiceNumber%'));
    }

    if (referenceNumber != null && referenceNumber.isNotEmpty) {
      query = query..where(orders.referenceNumber.like('%$referenceNumber%'));
    }

    if (statusAnyOf != null && statusAnyOf.isNotEmpty) {
      query = query..where(orders.status.isIn(statusAnyOf));
    } else if (status != null && status.isNotEmpty) {
      query = query..where(orders.status.equals(status));
    }

    if (orderType != null && orderType.isNotEmpty) {
      if (orderType == 'take_away') {
        query = query..where(orders.orderType.isNull() | orders.orderType.equals('take_away'));
      } else {
        query = query..where(orders.orderType.equals(orderType));
      }
    }

    if (deliveryPartner != null && deliveryPartner.isNotEmpty) {
      query = query..where(orders.deliveryPartner.like('%$deliveryPartner%'));
    }

    if (customerPhone != null && customerPhone.isNotEmpty) {
      query = query..where(orders.customerPhone.like('%$customerPhone%'));
    }

    if (startDate != null) {
      query = query..where(orders.createdAt.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query = query..where(orders.createdAt.isSmallerOrEqualValue(endDateTime));
    }

    if (driverId != null) {
      query = query..where(orders.driverId.equals(driverId));
    }

    if (userId != null) {
      query = query..where(orders.userId.equals(userId));
    }

    if (pickupToken != null && await _hasPickupTokenColumn()) {
      query = query..where(orders.pickupToken.equals(pickupToken));
    }

    final row = await query.getSingleOrNull();
    if (row == null) return 0;
    return row.read(countExp) ?? 0;
  }

  /// Matches [orderOutstandingCredit] — explicit `credit_amount` or unpaid gap after cash/card/online.
  static final Expression<bool> _hasOutstandingCreditSql = CustomExpression<bool>(
    "(credit_amount > 0.004 OR "
    "((CASE WHEN final_amount > 0.009 THEN final_amount ELSE total_amount END) "
    "- cash_amount - card_amount - online_amount) > 0.004)",
  );

  /// Credit sales list without loading [Orders.hubMetadata].
  Future<List<Order>> filterCreditSalesForList({
    required int branchId,
    int? userId,
    int limit = 400,
  }) async {
    final listCols = await _listOrderColumnsForQuery();
    var query = selectOnly(orders)..addColumns(listCols);
    query = query
      ..where(orders.branchId.equals(branchId))
      ..where(_hasOutstandingCreditSql)
      ..where(orders.status.equals('cancelled').not());
    if (userId != null) {
      query = query..where(orders.userId.equals(userId));
    }
    query = query
      ..orderBy([
        OrderingTerm.desc(orders.createdAt),
        OrderingTerm.desc(orders.id),
      ])
      ..limit(limit);
    return query.map(_orderFromListRow).get();
  }

  /// Highest numeric suffix for invoices in [branchId] and [prefix].
  ///
  /// Supports:
  /// - Current format: `PREFIX-branchId-###` (e.g. `INV-1-002`)
  /// - Legacy format: `PREFIX##` (e.g. `INV02`)
  Future<int> maxInvoiceNumericSuffixForPrefix(String prefix, {required int branchId}) {
    return maxInvoiceNumericSuffixForPrefixOnTable(
      accessor: this,
      tableName: 'orders',
      invoiceColumn: 'invoice_number',
      prefix: prefix,
      branchId: branchId,
    );
  }
}
