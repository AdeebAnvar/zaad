import 'package:pos/data/local/drift_database.dart';

abstract class OrderRepository {
  /// [cartLines] — use when cart rows are only in memory (avoids empty frozen snapshot).
  Future<int> createOrder(Order order, {List<CartItem>? cartLines});
  Future<List<Order>> getAllOrders();
  Future<List<Order>> getCompletedOrders();
  Future<Order?> getOrderById(int orderId);
  Future<List<Order>> getOrdersByDateRange(DateTime start, DateTime end);
  Future<void> updateOrderStatus(int orderId, String status);
  Future<void> deleteOrder(int orderId);
  Future<Order?> getKOTByReference(String referenceNumber);
  Future<void> updateOrder(Order order);

  /// Persists KOT header totals while the cart is edited — no hub freeze / cloud push.
  Future<void> updateKotTotalsLight(Order order);

  /// Save KOT: writes the order row immediately; hub freeze / cloud / LAN run after return.
  Future<int> saveKotOrder(Order order, {required List<CartItem> cartLines});

  /// Update existing KOT the same way as [saveKotOrder].
  Future<void> updateKotOrder(Order order, {required List<CartItem> cartLines});

  /// Pay / Submit — same fast path as KOT; finalize runs after the UI returns.
  Future<int> savePaidOrder(Order order, {required List<CartItem> cartLines});

  Future<void> updatePaidOrder(Order order, {required List<CartItem> cartLines});
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
    int? limit,
    List<String>? excludeStatusAnyOf,
  });

  /// Log screens: same filters as [filterOrders] but skips [Order.hubMetadata] in RAM.
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
    int? limit,
    int offset = 0,
    /// Exclude KOT/unsettled mirrors [orderCountsAsRecentSale].
    bool onlyRecentSaleSettled = false,
    String? paymentMethodKey,
    bool excludeKotStatus = false,
  });

  /// Row count for the same filters as [filterOrdersForList] (pagination UI).
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
    bool onlyRecentSaleSettled = false,
    String? paymentMethodKey,
    bool excludeKotStatus = false,
  });

  Future<List<Order>> getDeliveryOrdersWithDriver();

  /// Orders with any amount on credit (local), newest first. Excludes cancelled.
  Future<List<Order>> getCreditSales({int? userId});

  /// Next short receipt id for the channel (`TA01`, `DI02`, `DL01`, …).
  /// Serialized with [createCartWithReservedInvoice] so concurrent sales cannot reuse the same number.
  Future<String> getNextInvoiceNumber(String orderType);

  /// Open cart for counter add-to-cart — does **not** consume the next invoice (see [createCartWithReservedInvoice]).
  Future<int> createDraftCart({
    required String orderType,
    String? deliveryPartner,
    int? branchId,
  });

  /// Atomically allocates the next invoice number and creates the cart row (avoids duplicate INV under concurrency).
  /// [branchId] when set uses that branch for both invoice scoping and the cart row; otherwise the active session branch.
  Future<({String invoice, int cartId})> createCartWithReservedInvoice({
    required String orderType,
    String? deliveryPartner,
    int? branchId,
  });
}
