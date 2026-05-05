import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/sync/local_hub_sync_coordinator.dart';
import 'package:pos/core/sync/ws_detach_done_errors.dart';
import 'package:pos/core/sync/pos_sync_wire.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/features/orders/data/hub_orders_payload_builder.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Pushes [`ORDER_CREATE`] / [`ORDER_UPDATE`] / [`DELETE`] through the LAN Node hub so
/// other terminals apply the same Drift-shaped snapshot as [`SyncInboxApplier._upsertOrder`].
///
/// MAIN uses a short-lived WebSocket send (same pattern as [HubCatalogLanPublisher]); SUB queues
/// [LocalHubSyncCoordinator.enqueueOutbound] when connected as `hub_sub`.
class HubOrderLanPublisher {
  HubOrderLanPublisher._();

  static const _maxApproxBytes = 12 * 1024 * 1024;

  static Future<void>? _serial;

  static Map<String, dynamic> _snapshotMap(Order order, List<CartItem> cartItems) {
    final flutter = HubOrdersPayloadBuilder.flutterBlockFromDraft(order);
    return <String, dynamic>{
      'order_id': order.id,
      'cart_id': order.cartId,
      'invoice_number': order.invoiceNumber,
      'created_at': order.createdAt.toIso8601String(),
      'status': order.status,
      ...flutter,
      'items': HubOrdersPayloadBuilder.cartLinesToJson(cartItems),
    };
  }

  static LocalHubSettings? _eligibleHubOrNull() {
    try {
      final g = GetIt.instance;
      if (!g.isRegistered<LocalHubSettings>()) return null;
      final hub = g<LocalHubSettings>();
      if (hub.publishHubWsUrlOrLoopback.isEmpty) return null;
      return hub;
    } catch (_) {
      return null;
    }
  }

  /// LAN identity for deletes: preferred [serverOrderId] when present, else local row id string.
  static String hubOrderCorrelationId(Order? row, int fallbackLocalOrderId) {
    final sid = row?.serverOrderId?.trim();
    if (sid != null && sid.isNotEmpty) return sid;
    return fallbackLocalOrderId.toString();
  }

  static void scheduleOrderUpsert({
    required Order order,
    required List<CartItem> cartItems,
    required bool isCreate,
  }) {
    if (order.id <= 0) return;

    Future.microtask(() {
      final hub = _eligibleHubOrNull();
      if (hub == null) return;

      final snapshot = _snapshotMap(order, cartItems);
      final payload = <String, dynamic>{
        'orderId': hubOrderCorrelationId(order, order.id),
        'snapshot': snapshot,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      try {
        final approx = utf8.encode(jsonEncode(payload)).length;
        if (approx > _maxApproxBytes) {
          if (kDebugMode) debugPrint('[HubOrderLanPublisher] skip oversize (${approx}b) order=${order.id}');
          return;
        }
      } catch (_) {
        return;
      }

      final type = isCreate ? PosSyncEventTypes.orderCreate : PosSyncEventTypes.orderUpdate;

      if (hub.isHubSub) {
        final g = GetIt.instance;
        if (!g.isRegistered<LocalHubSyncCoordinator>()) return;
        _serial = (_serial ?? Future<void>.value()).then((_) async {
          try {
            await g<LocalHubSyncCoordinator>().enqueueOutbound(type, payload);
          } catch (_) {
            /* ignore LAN flush errors — retried via outbox */
          }
        });
        return;
      }

      _serial = (_serial ?? Future<void>.value()).then((_) async {
        try {
          await _publishMainEnvelope(hub, type, payload);
        } catch (_) {
          /* ignore transient WS errors */
        }
      });
    });
  }

  static void scheduleDelete({required String hubOrderId}) {
    Future.microtask(() {
      final hub = _eligibleHubOrNull();
      if (hub == null || hubOrderId.isEmpty) return;

      final payload = <String, dynamic>{
        'entity': 'orders',
        'id': hubOrderId,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (hub.isHubSub) {
        final g = GetIt.instance;
        if (!g.isRegistered<LocalHubSyncCoordinator>()) return;
        _serial = (_serial ?? Future<void>.value()).then((_) async {
          try {
            await g<LocalHubSyncCoordinator>().enqueueOutbound(PosSyncEventTypes.delete, payload);
          } catch (_) {}
        });
        return;
      }

      _serial = (_serial ?? Future<void>.value()).then((_) async {
        try {
          await _publishMainEnvelope(hub, PosSyncEventTypes.delete, payload);
        } catch (_) {}
      });
    });
  }

  static Future<void> _publishMainEnvelope(
    LocalHubSettings hub,
    String type,
    Map<String, dynamic> payload,
  ) async {
    WebSocketChannel? ch;
    try {
      await hub.resolveOrAllocateDeviceId(() => const Uuid().v4());
      final deviceId = hub.requireDeviceId();
      final uri = Uri.parse(hub.publishHubWsUrlOrLoopback.trim());
      ch = WebSocketChannel.connect(uri);
      detachWebSocketSinkDone(ch);
      final env = PosSyncEnvelope(
        eventId: const Uuid().v4(),
        type: type,
        payload: payload,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        deviceId: deviceId,
      );
      ch.sink.add(env.encode());
      if (kDebugMode) debugPrint('[HubOrderLanPublisher] MAIN sent $type orderId=${payload['orderId'] ?? payload['id']}');
    } catch (e, st) {
      if (kDebugMode) debugPrint('[HubOrderLanPublisher] MAIN send failed: $e\n$st');
    } finally {
      try {
        await ch?.sink.close();
      } catch (_) {
        /* ignore */
      }
    }
  }
}
