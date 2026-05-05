import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/sync/pos_sync_wire.dart';
import 'package:pos/core/sync/ws_detach_done_errors.dart';
import 'package:pos/core/sync/sync_inbox_applier.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/branch_repository.dart';
import 'package:pos/data/repository/pull_data_repository.dart';
import 'package:pos/data/repository/settings_repository.dart';
import 'package:pos/data/repository/user_repository.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// PRIMARY POS: long-lived WebSocket **listener** to the Node hub.
///
/// Ingests cashier [`ORDER_CREATE`]/[`ORDER_UPDATE`]/[`DELETE`] only (no journal replay, no
/// catalog mirror) so SUB-originated KOT/payments land in MAIN's Drift and [`push_records`]
/// runs from this machine.
class LocalHubPrimaryInboundCoordinator {
  LocalHubPrimaryInboundCoordinator({
    required AppDatabase db,
    required LocalHubSettings settings,
    required HubOrdersLiveSync ordersLiveSync,
    required PullDataRepository pullData,
    required UserRepository userRepo,
    required BranchRepository branchRepo,
    required SettingsRepository settingsRepo,
  })  : _db = db,
        _settings = settings,
        _ordersLive = ordersLiveSync,
        _applier = SyncInboxApplier(
          db,
          settings,
          ordersLiveSync,
          pullData,
          userRepo: userRepo,
          branchRepo: branchRepo,
          settingsRepo: settingsRepo,
        );

  final AppDatabase _db;
  final LocalHubSettings _settings;
  final HubOrdersLiveSync _ordersLive;
  final SyncInboxApplier _applier;

  static const _uuid = Uuid();

  static const _orderIngestTypes = <String>{
    PosSyncEventTypes.orderCreate,
    PosSyncEventTypes.orderUpdate,
    PosSyncEventTypes.delete,
  };

  bool _stopDesired = false;
  bool _loopRunning = false;
  WebSocketChannel? _channel;
  int _backoffSec = 1;

  bool get _enabled {
    if (_settings.blocksTenantCloudRest) return false;
    return _settings.publishHubWsUrlOrLoopback.trim().isNotEmpty;
  }

  Future<void> startIfEnabled() async {
    if (!_enabled) return;
    await _settings.resolveOrAllocateDeviceId(_uuid.v4);
    _stopDesired = false;
    if (_loopRunning) return;
    _loopRunning = true;
    unawaited(_connectionLoop());
  }

  void stop() {
    _stopDesired = true;
    unawaited(_channel?.sink.close());
    _channel = null;
  }

