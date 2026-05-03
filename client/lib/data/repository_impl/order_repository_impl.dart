import 'package:pos/core/config/pos_app_runtime_config.dart';
import 'package:pos/core/network/pos_api_service.dart';
import 'package:pos/core/network/pos_hub_device_identity.dart';
import 'package:pos/core/network/pos_server_settings.dart';
import 'package:pos/core/services/backup_service.dart';
import 'package:pos/core/utils/invoice_number_utils.dart';
import 'package:pos/core/utils/sales_csv_backup.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/features/orders/data/hub_orders_payload_builder.dart';
import 'package:pos/features/orders/data/hub_orders_sync.dart';
import 'package:pos/features/orders/data/local_hub_pending_queue.dart';
import 'package:uuid/uuid.dart';

/// Orders: hub is authoritative — Drift is filled via [HubOrdersSync] after API/WebSocket envelopes.
/// LOCAL + hub: transient failures enqueue [pending_actions] and persist drafts locally.
class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(
    this.db, {
    required PosServerSettings hubSettings,
    required PosApiService hubApi,
    required HubOrdersSync hubSync,
    required PosHubDeviceIdentity hubDevice,
    required PosAppRuntimeConfig runtime,
    required LocalHubPendingQueue hubPendingQueue,
  })  : _hubSettings = hubSettings,
        _hubApi = hubApi,
        _hubSync = hubSync,
        _hubDevice = hubDevice,
        _runtime = runtime,
        _hubPendingQueue = hubPendingQueue;

  final AppDatabase db;
  final PosServerSettings _hubSettings;
  final PosApiService _hubApi;
  final HubOrdersSync _hubSync;
  final PosHubDeviceIdentity _hubDevice;
  final PosAppRuntimeConfig _runtime;
  final LocalHubPendingQueue _hubPendingQueue;

  @override
  bool get hubConfigured => (_hubSettings.baseUrl ?? '').trim().isNotEmpty;

  bool get _offlineQueueEligible => _runtime.isLocal && hubConfigured;

  void _requireHub() {
    if (!hubConfigured) {
      throw StateError(
        'LAN hub URL required — set pos_server_base_url (Node hub), not the tenant API URL from login.',
      );
    }
  }

  String _correlationFromMetadata(String? hubMetadata) {
    final root = HubOrdersPayloadBuilder.decodeEnvelopeMetadata(hubMetadata);
    final existing = root?['correlation_id'];
    if (existing is String && existing.isNotEmpty) return existing;
    return const Uuid().v4();
  }

  Future<void> _afterMutation() async {
    await SalesCsvBackup.refreshFromDatabase(db);
    await BackupService.instance.recordOrderMutation(db);
  }

  @override
  Future<int> createOrder(Order order) async {
    _requireHub();
    final cartItems = await db.cartsDao.getItemsByCart(order.cartId);
    final deviceId = await _hubDevice.getOrCreateUuid();
    final correlationId = const Uuid().v4();
    final payload = HubOrdersPayloadBuilder.buildJson(
      draft: order,
      cartItems: cartItems,
      deviceUuid: deviceId,
      correlationId: correlationId,
    );
    try {
      final res = await _hubApi.createOrder(payload);
      final id = await _hubSync.applyHubEnvelope(res);
      await _afterMutation();
      return id;
    } catch (_) {
      if (!_offlineQueueEligible) rethrow;
      final pendingActionId = const Uuid().v4();
      final localId = await _hubSync.insertOfflineDraftOrder(
        order,
        pendingActionId: pendingActionId,
        correlationId: correlationId,
      );
      await _hubPendingQueue.enqueueCreateOrder(
        localOrderId: localId,
        hubBody: payload,
        actionId: pendingActionId,
      );
      await _afterMutation();
      return localId;
    }
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
    _requireHub();
    final row = await db.ordersDao.getOrderById(orderId);
    if (row == null) return;

    final sid = row.serverOrderId?.trim();
    if (sid == null || sid.isEmpty) {
      if (!_offlineQueueEligible) {
        throw StateError('Order #$orderId has no hub id yet; sync from server or finalize checkout via hub.');
      }
      final updated = row.copyWith(status: status);
      await db.ordersDao.updateOrder(updated.toCompanion(false));
      final cartItems = await db.cartsDao.getItemsByCart(row.cartId);
      final deviceId = await _hubDevice.getOrCreateUuid();
      final correlationId = _correlationFromMetadata(row.hubMetadata);
      await _hubPendingQueue.replacePendingCreatePayload(
        localOrderId: orderId,
        hubBody: HubOrdersPayloadBuilder.buildJson(
          draft: updated,
          cartItems: cartItems,
          deviceUuid: deviceId,
          correlationId: correlationId,
        ),
      );
      await _afterMutation();
      return;
    }

    try {
      final envelope = await _hubApi.patchOrderStatus(serverOrderId: sid, status: status);
      await _hubSync.applyHubEnvelope(envelope);
    } catch (_) {
      if (!_offlineQueueEligible) rethrow;
      final updated = row.copyWith(status: status);
      await db.ordersDao.updateOrder(updated.toCompanion(false));
      await _hubPendingQueue.enqueueUpdateOrder(
        localOrderId: orderId,
        serverOrderId: sid,
        patchBody: {'status': status},
      );
    }
    await _afterMutation();
  }

  @override
  Future<void> deleteOrder(int orderId) async {
    _requireHub();
    final row = await db.ordersDao.getOrderById(orderId);
    if (row == null) return;

    final sid = row.serverOrderId?.trim();
    if (sid == null || sid.isEmpty) {
      if (!_offlineQueueEligible) {
        throw StateError('Order #$orderId has no hub id yet; sync from server or finalize checkout via hub.');
      }
      await _hubPendingQueue.cancelPendingCreate(orderId);
      await db.ordersDao.deleteOrder(orderId);
      await _afterMutation();
      return;
    }

    try {
      await _hubApi.deleteOrderByServerId(sid);
      await _hubSync.evictByServerId(sid);
    } catch (_) {
      if (!_offlineQueueEligible) rethrow;
      await _hubPendingQueue.enqueueDeleteOrder(localOrderId: orderId, serverOrderId: sid);
      await _hubSync.evictByServerId(sid);
    }
    await _afterMutation();
  }

  @override
  Future<Order?> getKOTByReference(String referenceNumber) {
    return db.ordersDao.getKOTByReference(referenceNumber);
  }

  @override
  Future<void> updateOrder(Order order) async {
    _requireHub();
    final row = await db.ordersDao.getOrderById(order.id);
    if (row == null) return;

    final sid = row.serverOrderId?.trim();
    final cartItems = await db.cartsDao.getItemsByCart(order.cartId);
    final patch = HubOrdersPayloadBuilder.patchBodyFromDraft(draft: order, cartItems: cartItems);

    if (sid == null || sid.isEmpty) {
      if (!_offlineQueueEligible) {
        throw StateError('Order #${order.id} has no hub id yet; sync from server or finalize checkout via hub.');
      }
      await db.ordersDao.updateOrder(order.toCompanion(false));
      final deviceId = await _hubDevice.getOrCreateUuid();
      final correlationId = _correlationFromMetadata(row.hubMetadata);
      await _hubPendingQueue.replacePendingCreatePayload(
        localOrderId: order.id,
        hubBody: HubOrdersPayloadBuilder.buildJson(
          draft: order,
          cartItems: cartItems,
          deviceUuid: deviceId,
          correlationId: correlationId,
        ),
      );
      await _afterMutation();
      return;
    }

    try {
      final envelope = await _hubApi.patchOrder(serverOrderId: sid, body: patch);
      await _hubSync.applyHubEnvelope(envelope);
    } catch (_) {
      if (!_offlineQueueEligible) rethrow;
      await db.ordersDao.updateOrder(order.toCompanion(false));
      await _hubPendingQueue.enqueueUpdateOrder(
        localOrderId: order.id,
        serverOrderId: sid,
        patchBody: patch,
      );
    }
    await _afterMutation();
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
    int? userId,
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
      userId: userId,
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
    if (hubConfigured) {
      return 'DRAFT-${DateTime.now().millisecondsSinceEpoch}';
    }
    final session = await db.sessionDao.getActiveSession();
    final branch = session == null ? null : await db.branchesDao.getBranchById(session.branchId);
    final branchPrefix = branch?.prefixInv.trim();
    final prefix =
        (branchPrefix != null && branchPrefix.isNotEmpty) ? branchPrefix : invoicePrefixForOrderType(orderType);
    final oMax = await db.ordersDao.maxInvoiceNumericSuffixForPrefix(prefix);
    final cMax = await db.cartsDao.maxInvoiceNumericSuffixForPrefix(prefix);
    final next = (oMax > cMax ? oMax : cMax) + 1;
    return formatShortInvoice(prefix, next);
  }
}
