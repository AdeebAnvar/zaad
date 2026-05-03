import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/features/orders/data/hub_orders_payload_builder.dart';
/// Applies hub JSON envelopes into Drift (cache only).
class HubOrdersSync {
  HubOrdersSync(this._db);

  final AppDatabase _db;

  static dynamic _pick(Map<String, dynamic> m, String snake, [String? camel]) {
    if (m.containsKey(snake)) return m[snake];
    if (camel != null && m.containsKey(camel)) return m[camel];
    return null;
  }

  static Map<String, dynamic>? _mapFrom(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  static Map<String, dynamic>? _parseMetadataField(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.isNotEmpty) {
      try {
        final d = jsonDecode(raw);
        if (d is Map<String, dynamic>) return d;
        if (d is Map) return Map<String, dynamic>.from(d);
      } catch (_) {}
    }
    return null;
  }

  /// Returns local Drift `orders.id` after upsert.
  Future<int> applyHubEnvelope(Map<String, dynamic> body) async {
    final orderMap = _mapFrom(body['order']);
    if (orderMap == null) {
      throw StateError('hub envelope missing order');
    }

    final serverId = '${_pick(orderMap, 'id') ?? ''}';
    if (serverId.isEmpty) {
      throw StateError('hub order missing id');
    }

    final invoiceRaw = _pick(orderMap, 'invoice_number', 'invoiceNumber');
    final invoiceStr = invoiceRaw == null ? serverId : '$invoiceRaw';

    final meta = _parseMetadataField(_pick(orderMap, 'metadata'));
    final flutter = meta != null ? _mapFrom(meta['flutter']) : null;

    final status = '${_pick(orderMap, 'status') ?? 'open'}';
    final totalCentsRaw = _pick(orderMap, 'total_cents', 'totalCents');
    final totalFromServer = totalCentsRaw is num ? totalCentsRaw.toDouble() / 100.0 : null;

    final createdRaw = _pick(orderMap, 'created_at', 'createdAt');
    final createdAt = _parseDate(createdRaw) ?? DateTime.now();

    final paymentsBody = body['payments'];
    final paySplit = _paymentsFromHubList(paymentsBody);

    double totalAmount = _asDouble(flutter?['total_amount']) ?? totalFromServer ?? 0;
    double finalAmount = _asDouble(flutter?['final_amount']) ?? totalFromServer ?? totalAmount;
    double discountAmount = _asDouble(flutter?['discount_amount']) ?? 0;
    final discountType = flutter?['discount_type'] as String?;

    if (flutter == null && totalFromServer != null) {
      totalAmount = totalFromServer;
      finalAmount = totalFromServer;
    }

    String? customerName = flutter?['customer_name'] as String?;
    String? customerEmail = flutter?['customer_email'] as String?;
    String? customerPhone = flutter?['customer_phone'] as String?;
    String? customerGender = flutter?['customer_gender'] as String?;

    double cash = _asDouble(flutter?['cash_amount']) ?? paySplit.cash;
    double credit = _asDouble(flutter?['credit_amount']) ?? paySplit.credit;
    double card = _asDouble(flutter?['card_amount']) ?? paySplit.card;
    double online = _asDouble(flutter?['online_amount']) ?? paySplit.online;

    final referenceNumber = flutter?['reference_number'] as String?;
    final orderType = flutter?['order_type'] as String?;
    final deliveryPartner = flutter?['delivery_partner'] as String?;
    final driverId = _asInt(flutter?['driver_id']);
    final driverName = flutter?['driver_name'] as String?;
    final userId = _asInt(flutter?['user_id']);

    final cartIdPreferred = _asInt(flutter?['cart_id']);
    final cartId = await _resolveCartId(
      preferredLocalId: cartIdPreferred,
      invoiceLabel: invoiceStr,
      orderType: orderType,
      deliveryPartner: deliveryPartner,
    );

    final hubMetaJson = jsonEncode({
      'source': 'hub',
      'envelope': body,
    });

    final existing = await _db.ordersDao.getOrderByServerId(serverId);
    if (existing != null) {
      await (_db.update(_db.orders)..where((o) => o.id.equals(existing.id))).write(
        OrdersCompanion(
          cartId: Value(cartId),
          invoiceNumber: Value(invoiceStr),
          referenceNumber: Value(referenceNumber),
          totalAmount: Value(totalAmount),
          discountAmount: Value(discountAmount),
          discountType: Value(discountType),
          finalAmount: Value(finalAmount),
          customerName: Value(customerName),
          customerEmail: Value(customerEmail),
          customerPhone: Value(customerPhone),
          customerGender: Value(customerGender),
          cashAmount: Value(cash),
          creditAmount: Value(credit),
          cardAmount: Value(card),
          onlineAmount: Value(online),
          createdAt: Value(createdAt),
          status: Value(status),
          orderType: Value(orderType),
          deliveryPartner: Value(deliveryPartner),
          driverId: Value(driverId),
          driverName: Value(driverName),
          userId: Value(userId),
          serverOrderId: Value(serverId),
          hubMetadata: Value(hubMetaJson),
          hubSyncPending: const Value(false),
        ),
      );

      return existing.id;
    }

    final insertedId = await _db.ordersDao.createOrder(
      OrdersCompanion.insert(
        cartId: cartId,
        invoiceNumber: invoiceStr,
        referenceNumber: Value(referenceNumber),
        totalAmount: totalAmount,
        discountAmount: Value(discountAmount),
        discountType: Value(discountType),
        finalAmount: finalAmount,
        customerName: Value(customerName),
        customerEmail: Value(customerEmail),
        customerPhone: Value(customerPhone),
        customerGender: Value(customerGender),
        cashAmount: Value(cash),
        creditAmount: Value(credit),
        cardAmount: Value(card),
        onlineAmount: Value(online),
        createdAt: createdAt,
        status: Value(status),
        orderType: Value(orderType),
        deliveryPartner: Value(deliveryPartner),
        driverId: Value(driverId),
        driverName: Value(driverName),
        userId: Value(userId),
        serverOrderId: Value(serverId),
        hubMetadata: Value(hubMetaJson),
        hubSyncPending: const Value(false),
      ),
    );

    await _insertOrderLogSnapshot(
      localOrderId: insertedId,
      cartId: cartId,
      serverId: serverId,
      invoiceStr: invoiceStr,
      flutter: flutter,
      cartLineSnapshot: meta?['cart_lines'],
    );

    return insertedId;
  }

