import 'package:drift/drift.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final AppDatabase db;

  OrderRepositoryImpl(this.db);

  @override
  Future<int> createOrder(Order order) {
    return db.ordersDao.createOrder(
      OrdersCompanion.insert(
        cartId: order.cartId,
        invoiceNumber: order.invoiceNumber,
        referenceNumber: Value(order.referenceNumber),
        totalAmount: order.totalAmount,
        discountAmount: Value(order.discountAmount),
        discountType: Value(order.discountType),
        finalAmount: order.finalAmount,
        customerName: Value(order.customerName),
        customerEmail: Value(order.customerEmail),
        customerPhone: Value(order.customerPhone),
        customerGender: Value(order.customerGender),
        cashAmount: Value(order.cashAmount),
        creditAmount: Value(order.creditAmount),
        cardAmount: Value(order.cardAmount),
        onlineAmount: Value(order.onlineAmount),
        createdAt: order.createdAt,
        status: Value(order.status),
        orderType: Value(order.orderType),
        deliveryPartner: Value(order.deliveryPartner),
      ),
    );
  }

  @override
  Future<List<Order>> getAllOrders() {
    return db.ordersDao.getAllOrders();
  }

  @override
  Future<Order?> getOrderById(int orderId) {
    return db.ordersDao.getOrderById(orderId);
  }

  @override
  Future<List<Order>> getOrdersByDateRange(DateTime start, DateTime end) {
    return db.ordersDao.getOrdersByDateRange(start, end);
  }

  @override
  Future<void> updateOrderStatus(int orderId, String status) {
    return db.ordersDao.updateOrderStatus(orderId, status);
  }

  @override
  Future<void> deleteOrder(int orderId) {
    return db.ordersDao.deleteOrder(orderId);
  }

  @override
  Future<Order?> getKOTByReference(String referenceNumber) {
    return db.ordersDao.getKOTByReference(referenceNumber);
  }

  @override
  Future<void> updateOrder(Order order) {
    return db.ordersDao.updateOrder(
      OrdersCompanion(
        id: Value(order.id),
        cartId: Value(order.cartId),
        invoiceNumber: Value(order.invoiceNumber),
        referenceNumber: Value(order.referenceNumber),
        totalAmount: Value(order.totalAmount),
        discountAmount: Value(order.discountAmount),
        discountType: Value(order.discountType),
        finalAmount: Value(order.finalAmount),
        customerName: Value(order.customerName),
        customerEmail: Value(order.customerEmail),
        customerPhone: Value(order.customerPhone),
        customerGender: Value(order.customerGender),
        cashAmount: Value(order.cashAmount),
        creditAmount: Value(order.creditAmount),
        cardAmount: Value(order.cardAmount),
        onlineAmount: Value(order.onlineAmount),
        createdAt: Value(order.createdAt),
        status: Value(order.status),
        orderType: Value(order.orderType),
        deliveryPartner: Value(order.deliveryPartner),
      ),
    );
  }

  @override
  Future<List<Order>> filterOrders({
    String? invoiceNumber,
    String? referenceNumber,
    String? status,
    String? orderType,
    String? deliveryPartner,
    String? customerPhone,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return db.ordersDao.filterOrders(
      invoiceNumber: invoiceNumber,
      referenceNumber: referenceNumber,
      status: status,
      orderType: orderType,
      deliveryPartner: deliveryPartner,
      customerPhone: customerPhone,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
