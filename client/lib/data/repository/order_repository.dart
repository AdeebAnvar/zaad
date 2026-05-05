import 'package:pos/data/local/drift_database.dart';

abstract class OrderRepository {
  Future<int> createOrder(Order order);
  Future<List<Order>> getAllOrders();
  Future<Order?> getOrderById(int orderId);
  Future<List<Order>> getOrdersByDateRange(DateTime start, DateTime end);
  Future<void> updateOrderStatus(int orderId, String status);
  Future<void> deleteOrder(int orderId);
  Future<Order?> getKOTByReference(String referenceNumber);
  Future<void> updateOrder(Order order);
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
  });

  Future<List<Order>> getDeliveryOrdersWithDriver();

  /// Orders with any amount on credit (local), newest first. Excludes cancelled.
  Future<List<Order>> getCreditSales();

  /// Next short receipt id for the channel (`TA01`, `DI02`, `DL01`, …).
  /// Serialized with [createCartWithReservedInvoice] so concurrent sales cannot reuse the same number.
  Future<String> getNextInvoiceNumber(String orderType);

  /// Atomically allocates the next invoice number and creates the cart row (avoids duplicate INV under concurrency).
  /// [branchId] when set uses that branch for both invoice scoping and the cart row; otherwise the active session branch.
  Future<({String invoice, int cartId})> createCartWithReservedInvoice({
    required String orderType,
    String? deliveryPartner,
    int? branchId,
  });
}