  Future<int> _resolveCartId({
    required int? preferredLocalId,
    required String invoiceLabel,
    required String? orderType,
    required String? deliveryPartner,
  }) async {
    if (preferredLocalId != null) {
      final existing = await _db.cartsDao.getCartByCartId(preferredLocalId);
      if (existing != null) {
        return preferredLocalId;
      }
    }
    return _db.cartsDao.createCart(
      invoiceLabel,
      orderType: orderType,
      deliveryPartner: deliveryPartner,
    );
  }

  Future<void> _insertOrderLogSnapshot({
    required int localOrderId,
    required int cartId,
    required String serverId,
    required String invoiceStr,
    required Map<String, dynamic>? flutter,
    required dynamic cartLineSnapshot,
  }) async {
    final snapshot = <String, dynamic>{
      'order_id': localOrderId,
      'server_order_id': serverId,
      'cart_id': cartId,
      'invoice_number': invoiceStr,
      if (flutter != null) ...flutter,
      'items': cartLineSnapshot,
    };
    await _db.ordersDao.insertOrderLog(jsonEncode(snapshot));
  }

  static DateTime? _parseDate(dynamic v) {
    if (v is String) {
      return DateTime.tryParse(v);
    }
    return null;
  }

  static double? _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return null;
  }

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  /// LOCAL offline: persist draft locally before hub POST succeeds.
  Future<int> insertOfflineDraftOrder(
    Order draft, {
    required String pendingActionId,
    required String correlationId,
  }) async {
    final hubMetaJson = jsonEncode({
      'source': 'offline_local',
      'pending_action_id': pendingActionId,
      'correlation_id': correlationId,
      'flutter': HubOrdersPayloadBuilder.flutterBlockFromDraft(draft),
    });
    return _db.ordersDao.createOrder(
      OrdersCompanion.insert(
        cartId: draft.cartId,
        invoiceNumber: draft.invoiceNumber,
        referenceNumber: Value(draft.referenceNumber),
        totalAmount: draft.totalAmount,
        discountAmount: Value(draft.discountAmount),
        discountType: Value(draft.discountType),
        finalAmount: draft.finalAmount,
        customerName: Value(draft.customerName),
        customerEmail: Value(draft.customerEmail),
        customerPhone: Value(draft.customerPhone),
        customerGender: Value(draft.customerGender),
        cashAmount: Value(draft.cashAmount),
        creditAmount: Value(draft.creditAmount),
        cardAmount: Value(draft.cardAmount),
        onlineAmount: Value(draft.onlineAmount),
        createdAt: draft.createdAt,
        status: Value(draft.status),
        orderType: Value(draft.orderType),
        deliveryPartner: Value(draft.deliveryPartner),
        driverId: Value(draft.driverId),
        driverName: Value(draft.driverName),
        userId: Value(draft.userId),
        hubSyncPending: const Value(true),
        hubMetadata: Value(hubMetaJson),
      ),
    );
  }

  /// After offline CREATE syncs, merge hub response into the **existing** local row (no duplicate).
  Future<int> applyHubEnvelopeMergeLocal({
    required int localOrderId,
    required Map<String, dynamic> body,
  }) async {
    final existingLocal = await _db.ordersDao.getOrderById(localOrderId);
    if (existingLocal == null) {
      throw StateError('offline merge: missing local order $localOrderId');
    }

    final orderMap = _mapFrom(body['order']);
    if (orderMap == null) {
      throw StateError('hub envelope missing order');
    }

    final serverId = '${_pick(orderMap, 'id') ?? ''}';
    if (serverId.isEmpty) {
      throw StateError('hub order missing id');
    }

    final invoiceRaw = _pick(orderMap, 'invoice_number', 'invoiceNumber');
    final invoiceStr = invoiceRaw == null ? serverId : '$invoiceRaw';

    final meta = _parseMetadataField(_pick(orderMap, 'metadata'));
    final flutter = meta != null ? _mapFrom(meta['flutter']) : null;

    final status = '${_pick(orderMap, 'status') ?? 'open'}';
    final totalCentsRaw = _pick(orderMap, 'total_cents', 'totalCents');
    final totalFromServer = totalCentsRaw is num ? totalCentsRaw.toDouble() / 100.0 : null;

    final createdRaw = _pick(orderMap, 'created_at', 'createdAt');
    final createdAt = _parseDate(createdRaw) ?? DateTime.now();

    final paymentsBody = body['payments'];
    final paySplit = _paymentsFromHubList(paymentsBody);

    double totalAmount = _asDouble(flutter?['total_amount']) ?? totalFromServer ?? 0;
    double finalAmount = _asDouble(flutter?['final_amount']) ?? totalFromServer ?? totalAmount;
    double discountAmount = _asDouble(flutter?['discount_amount']) ?? 0;
    final discountType = flutter?['discount_type'] as String?;

    if (flutter == null && totalFromServer != null) {
      totalAmount = totalFromServer;
      finalAmount = totalFromServer;
    }

    String? customerName = flutter?['customer_name'] as String?;
    String? customerEmail = flutter?['customer_email'] as String?;
    String? customerPhone = flutter?['customer_phone'] as String?;
    String? customerGender = flutter?['customer_gender'] as String?;

    double cash = _asDouble(flutter?['cash_amount']) ?? paySplit.cash;
    double credit = _asDouble(flutter?['credit_amount']) ?? paySplit.credit;
    double card = _asDouble(flutter?['card_amount']) ?? paySplit.card;
    double online = _asDouble(flutter?['online_amount']) ?? paySplit.online;

    final referenceNumber = flutter?['reference_number'] as String?;
    final orderType = flutter?['order_type'] as String?;
    final deliveryPartner = flutter?['delivery_partner'] as String?;
    final driverId = _asInt(flutter?['driver_id']);
    final driverName = flutter?['driver_name'] as String?;
    final userId = _asInt(flutter?['user_id']);

    final cartIdPreferred = _asInt(flutter?['cart_id']);
    final cartId = await _resolveCartId(
      preferredLocalId: cartIdPreferred,
      invoiceLabel: invoiceStr,
      orderType: orderType,
      deliveryPartner: deliveryPartner,
    );

    final hubMetaJson = jsonEncode({
      'source': 'hub',
      'envelope': body,
      'merged_from_offline_local_id': localOrderId,
    });

    await (_db.update(_db.orders)..where((o) => o.id.equals(localOrderId))).write(
      OrdersCompanion(
        cartId: Value(cartId),
        invoiceNumber: Value(invoiceStr),
        referenceNumber: Value(referenceNumber),
        totalAmount: Value(totalAmount),
        discountAmount: Value(discountAmount),
        discountType: Value(discountType),
        finalAmount: Value(finalAmount),
        customerName: Value(customerName),
        customerEmail: Value(customerEmail),
        customerPhone: Value(customerPhone),
        customerGender: Value(customerGender),
        cashAmount: Value(cash),
        creditAmount: Value(credit),
        cardAmount: Value(card),
        onlineAmount: Value(online),
        createdAt: Value(createdAt),
        status: Value(status),
        orderType: Value(orderType),
        deliveryPartner: Value(deliveryPartner),
        driverId: Value(driverId),
        driverName: Value(driverName),
        userId: Value(userId),
        serverOrderId: Value(serverId),
        hubMetadata: Value(hubMetaJson),
        hubSyncPending: const Value(false),
      ),
    );

    return localOrderId;
  }

  /// Remove cached row when hub deletes an order (`ORDER_DELETED` or after `DELETE /orders/:id`).
  Future<void> evictByServerId(String serverId) async {
    final trimmed = serverId.trim();
    if (trimmed.isEmpty) return;
    final row = await _db.ordersDao.getOrderByServerId(trimmed);
    if (row == null) return;
    await _db.ordersDao.deleteOrder(row.id);
  }

  static _PaySplit _paymentsFromHubList(dynamic raw) {
    final out = _PaySplit();
    if (raw is! List) return out;
    for (final p in raw) {
      final m = _mapFrom(p);
      if (m == null) continue;
      final method = '${m['method'] ?? ''}'.toLowerCase();
      final cents = m['amount_cents'] ?? m['amountCents'];
      final amt = cents is num ? cents.toDouble() / 100.0 : 0.0;
      switch (method) {
        case 'cash':
          out.cash += amt;
          break;
        case 'credit':
          out.credit += amt;
          break;
        case 'card':
          out.card += amt;
          break;
        case 'online':
        case 'other':
          out.online += amt;
          break;
        default:
          out.online += amt;
      }
    }
    return out;
  }
}

class _PaySplit {
  double cash = 0;
  double credit = 0;
  double card = 0;
  double online = 0;
}
