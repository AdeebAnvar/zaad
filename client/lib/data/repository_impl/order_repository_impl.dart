import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:pos/core/services/backup_service.dart';
import 'package:synchronized/synchronized.dart';
import 'package:pos/core/sync/cloud_order_push_queue.dart';
import 'package:pos/core/sync/hub_order_lan_publisher.dart';
import 'package:pos/core/sync/outbound_push_coordinator.dart';
import 'package:pos/core/utils/invoice_number_utils.dart';
import 'package:pos/core/utils/order_list_sort.dart';
import 'package:pos/core/utils/sales_csv_backup.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/features/orders/data/hub_orders_payload_builder.dart';

/// Local-first orders in Drift; unsynced [OrderLog] rows drive [PushRecordsRepository] cloud upload.
class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this.db);

  final AppDatabase db;

  /// Shared across instances so parallel UI flows cannot read the same max suffix before another inserts a cart.
  static final Lock _invoiceAllocLock = Lock();

  Future<int> _activeBranchId() => db.sessionDao.requireActiveBranchId();

  Future<void> _afterMutation() async {
    await SalesCsvBackup.refreshFromDatabase(db);
    await BackupService.instance.recordOrderMutation(db);
  }

  Future<Map<String, dynamic>> _orderSnapshotMap(Order order, List<CartItem> cartItems) async {
    final flutter = HubOrdersPayloadBuilder.flutterBlockFromDraft(order);
    String? cashierName;
    final uid = order.userId;
    if (uid != null) {
      final u = await db.usersDao.findUserById(uid);
      final n = u?.name.trim() ?? '';
      if (n.isNotEmpty) cashierName = n;
    }
    return <String, dynamic>{
      'order_id': order.id,
      'cart_id': order.cartId,
      'invoice_number': order.invoiceNumber,
      'created_at': order.createdAt.toIso8601String(),
      'status': order.status,
      ...flutter,
      if (cashierName != null) 'cashier_name': cashierName,
      'items': HubOrdersPayloadBuilder.cartLinesToJson(cartItems),
    };
  }

  Future<String> _orderSnapshotJson(Order order, List<CartItem> cartItems) async =>
      jsonEncode(await _orderSnapshotMap(order, cartItems));

  Future<void> _enqueueOutboundOrderSnapshot(Order order) async {
    final cartItems = await db.cartsDao.getItemsByCart(order.cartId);
    await enqueueOrderLogSnapshotForCloudPush(
      db: db,
      order: order,
      snapshotPayload: await _orderSnapshotMap(order, cartItems),
    );
  }

  @override
  Future<int> createOrder(Order order) async {
    final branchId = await _activeBranchId();
    final newId = await db.ordersDao.createOrder(
      OrdersCompanion.insert(
        cartId: order.cartId,
        invoiceNumber: order.invoiceNumber,
        branchId: Value(branchId),
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
        userId: Value(order.userId),
        hubSyncPending: const Value(false),
      ),
    );
    final saved = await db.ordersDao.getOrderById(newId);
    if (saved == null) {
      throw StateError('createOrder failed to read row $newId');
    }
    final cartItems = await db.cartsDao.getItemsByCart(saved.cartId);
    await db.ordersDao.insertOrderLog(await _orderSnapshotJson(saved, cartItems));
    await _afterMutation();
    scheduleOutboundPushAfterLocalOrder();
    await db.ordersDao.setHubCorrelationIfUnset(
      orderId: newId,
      correlationId: HubOrderLanPublisher.hubOrderCorrelationId(saved, saved.id),
    );
    final forHub = await db.ordersDao.getOrderById(newId) ?? saved;
    HubOrderLanPublisher.scheduleOrderUpsert(order: forHub, cartItems: cartItems, isCreate: true);
    return newId;
  }

  @override
  Future<List<Order>> getAllOrders() async {
    final bid = await _activeBranchId();
    return db.ordersDao.getAllOrders(branchId: bid);
  }

  @override
  Future<Order?> getOrderById(int orderId) {
    return db.ordersDao.getOrderById(orderId);
  }

  @override
  Future<List<Order>> getOrdersByDateRange(DateTime start, DateTime end) async {
    final bid = await _activeBranchId();
    return db.ordersDao.getOrdersByDateRange(start, end, branchId: bid);
  }

  @override
  Future<void> updateOrderStatus(int orderId, String status) async {
    await db.ordersDao.updateOrderStatus(orderId, status);
    final row = await db.ordersDao.getOrderById(orderId);
    if (row != null) {
      await db.ordersDao.setHubCorrelationIfUnset(
        orderId: row.id,
        correlationId: HubOrderLanPublisher.hubOrderCorrelationId(row, row.id),
      );
      final patched = await db.ordersDao.getOrderById(row.id) ?? row;
      await _enqueueOutboundOrderSnapshot(patched);
      final cartItems = await db.cartsDao.getItemsByCart(patched.cartId);
      HubOrderLanPublisher.scheduleOrderUpsert(order: patched, cartItems: cartItems, isCreate: false);
    }
    await _afterMutation();
  }

  @override
  Future<void> deleteOrder(int orderId) async {
    final existing = await db.ordersDao.getOrderById(orderId);
    final hubOid = HubOrderLanPublisher.hubOrderCorrelationId(existing, orderId);
    await db.ordersDao.deleteOrderLogsForLocalOrderId(orderId);
    await db.ordersDao.deleteOrder(orderId);
    await _afterMutation();
    HubOrderLanPublisher.scheduleDelete(hubOrderId: hubOid);
  }

  @override
  Future<Order?> getKOTByReference(String referenceNumber) async {
    final bid = await _activeBranchId();
    return db.ordersDao.getKOTByReference(referenceNumber, branchId: bid);
  }

  @override
  Future<void> updateOrder(Order order) async {
    await db.ordersDao.updateOrder(order.toCompanion(false));
    final row = await db.ordersDao.getOrderById(order.id);
    if (row != null) {
      await db.ordersDao.setHubCorrelationIfUnset(
        orderId: row.id,
        correlationId: HubOrderLanPublisher.hubOrderCorrelationId(row, row.id),
      );
      final patched = await db.ordersDao.getOrderById(row.id) ?? row;
      await _enqueueOutboundOrderSnapshot(patched);
      final cartItems = await db.cartsDao.getItemsByCart(patched.cartId);
      HubOrderLanPublisher.scheduleOrderUpsert(order: patched, cartItems: cartItems, isCreate: false);
    }
    await _afterMutation();
  }

  @override
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
  }) async {
    final bid = await _activeBranchId();
    return db.ordersDao.filterOrders(
      invoiceNumber: invoiceNumber,
      referenceNumber: referenceNumber,
      status: status,
      statusAnyOf: statusAnyOf,
      orderType: orderType,
      deliveryPartner: deliveryPartner,
      customerPhone: customerPhone,
      startDate: startDate,
      endDate: endDate,
      driverId: driverId,
      userId: userId,
      branchId: bid,
    );
  }

  @override
  Future<List<Order>> getDeliveryOrdersWithDriver() async {
    final bid = await _activeBranchId();
    return db.ordersDao.getDeliveryOrdersWithDriver(branchId: bid);
  }

  @override
  Future<List<Order>> getCreditSales() async {
    final bid = await _activeBranchId();
    final all = await db.ordersDao.getAllOrders(branchId: bid);
    final list = all.where((o) => o.creditAmount > 0.004 && o.status != 'cancelled').toList();
    sortOrdersNewestFirst(list);
    return list;
  }

  Future<String> _allocateNextInvoiceNumber(String orderType, {int? branchIdOverride}) async {
    final bid = branchIdOverride ?? await db.sessionDao.requireActiveBranchId();
    final branch = await db.branchesDao.getBranchById(bid);
    final branchPrefix = branch?.prefixInv.trim();
    final prefix =
        (branchPrefix != null && branchPrefix.isNotEmpty) ? branchPrefix : invoicePrefixForOrderType(orderType);
    final oMax = await db.ordersDao.maxInvoiceNumericSuffixForPrefix(prefix, branchId: bid);
    final cMax = await db.cartsDao.maxInvoiceNumericSuffixForPrefix(prefix, branchId: bid);
    final next = (oMax > cMax ? oMax : cMax) + 1;
    return formatShortInvoice(prefix, bid, next);
  }

  @override
  Future<String> getNextInvoiceNumber(String orderType) {
    return _invoiceAllocLock.synchronized(() => _allocateNextInvoiceNumber(orderType));
  }

  @override
  Future<({String invoice, int cartId})> createCartWithReservedInvoice({
    required String orderType,
    String? deliveryPartner,
    int? branchId,
  }) async {
    return _invoiceAllocLock.synchronized(() async {
      final invoice = await _allocateNextInvoiceNumber(orderType, branchIdOverride: branchId);
      final cartBranchId = branchId ?? await db.sessionDao.requireActiveBranchId();
      final cartId = await db.cartsDao.createCart(
        invoice,
        orderType: orderType,
        deliveryPartner: deliveryPartner,
        branchId: cartBranchId,
      );
      return (invoice: invoice, cartId: cartId);
    });
  }
}
