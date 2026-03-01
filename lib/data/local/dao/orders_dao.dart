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
  
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('placed'))(); // placed, completed, cancelled, kot
}

@DriftAccessor(tables: [
  Orders,
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

  Future<List<Order>> filterOrders({
    String? invoiceNumber,
    String? referenceNumber,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
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

    if (startDate != null) {
      query = query..where((o) => o.createdAt.isBiggerOrEqualValue(startDate));
    }

    if (endDate != null) {
      // Add one day to include the entire end date
      final endDateTime = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      query = query..where((o) => o.createdAt.isSmallerOrEqualValue(endDateTime));
    }

    return (query..orderBy([(o) => OrderingTerm.desc(o.createdAt)])).get();
  }
}
