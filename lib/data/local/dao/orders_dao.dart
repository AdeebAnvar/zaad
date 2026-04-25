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
  OrdersDao(AppDatabase db) : super(db);

  /* ───────── ORDERS ───────── */

  Future<int> createOrder(OrdersCompanion order) {
    return into(orders).insert(order);
  }

  Future<List<Order>> getAllOrders() {
    return (select(orders)..orderBy([(o) => OrderingTerm.desc(o.createdAt)])).get();
  }

  Future<Order?> getOrderById(int orderId) {
    return (select(orders)..where((o) => o.id.equals(orderId))).getSingleOrNull();
  }

  Future<List<Order>> getOrdersByDateRange(DateTime start, DateTime end) {
    return (select(orders)
          ..where((o) => o.createdAt.isBiggerOrEqualValue(start))
          ..where((o) => o.createdAt.isSmallerOrEqualValue(end))
          ..orderBy([(o) => OrderingTerm.desc(o.createdAt)]))
        .get();
  }

  Future<void> updateOrderStatus(int orderId, String status) {
    return (update(orders)..where((o) => o.id.equals(orderId)))
        .write(OrdersCompanion(status: Value(status)));
  }

  Future<void> deleteOrder(int orderId) {
    return (delete(orders)..where((o) => o.id.equals(orderId))).go();
  }

  Future<Order?> getKOTByReference(String referenceNumber) async {
    final query = select(orders)
      ..where((o) => o.referenceNumber.equals(referenceNumber))
      ..where((o) => o.status.equals('kot'))
      ..orderBy([(o) => OrderingTerm.desc(o.id)])
      ..limit(1);
    final list = await query.get();
    return list.isEmpty ? null : list.first;
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

  /// Normal delivery orders that have a driver assigned (for driver log).
  Future<List<Order>> getDeliveryOrdersWithDriver() {
    return (select(orders)
          ..where((o) => o.orderType.equals('delivery'))
          ..where((o) => o.driverId.isNotNull())
          ..orderBy([(o) => OrderingTerm.desc(o.createdAt)]))
        .get();
  }

  Future<List<Order>> filterOrders({
    String? invoiceNumber,
    String? referenceNumber,
    String? status,
    String? orderType,
    String? deliveryPartner,
    String? customerPhone,
    DateTime? startDate,
    DateTime? endDate,
    int? driverId,
  }) {
    var query = select(orders);

    if (invoiceNumber != null && invoiceNumber.isNotEmpty) {
      query = query..where((o) => o.invoiceNumber.like('%$invoiceNumber%'));
    }

    if (referenceNumber != null && referenceNumber.isNotEmpty) {
      query = query..where((o) => o.referenceNumber.like('%$referenceNumber%'));
    }

    if (status != null && status.isNotEmpty) {
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

    return (query..orderBy([(o) => OrderingTerm.desc(o.createdAt)])).get();
  }

  /// Highest numeric suffix for invoices starting with [prefix] (e.g. `TA` → `TA01` → 1).
  Future<int> maxInvoiceNumericSuffixForPrefix(String prefix) async {
    final rows = await (select(orders)..where((o) => o.invoiceNumber.like('$prefix%'))).get();
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
