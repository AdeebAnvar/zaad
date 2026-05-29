import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:get_it/get_it.dart';
import 'package:pos/core/services/backup_service.dart';
import 'package:synchronized/synchronized.dart';
import 'package:pos/core/constants/order_log_list_limits.dart';
import 'package:pos/core/sync/cloud_order_push_queue.dart';
import 'package:pos/core/sync/hub_order_lan_publisher.dart';
import 'package:pos/core/sync/outbound_push_coordinator.dart';
import 'package:pos/core/utils/credit_payment_metadata.dart';
import 'package:pos/core/utils/invoice_number_utils.dart';
import 'package:pos/core/utils/order_log_cart_fallback.dart';
import 'package:pos/core/utils/order_list_sort.dart';
import 'package:pos/core/utils/order_payment_utils.dart';
import 'package:pos/core/utils/sales_csv_backup.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/core/debug/agent_debug_log.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';
import 'package:pos/features/orders/data/hub_orders_payload_builder.dart';
import 'package:pos/presentation/dine_in_log/dine_in_reference_utils.dart';

/// Local-first orders in Drift; unsynced [OrderLog] rows drive [PushRecordsRepository] cloud upload.
class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this.db);

  final AppDatabase db;

  /// Shared across instances so parallel UI flows cannot read the same max suffix before another inserts a cart.
  static final Lock _invoiceAllocLock = Lock();
  static final Lock _pickupTokenAllocLock = Lock();

  Future<int> _activeBranchId() => db.sessionDao.requireActiveBranchId();

  void _afterMutation() {
    // Full XLSX export is debounced — never block checkout on workbook build.
    SalesCsvBackup.scheduleDebouncedRefresh(db);
    BackupService.instance.enqueueBackupAfterMutation(db);
    _notifyOrderLogsRefresh();
  }

  /// Runs backup/XLSX/hub refresh after the current frame so snackbars and navigation paint first.
  void _scheduleAfterMutation() {
    SchedulerBinding.instance.scheduleFrameCallback((_) => _afterMutation());
  }

  void _notifyOrderLogsRefresh() {
    try {
      final g = GetIt.instance;
      if (g.isRegistered<HubOrdersLiveSync>()) {
        g<HubOrdersLiveSync>().notifyHubOrdersChanged();
      }
    } catch (_) {
      /* DI not ready in tests */
    }
  }

  static String? _dineInRoutingRefFromOrderRow(Order order) {
    if ((order.orderType ?? '').trim().toLowerCase() != 'dine_in') return null;
    final r = order.referenceNumber?.trim();
    if (r == null || r.isEmpty) return null;
    if (DineInRefParser.extractLeadingFloorId(r) != null) return r;
    return null;
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
    final orderType = (order.orderType?.trim().isNotEmpty == true)
        ? order.orderType!.trim()
        : (flutter['order_type']?.toString() ?? 'take_away');
    return <String, dynamic>{
      'order_id': order.id,
      'cart_id': order.cartId,
      'branch_id': order.branchId,
      'invoice_number': order.invoiceNumber,
      'created_at': order.createdAt.toIso8601String(),
      'status': order.status,
      'delivery_partner': order.deliveryPartner,
      ...flutter,
      'order_type': orderType,
      if (cashierName != null) 'cashier_name': cashierName,
      'items': HubOrdersPayloadBuilder.cartLinesToJson(cartItems),
    };
  }

  /// Freeze line items on the order row so Recent Sales / day close never read another sale's cart lines.
  Future<Order> _persistFrozenLineSnapshotOnOrder(
    Order order,
    List<CartItem> cartItems,
    Map<String, dynamic> snapshot,
  ) async {
    final anchor = DineInRefParser.dineInAnchorFromHubMetadata(order.hubMetadata) ??
        _dineInRoutingRefFromOrderRow(order);
    final creditPayments = creditPaymentsFromHubMetadata(order.hubMetadata);
    dynamic appliedOffer;
    if (order.hubMetadata != null && order.hubMetadata!.trim().isNotEmpty) {
      try {
        final parsed = jsonDecode(order.hubMetadata!);
        if (parsed is Map && parsed['applied_offer'] != null) {
          appliedOffer = parsed['applied_offer'];
        }
      } catch (_) {}
    }
    final hubMeta = jsonEncode(<String, dynamic>{
      'orderId': HubOrderLanPublisher.hubOrderCorrelationId(order, order.id),
      'snapshot': snapshot,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      if (anchor != null && anchor.isNotEmpty) DineInRefParser.hubMetadataAnchorKey: anchor,
      if (creditPayments != null && creditPayments.isNotEmpty)
        'creditPayments': creditPayments,
      if (appliedOffer != null) 'applied_offer': appliedOffer,
    });
    await (db.update(db.orders)..where((o) => o.id.equals(order.id))).write(
      OrdersCompanion(hubMetadata: Value(hubMeta)),
    );
    return order.copyWith(hubMetadata: Value(hubMeta));
  }

  Future<void> _enqueueOutboundOrderSnapshot(
    Order order, {
    required List<CartItem> cartItems,
    required Map<String, dynamic> snapshotPayload,
  }) async {
    await enqueueOrderLogSnapshotForCloudPush(
      db: db,
      order: order,
      snapshotPayload: snapshotPayload,
    );
  }

  Future<List<CartItem>> _cartLinesForOrder(Order order, {List<CartItem>? cartLines}) async {
    if (cartLines != null && cartLines.isNotEmpty) return cartLines;
    final fromDb = await db.cartsDao.getItemsByCart(order.cartId);
    if (fromDb.isNotEmpty) return fromDb;
    return OrderLogCartFallback.resolveWithDb(order: order, db: db);
  }

  Order _withHubCorrelationIfUnset(Order row) {
    if ((row.serverOrderId ?? '').trim().isNotEmpty) return row;
    final key = HubOrderLanPublisher.hubOrderCorrelationId(row, row.id);
    return row.copyWith(serverOrderId: Value(key));
  }

  /// One re-read after write: hub freeze, cloud log, LAN mirror.
  Future<Order> _finalizePersistedOrder({
    required Order row,
    List<CartItem>? cartLines,
    required bool isCreate,
  }) async {
    final lines = await _cartLinesForOrder(row, cartLines: cartLines);
    final correlated = _withHubCorrelationIfUnset(row);
    await db.ordersDao.setHubCorrelationIfUnset(
      orderId: correlated.id,
      correlationId: HubOrderLanPublisher.hubOrderCorrelationId(correlated, correlated.id),
    );
    final snapshot = await _orderSnapshotMap(correlated, lines);
    final frozen = await _persistFrozenLineSnapshotOnOrder(correlated, lines, snapshot);
    if (frozen.status.toLowerCase() == 'kot') {
      unawaited(
        _enqueueOutboundOrderSnapshot(frozen, cartItems: lines, snapshotPayload: snapshot),
      );
    } else {
      await _enqueueOutboundOrderSnapshot(frozen, cartItems: lines, snapshotPayload: snapshot);
      scheduleOutboundPushAfterLocalOrder();
    }
    HubOrderLanPublisher.scheduleOrderUpsert(order: frozen, cartItems: lines, isCreate: isCreate);
    return frozen;
  }

  Future<int> _allocateNextPickupToken({int? branchIdOverride}) async {
    final bid = branchIdOverride ?? await _activeBranchId();
    final cutoff = await db.dayClosingCheckpointDao.lastSettledAtForBranch(bid);
    final max =
        await db.ordersDao.maxPickupTokenForBranchSince(bid, cutoff) ?? 0;
    return max + 1;
  }

  @override
  Future<int> allocateNextPickupToken({int? branchId}) {
    return _pickupTokenAllocLock.synchronized(
      () => _allocateNextPickupToken(branchIdOverride: branchId),
    );
  }

  Future<Value<int?>> _pickupTokenCompanionForNewOrder(
    Order order,
    int branchId,
  ) async {
    final existing = order.pickupToken;
    if (existing != null) {
      return Value(existing);
    }
    if (!orderTypeUsesPickupToken(order.orderType)) {
      return const Value.absent();
    }
    final token = await allocateNextPickupToken(branchId: branchId);
    return Value(token);
  }

  @override
  Future<int> createOrder(Order order, {List<CartItem>? cartLines}) async {
    final branchId = await _activeBranchId();
    final pickupToken = await _pickupTokenCompanionForNewOrder(order, branchId);
    final newId = await db.ordersDao.createOrder(
      OrdersCompanion.insert(
        cartId: order.cartId,
        invoiceNumber: order.invoiceNumber,
        branchId: Value(branchId),
        pickupToken: pickupToken,
        referenceNumber: Value(order.referenceNumber),
        totalAmount: order.totalAmount,
        discountAmount: Value(order.discountAmount),
        discountType: Value(order.discountType),
        finalAmount: order.finalAmount,
        customerName: Value(order.customerName),
        customerEmail: Value(order.customerEmail),
        customerPhone: Value(order.customerPhone),
        customerAddress: Value(order.customerAddress),
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
        hubMetadata: Value(order.hubMetadata),
        hubSyncPending: const Value(false),
      ),
    );
    final saved = await db.ordersDao.getOrderById(newId);
    if (saved == null) {
      throw StateError('createOrder failed to read row $newId');
    }
    await _finalizePersistedOrder(
      row: saved,
      cartLines: cartLines,
      isCreate: true,
    );
    _scheduleAfterMutation();
    return newId;
  }

  @override
  Future<List<Order>> getAllOrders() async {
    final bid = await _activeBranchId();
    return db.ordersDao.getAllOrders(branchId: bid);
  }

  @override
  Future<List<Order>> getCompletedOrders() async {
    final bid = await _activeBranchId();
    return db.ordersDao.getCompletedOrders(branchId: bid);
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
      final frozen = await _finalizePersistedOrder(row: row, isCreate: false);
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H2-H5',
        location: 'order_repository_impl.dart:updateOrderStatus',
        message: 'order_status_persisted',
        data: <String, Object?>{
          'orderId': orderId,
          'status': frozen.status,
          'orderType': frozen.orderType,
          'invoice': frozen.invoiceNumber,
        },
      );
      // #endregion
    }
    _scheduleAfterMutation();
  }

  @override
  Future<void> deleteOrder(int orderId) async {
    final existing = await db.ordersDao.getOrderById(orderId);
    final hubOid = HubOrderLanPublisher.hubOrderCorrelationId(existing, orderId);
    await db.ordersDao.deleteOrderLogsForLocalOrderId(orderId);
    await db.ordersDao.deleteOrder(orderId);
    HubOrderLanPublisher.scheduleDelete(hubOrderId: hubOid);
    _scheduleAfterMutation();
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
      final frozen = await _finalizePersistedOrder(row: row, isCreate: false);
      // #region agent log
      if ((frozen.orderType ?? '').contains('delivery') || frozen.orderType == 'take_away') {
        agentDebugLog(
          hypothesisId: 'H1-H2',
          location: 'order_repository_impl.dart:updateOrder',
          message: 'order_update_persisted',
          data: <String, Object?>{
            'orderId': frozen.id,
            'status': frozen.status,
            'orderType': frozen.orderType,
            'invoice': frozen.invoiceNumber,
            'paid': frozen.cashAmount + frozen.cardAmount + frozen.creditAmount + frozen.onlineAmount,
          },
        );
      }
      // #endregion
    }
    _scheduleAfterMutation();
  }

  @override
  Future<int> saveKotOrder(Order order, {required List<CartItem> cartLines}) async {
    final branchId = await _activeBranchId();
    final pickupToken = await _pickupTokenCompanionForNewOrder(order, branchId);
    final newId = await db.ordersDao.createOrder(
      OrdersCompanion.insert(
        cartId: order.cartId,
        invoiceNumber: order.invoiceNumber,
        branchId: Value(branchId),
        pickupToken: pickupToken,
        referenceNumber: Value(order.referenceNumber),
        totalAmount: order.totalAmount,
        discountAmount: Value(order.discountAmount),
        discountType: Value(order.discountType),
        finalAmount: order.finalAmount,
        customerName: Value(order.customerName),
        customerEmail: Value(order.customerEmail),
        customerPhone: Value(order.customerPhone),
        customerAddress: Value(order.customerAddress),
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
        hubMetadata: Value(order.hubMetadata),
        hubSyncPending: const Value(false),
      ),
    );
    final saved = await db.ordersDao.getOrderById(newId);
    if (saved == null) {
      throw StateError('saveKotOrder failed to read row $newId');
    }
    _notifyOrderLogsRefresh();
    await _finalizePersistedOrder(row: saved, cartLines: cartLines, isCreate: true);
    _scheduleAfterMutation();
    return newId;
  }

  @override
  Future<void> updateKotOrder(Order order, {required List<CartItem> cartLines}) async {
    await db.ordersDao.updateOrder(order.toCompanion(false));
    _notifyOrderLogsRefresh();
    await _finalizePersistedOrder(row: order, cartLines: cartLines, isCreate: false);
    _scheduleAfterMutation();
  }

  @override
  Future<int> savePaidOrder(Order order, {required List<CartItem> cartLines}) =>
      saveKotOrder(order, cartLines: cartLines);

  @override
  Future<void> updatePaidOrder(Order order, {required List<CartItem> cartLines}) =>
      updateKotOrder(order, cartLines: cartLines);

  @override
  Future<void> updateKotTotalsLight(Order order) async {
    await db.ordersDao.updateKotOrderTotals(
      orderId: order.id,
      totalAmount: order.totalAmount,
      finalAmount: order.finalAmount,
      cartId: order.cartId,
      referenceNumber: order.referenceNumber != null
          ? Value(order.referenceNumber)
          : const Value.absent(),
      hubMetadata: order.hubMetadata != null
          ? Value(order.hubMetadata)
          : const Value.absent(),
    );
    _notifyOrderLogsRefresh();
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
    int? limit,
    List<String>? excludeStatusAnyOf,
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
      limit: limit,
      excludeStatusAnyOf: excludeStatusAnyOf,
    );
  }

  @override
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
    bool onlyRecentSaleSettled = false,
    String? paymentMethodKey,
    bool excludeKotStatus = false,
  }) async {
    final bid = await _activeBranchId();
    return db.ordersDao.filterOrdersForList(
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
      pickupToken: pickupToken,
      branchId: bid,
      limit: limit,
      offset: offset,
      onlyRecentSaleSettled: onlyRecentSaleSettled,
      paymentMethodKey: paymentMethodKey,
      excludeKotStatus: excludeKotStatus,
    );
  }

  @override
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
  }) async {
    final bid = await _activeBranchId();
    return db.ordersDao.countOrdersForList(
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
      pickupToken: pickupToken,
      branchId: bid,
      onlyRecentSaleSettled: onlyRecentSaleSettled,
      paymentMethodKey: paymentMethodKey,
      excludeKotStatus: excludeKotStatus,
    );
  }

  @override
  Future<List<Order>> getDeliveryOrdersWithDriver() async {
    final bid = await _activeBranchId();
    return db.ordersDao.getDeliveryOrdersWithDriver(branchId: bid);
  }

  @override
  Future<List<Order>> getCreditSales({int? userId}) async {
    final bid = await _activeBranchId();
    final list = await db.ordersDao.filterCreditSalesForList(
      branchId: bid,
      userId: userId,
      limit: kOrderLogDefaultListLimit,
    );
    list.retainWhere(
      (o) => orderOutstandingCredit(o) > 0.004 || orderCreditSaleAmount(o) > 0.004,
    );
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

  @override
  Future<String> reserveInvoiceForCart({
    required int cartId,
    required String orderType,
    int? branchId,
  }) {
    return _invoiceAllocLock.synchronized(() async {
      final existingCart = await db.cartsDao.getCartByCartId(cartId);
      final existingInvoice = existingCart?.invoiceNumber.trim() ?? '';
      if (existingInvoice.isNotEmpty) return existingInvoice;
      final invoice = await _allocateNextInvoiceNumber(orderType, branchIdOverride: branchId);
      await db.cartsDao.updateCartInvoiceNumber(cartId, invoice);
      return invoice;
    });
  }
}
