import 'dart:convert';

import 'package:drift/drift.dart' show Value;
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

  static AppDatabase? _dbOrNull() {
    try {
      final g = GetIt.instance;
      if (!g.isRegistered<AppDatabase>()) return null;
      return g<AppDatabase>();
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
          await _enqueueAndFlushMain(hub: hub, type: type, payload: payload);
        } catch (_) {
          /* keep unsynced in outbox */
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
          await _enqueueAndFlushMain(
            hub: hub,
            type: PosSyncEventTypes.delete,
            payload: payload,
          );
        } catch (_) {}
      });
    });
  }

  static Future<void> _enqueueAndFlushMain({
    required LocalHubSettings hub,
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final db = _dbOrNull();
    if (db == null) return;
    final eventId = const Uuid().v4();
    await db.syncQueueDao.insertOutbox(
      SyncOutboxCompanion.insert(
        id: eventId,
        eventType: type,
        payload: jsonEncode(payload),
      ),
    );
    await _flushMainOutboxBestEffort(hub: hub, db: db);
  }

  static Future<int> retryUnsyncedNow() async {
    final hub = _eligibleHubOrNull();
    final db = _dbOrNull();
    if (hub == null || db == null) return 0;
    return _flushMainOutboxBestEffort(hub: hub, db: db);
  }

  /// Queue any MAIN-originated WS sync event with ACK-backed outbox semantics.
  static Future<void> enqueueMainEventWithQueue({
    required String type,
    required Map<String, dynamic> payload,
  }) async {
    final hub = _eligibleHubOrNull();
    if (hub == null || hub.isHubSub) return;
    await _enqueueAndFlushMain(hub: hub, type: type, payload: payload);
  }

  static Future<int> _flushMainOutboxBestEffort({
    required LocalHubSettings hub,
    required AppDatabase db,
  }) async {
    final now = DateTime.now();
    final rows = await db.syncQueueDao.outboxWorkQueue(now);
    var acked = 0;
    for (final r in rows) {
      final ok = await _sendMainOutboxRowWithAck(hub: hub, row: r);
      if (ok) {
        acked++;
        await db.syncQueueDao.patchOutbox(
          r.id,
          const SyncOutboxCompanion(
            status: Value('ACKED'),
            nextRetryAfter: Value(null),
          ),
        );
      } else {
        await db.syncQueueDao.patchOutbox(
          r.id,
          SyncOutboxCompanion(
            status: const Value('FAILED'),
            retryCount: Value(r.retryCount + 1),
            nextRetryAfter: Value(now.add(Duration(seconds: _nextBackoffSec(r.retryCount + 1)))),
          ),
        );
      }
    }
    return acked;
  }

  static int _nextBackoffSec(int retryCount) => (1 << retryCount.clamp(0, 8)).clamp(1, 120);

  static Future<bool> _sendMainOutboxRowWithAck({
    required LocalHubSettings hub,
    required SyncOutboxData row,
  }) async {
    WebSocketChannel? ch;
    try {
      final decoded = jsonDecode(row.payload);
      final payload = Map<String, dynamic>.from(decoded as Map);
      await hub.resolveOrAllocateDeviceId(() => const Uuid().v4());
      final deviceId = hub.requireDeviceId();
      final uri = Uri.parse(hub.publishHubWsUrlOrLoopback.trim());
      ch = WebSocketChannel.connect(uri);
      detachWebSocketSinkDone(ch);

      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final connect = PosSyncEnvelope(
        eventId: const Uuid().v4(),
        type: PosSyncEventTypes.connect,
        payload: const <String, dynamic>{
          'clientRole': 'MAIN_CLIENT',
          'appMode': 'main',
        },
        timestamp: nowSec,
        deviceId: deviceId,
      );
      ch.sink.add(connect.encode());

      final env = PosSyncEnvelope(
        eventId: row.id,
        type: row.eventType,
        payload: payload,
        timestamp: nowSec,
        deviceId: deviceId,
      );
      ch.sink.add(env.encode());

      final rawAck = await ch.stream.firstWhere((dynamic raw) {
        try {
          final text = raw is String ? raw : utf8.decode(raw as List<int>);
          final ack = PosSyncEnvelope.tryDecode(text);
          if (ack == null || ack.type != PosSyncEventTypes.ack) return false;
          return ack.payload['forEventId']?.toString() == row.id;
        } catch (_) {
          return false;
        }
      }).timeout(const Duration(seconds: 5));

      final text = rawAck is String ? rawAck : utf8.decode(rawAck as List<int>);
      final ack = PosSyncEnvelope.tryDecode(text);
      final ok = ack != null && (ack.payload['ok'] == true || ack.payload['duplicate'] == true);
      return ok;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[HubOrderLanPublisher] MAIN send failed id=${row.id}: $e\n$st');
      }
      return false;
    } finally {
      try {
        await ch?.sink.close();
      } catch (_) {
        /* ignore */
      }
    }
  }
}
