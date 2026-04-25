import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:pos/core/services/backup_service.dart';
import 'package:pos/core/utils/sales_csv_backup.dart';
import 'package:pos/core/utils/invoice_number_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final AppDatabase db;

  OrderRepositoryImpl(this.db);

  @override
  Future<int> createOrder(Order order) async {
    late final int id;
    await db.transaction(() async {
      id = await db.ordersDao.createOrder(
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
          driverId: Value(order.driverId),
          driverName: Value(order.driverName),
        ),
      );
      final cartItems = await db.cartsDao.getItemsByCart(order.cartId);
      final snapshot = _buildOrderSnapshot(order: order, orderId: id, cartItems: cartItems);
      await db.ordersDao.insertOrderLog(jsonEncode(snapshot));
    });
    await SalesCsvBackup.refreshFromDatabase(db);
    await BackupService.instance.recordOrderMutation(db);
    return id;
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
  Future<void> updateOrderStatus(int orderId, String status) async {
    await db.ordersDao.updateOrderStatus(orderId, status);
    await SalesCsvBackup.refreshFromDatabase(db);
    await BackupService.instance.recordOrderMutation(db);
  }

  @override
  Future<void> deleteOrder(int orderId) async {
    await db.ordersDao.deleteOrder(orderId);
    await SalesCsvBackup.refreshFromDatabase(db);
    await BackupService.instance.recordOrderMutation(db);
  }

  @override
  Future<Order?> getKOTByReference(String referenceNumber) {
    return db.ordersDao.getKOTByReference(referenceNumber);
  }

  @override
  Future<void> updateOrder(Order order) async {
    await db.ordersDao.updateOrder(
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
        driverId: Value(order.driverId),
        driverName: Value(order.driverName),
      ),
    );
    await SalesCsvBackup.refreshFromDatabase(db);
    await BackupService.instance.recordOrderMutation(db);
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
    int? driverId,
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
      driverId: driverId,
    );
  }

  @override
  Future<List<Order>> getDeliveryOrdersWithDriver() {
    return db.ordersDao.getDeliveryOrdersWithDriver();
  }

  @override
  Future<List<Order>> getCreditSales() async {
    final all = await db.ordersDao.getAllOrders();
    return all
        .where((o) => o.creditAmount > 0.004 && o.status != 'cancelled')
        .toList();
  }

  @override
  Future<String> getNextInvoiceNumber(String orderType) async {
    final prefix = invoicePrefixForOrderType(orderType);
    final oMax = await db.ordersDao.maxInvoiceNumericSuffixForPrefix(prefix);
    final cMax = await db.cartsDao.maxInvoiceNumericSuffixForPrefix(prefix);
    final next = (oMax > cMax ? oMax : cMax) + 1;
    return formatShortInvoice(prefix, next);
  }

  Map<String, dynamic> _buildOrderSnapshot({
    required Order order,
    required int orderId,
    required List<CartItem> cartItems,
  }) {
    return {
      'order_id': orderId,
      'cart_id': order.cartId,
      'invoice_number': order.invoiceNumber,
      'reference_number': order.referenceNumber,
      'total_amount': order.totalAmount,
      'discount_amount': order.discountAmount,
      'discount_type': order.discountType,
      'final_amount': order.finalAmount,
      'customer_name': order.customerName,
      'customer_email': order.customerEmail,
      'customer_phone': order.customerPhone,
      'customer_gender': order.customerGender,
      'cash_amount': order.cashAmount,
      'credit_amount': order.creditAmount,
      'card_amount': order.cardAmount,
      'online_amount': order.onlineAmount,
      'status': order.status,
      'order_type': order.orderType,
      'delivery_partner': order.deliveryPartner,
      'driver_id': order.driverId,
      'driver_name': order.driverName,
      'created_at': order.createdAt.toIso8601String(),
      'items': cartItems
          .map(
            (item) => {
              'id': item.id,
              'cart_id': item.cartId,
              'item_id': item.itemId,
              'item_variant_id': item.itemVariantId,
              'item_topping_id': item.itemToppingId,
              'quantity': item.quantity,
              'total': item.total,
              'discount': item.discount,
              'discount_type': item.discountType,
              'notes': item.notes,
            },
          )
          .toList(),
    };
  }
}
