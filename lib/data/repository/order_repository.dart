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
    String? orderType,
    String? deliveryPartner,
    String? customerPhone,
    DateTime? startDate,
    DateTime? endDate,
  });
}