  Future<void> reconnectFromSettings() async {
    stop();
    for (var i = 0; i < 40 && _loopRunning; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    await startIfEnabled();
  }

  Future<void> _connectionLoop() async {
    while (!_stopDesired) {
      if (!_enabled) {
        await Future<void>.delayed(const Duration(seconds: 2));
        continue;
      }

      if (_backoffSec > 0) {
        await Future<void>.delayed(Duration(seconds: _backoffSec));
      }
      if (_stopDesired) break;

      try {
        final uri = Uri.parse(_settings.publishHubWsUrlOrLoopback.trim());
        final ch = WebSocketChannel.connect(uri);
        _channel = ch;
        _backoffSec = 1;
        detachWebSocketSinkDone(ch);

        await _handshakeConnectOnly(ch);

        final disconnected = Completer<void>();
        Object? streamErr;
        StackTrace? streamSt;
        late final StreamSubscription<dynamic> sub;
        sub = ch.stream.listen(
          (dynamic raw) {
            if (_stopDesired) return;
            unawaited(Future<void>(() async {
              try {
                final s = _stringFromDynamic(raw);
                await _onRawMessage(s);
              } catch (e, st) {
                if (kDebugMode) {
                  debugPrint('[LocalHubPrimaryInbound] inbound message handler: $e\n$st');
                }
              }
            }));
          },
          onError: (Object e, StackTrace st) {
            streamErr = e;
            streamSt = st;
            if (!disconnected.isCompleted) disconnected.complete();
          },
          onDone: () {
            if (!disconnected.isCompleted) disconnected.complete();
          },
          cancelOnError: false,
        );

        await disconnected.future;
        await sub.cancel();

        if (streamErr != null) {
          if (kDebugMode) {
            debugPrint('[LocalHubPrimaryInbound] socket error: $streamErr\n$streamSt');
          }
          _backoffSec = (_backoffSec * 2).clamp(1, 120);
        }
      } catch (e, st) {
        if (kDebugMode) debugPrint('[LocalHubPrimaryInbound] socket error: $e\n$st');
        _backoffSec = (_backoffSec * 2).clamp(1, 120);
      } finally {
        try {
          await _channel?.sink.close();
        } catch (_) {
          /* ignore */
        }
        _channel = null;
      }
    }
    _loopRunning = false;
  }

  String _stringFromDynamic(dynamic raw) {
    if (raw is String) return raw;
    return utf8.decode(raw as List<int>);
  }

  Future<void> _handshakeConnectOnly(WebSocketChannel ch) async {
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final deviceId = _settings.requireDeviceId();
    final connect = PosSyncEnvelope(
      eventId: _uuid.v4(),
      type: PosSyncEventTypes.connect,
      payload: const <String, dynamic>{},
      timestamp: ts,
      deviceId: deviceId,
    );
    ch.sink.add(connect.encode());

    // Replay SUB-originated order events missed while disconnected (hub journal).
    final syncReq = PosSyncEnvelope(
      eventId: _uuid.v4(),
      type: PosSyncEventTypes.syncRequest,
      payload: <String, dynamic>{'lastSyncTimestamp': _settings.lastJournalMs},
      timestamp: ts,
      deviceId: deviceId,
    );
    ch.sink.add(syncReq.encode());
  }

  Future<void> _onRawMessage(String raw) async {
    if (raw.trim().isEmpty) return;

    if (raw.startsWith('{') && raw.contains('"error"')) {
      try {
        final map = jsonDecode(raw);
        if (map is Map && map['error'] != null && kDebugMode) {
          debugPrint('[LocalHubPrimaryInbound] server error: ${map['error']} ${map['detail'] ?? ''}');
        }
      } catch (_) {
        /* ignore */
      }
      return;
    }

    final env = PosSyncEnvelope.tryDecode(raw);
    if (env == null) return;

    if (env.type == PosSyncEventTypes.ack || env.type == PosSyncEventTypes.connect) {
      return;
    }

    if (env.type == PosSyncEventTypes.syncResponse) {
      await _ingestSyncResponse(env);
      return;
    }

    if (!_orderIngestTypes.contains(env.type)) {
      return;
    }

    // Avoid re-applying this POS's own ORDER_* (publish uses a second socket; hub echoes to listeners).
    final mainDid = _settings.requireDeviceId();
    if (env.deviceId == mainDid) {
      return;
    }

    await _persistInboxAndApply(env, raw);
    _ordersLive.notifyHubOrdersChanged();
  }

  Future<void> _maybeAdvanceWatermark(int candidateMs) async {
    final cur = _settings.lastJournalMs;
    if (candidateMs > cur) await _settings.saveLastJournalMs(candidateMs);
  }

  /// Apply only order-related journal rows (same applier as live broadcast).
  Future<void> _ingestSyncResponse(PosSyncEnvelope env) async {
    final p = env.payload;

    final list = p['events'];
    if (list is! List<dynamic>) return;

    for (final item in list) {
      final inner = PosSyncJournalReplay.envelopeFromItem(item);
      if (inner == null) continue;
      final effMs = PosSyncJournalReplay.watermarkMs(item, inner);

      if (!_orderIngestTypes.contains(inner.type)) {
        await _maybeAdvanceWatermark(effMs);
        continue;
      }
      if (inner.deviceId == _settings.requireDeviceId()) {
        await _maybeAdvanceWatermark(effMs);
        continue;
      }

      final encoded = inner.encode();
      await _persistInboxAndApply(inner, encoded);
      await _maybeAdvanceWatermark(effMs);
    }

    _ordersLive.notifyHubOrdersChanged();
  }

  Future<void> _persistInboxAndApply(PosSyncEnvelope env, String raw) async {
    final existing = await _db.syncQueueDao.inboxRowByEventId(env.eventId);
    if (existing != null) {
      if (existing.applied) return;
      try {
        await _applier.apply(existing.id, env, env.payload);
        await _db.syncQueueDao.markInboxApplied(existing.id);
        if (kDebugMode && _orderIngestTypes.contains(env.type)) {
          debugPrint('[LocalHubPrimaryInbound] reapplied ${env.type} ${env.eventId}');
        }
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[LocalHubPrimaryInbound] reapply failed ${env.type} ${env.eventId}: $e\n$st');
        }
      }
      return;
    }

    final inboxPk = _uuid.v4();
    await _db.into(_db.syncInbox).insert(
          SyncInboxCompanion.insert(
            id: inboxPk,
            eventId: env.eventId,
            type: env.type,
            payload: jsonEncode(env.payload),
            rawEnvelope: raw,
          ),
        );

    try {
      await _applier.apply(inboxPk, env, env.payload);
      await _db.syncQueueDao.markInboxApplied(inboxPk);
      if (kDebugMode && _orderIngestTypes.contains(env.type)) {
        debugPrint('[LocalHubPrimaryInbound] applied ${env.type} ${env.eventId}');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[LocalHubPrimaryInbound] apply failed ${env.type} ${env.eventId}: $e\n$st');
      }
    }
  }
}
