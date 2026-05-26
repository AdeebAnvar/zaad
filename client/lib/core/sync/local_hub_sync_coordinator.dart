import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart' show Value;
import 'package:pos/core/debug/agent_debug_log.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/sync/pos_sync_wire.dart';
import 'package:pos/core/sync/ws_detach_done_errors.dart';
import 'package:pos/core/sync/hub_inbound_dispatch.dart';
import 'package:pos/core/sync/sync_inbox_applier.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/branch_repository.dart';
import 'package:pos/data/repository/pull_data_repository.dart';
import 'package:pos/data/repository/settings_repository.dart';
import 'package:pos/data/repository/user_repository.dart';
import 'package:pos/features/day_closing/data/day_closing_live_sync.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// SUB-side WebSocket client: outbox flush, inbox persistence, ACK handling, reconnect + backoff.
class LocalHubSyncCoordinator {
  LocalHubSyncCoordinator({
    required AppDatabase db,
    required LocalHubSettings settings,
    required HubOrdersLiveSync ordersLiveSync,
    required PullDataRepository pullData,
    required UserRepository userRepo,
    required BranchRepository branchRepo,
    required SettingsRepository settingsRepo,
    DayClosingLiveSync? dayClosingLiveSync,
  })  : _db = db,
        _settings = settings,
        _ordersLive = ordersLiveSync,
        _dayClosingLive = dayClosingLiveSync,
        _applier = SyncInboxApplier(
          db,
          settings,
          ordersLiveSync,
          pullData,
          userRepo: userRepo,
          branchRepo: branchRepo,
          settingsRepo: settingsRepo,
          dayClosingLiveSync: dayClosingLiveSync,
        );

  final AppDatabase _db;
  final LocalHubSettings _settings;
  final HubOrdersLiveSync _ordersLive;
  final DayClosingLiveSync? _dayClosingLive;
  final SyncInboxApplier _applier;

  static const _uuid = Uuid();

  bool _stopDesired = false;
  bool _loopRunning = false;
  WebSocketChannel? _channel;
  int _backoffSec = 0;
  bool _fastReconnectRequested = false;

  /// True while a hub WebSocket is connected (SUB sync path).
  bool get hasActiveSocket => _channel != null;

  bool get _enabled {
    final url = _settings.hubWsUrl;
    return _settings.isHubSub && url != null && url.isNotEmpty;
  }

  /// Start background reconnect loop when SUB mode + hub URL are configured.
  Future<void> startIfEnabled() async {
    // #region agent log
    agentDebugLog(
      hypothesisId: 'H2',
      location: 'local_hub_sync_coordinator.dart:startIfEnabled',
      message: 'sub_coordinator_start_check',
      data: <String, Object?>{
        'isHubSub': _settings.isHubSub,
        'hubWsUrlLen': _settings.hubWsUrl?.length ?? 0,
        'enabled': _enabled,
      },
    );
    // #endregion
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

  /// After changing hub URL or SUB role in [LocalHubSettings], reconnect (or idle) cleanly.
  Future<void> reconnectFromSettings() async {
    stop();
    for (var i = 0; i < 40 && _loopRunning; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    await startIfEnabled();
  }

  /// Wi‑Fi restore / app resume / watchdog — skip long backoff and reconnect now.
  void requestFastReconnect() {
    if (!_enabled) {
      unawaited(startIfEnabled());
      return;
    }
    _fastReconnectRequested = true;
    _backoffSec = 0;
    unawaited(_channel?.sink.close());
    unawaited(startIfEnabled());
  }

  /// Full envelope JSON is queued with `PENDING` until MAIN `ACK`.
  Future<String?> enqueueOutbound(String type, Map<String, dynamic> payload) async {
    if (!_enabled) return null;
    await _settings.resolveOrAllocateDeviceId(_uuid.v4);
    final id = _uuid.v4();
    await _db.syncQueueDao.insertOutbox(
      SyncOutboxCompanion.insert(
        id: id,
        eventType: type,
        payload: jsonEncode(payload),
      ),
    );
    await _tryFlushOutbox();
    return id;
  }

  Future<void> _connectionLoop() async {
    while (!_stopDesired) {
      if (!_enabled) {
        await Future<void>.delayed(const Duration(seconds: 2));
        continue;
      }

      await _waitBeforeReconnect();
      if (_stopDesired) break;

      try {
        final uri = Uri.parse(_settings.hubWsUrl!);
        final ch = WebSocketChannel.connect(uri);
        _channel = ch;
        _backoffSec = 0;
        detachWebSocketSinkDone(ch);
        // #region agent log
        agentDebugLog(
          hypothesisId: 'H2',
          location: 'local_hub_sync_coordinator.dart:_connectionLoop',
          message: 'sub_ws_socket_connected',
          data: <String, Object?>{
            'host': uri.host,
            'port': uri.port,
            'path': uri.path,
          },
        );
        // #endregion

        await _handshakeAndFlush(ch);

        await for (final raw in ch.stream) {
          if (_stopDesired) break;
          try {
            final s = _stringFromDynamic(raw);
            await _onRawMessage(s);
          } catch (e, st) {
            if (kDebugMode) {
              debugPrint('[LocalHub] inbound message handler: $e\n$st');
            }
          }
        }
      } catch (e, st) {
        if (kDebugMode) debugPrint('[LocalHub] socket error: $e\n$st');
        _backoffSec = _backoffSec <= 0 ? 1 : (_backoffSec * 2).clamp(1, 120);
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

  Future<void> _waitBeforeReconnect() async {
    if (_backoffSec <= 0) return;
    final slices = _backoffSec * 2;
    for (var i = 0; i < slices; i++) {
      if (_stopDesired) return;
      if (_fastReconnectRequested) {
        _fastReconnectRequested = false;
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  String _stringFromDynamic(dynamic raw) {
    if (raw is String) return raw;
    return utf8.decode(raw as List<int>);
  }

  Future<void> _handshakeAndFlush(WebSocketChannel ch) async {
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final deviceId = _settings.requireDeviceId();
    final connect = PosSyncEnvelope(
      eventId: _uuid.v4(),
      type: PosSyncEventTypes.connect,
      payload: const <String, dynamic>{
        'clientRole': 'SUB_CLIENT',
        'appMode': 'hub_sub',
      },
      timestamp: ts,
      deviceId: deviceId,
    );
    ch.sink.add(connect.encode());

    final syncReq = PosSyncEnvelope(
      eventId: _uuid.v4(),
      type: PosSyncEventTypes.syncRequest,
      payload: <String, dynamic>{'lastSyncTimestamp': _settings.lastJournalMs},
      timestamp: ts,
      deviceId: deviceId,
    );
    ch.sink.add(syncReq.encode());
    // #region agent log
    agentDebugLog(
      hypothesisId: 'H5',
      location: 'local_hub_sync_coordinator.dart:_handshakeAndFlush',
      message: 'sub_sync_request_sent',
      data: <String, Object?>{
        'lastJournalMs': _settings.lastJournalMs,
      },
    );
    // #endregion

    await _flushOutboxOver(ch);
  }

  Future<void> _tryFlushOutbox() async {
    final ch = _channel;
    if (ch == null) return;
    await _flushOutboxOver(ch);
  }

  Future<int> retryUnsyncedNow() async {
    if (!_enabled) return 0;
    final ready = await _ensureConnectedForRetry();
    if (!ready) return 0;
    final ch = _channel;
    if (ch == null) return 0;
    try {
      return await _flushOutboxOver(ch);
    } catch (_) {
      return 0;
    }
  }

  /// Best-effort wait for an active socket so manual Retry works right after Wi-Fi reconnect.
  Future<bool> _ensureConnectedForRetry({Duration timeout = const Duration(seconds: 5)}) async {
    await startIfEnabled();
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      if (_channel != null) return true;
      if (_stopDesired || !_enabled) return false;
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    return _channel != null;
  }

  Future<int> _flushOutboxOver(WebSocketChannel ch) async {
    final now = DateTime.now();
    final rows = await _db.syncQueueDao.outboxWorkQueue(now);
    var ackedNow = 0;
    for (final r in rows) {
      if (_stopDesired) break;
      Map<String, dynamic> payload;
      try {
        final decoded = jsonDecode(r.payload);
        payload = Map<String, dynamic>.from(decoded as Map);
      } catch (_) {
        await _db.syncQueueDao.patchOutbox(
          r.id,
          SyncOutboxCompanion(
            status: const Value('FAILED'),
            retryCount: Value(r.retryCount + 1),
            nextRetryAfter: Value(now.add(Duration(seconds: _nextBackoffSec(r.retryCount + 1)))),
          ),
        );
        continue;
      }

      final env = PosSyncEnvelope(
        eventId: r.id,
        type: r.eventType,
        payload: payload,
        timestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        deviceId: _settings.requireDeviceId(),
      );

      try {
        ch.sink.add(env.encode());
        await _db.syncQueueDao.patchOutbox(r.id, const SyncOutboxCompanion(status: Value('SENT')));
        ackedNow++;
      } catch (_) {
        await _db.syncQueueDao.patchOutbox(
          r.id,
          SyncOutboxCompanion(
            status: const Value('FAILED'),
            retryCount: Value(r.retryCount + 1),
            nextRetryAfter: Value(now.add(Duration(seconds: _nextBackoffSec(r.retryCount + 1)))),
          ),
        );
      }
    }
    return ackedNow;
  }

  int _nextBackoffSec(int retryCount) => (1 << retryCount.clamp(0, 8)).clamp(1, 120);

  Future<void> _onRawMessage(String raw) async {
    if (raw.trim().isEmpty) return;

    if (raw.startsWith('{') && raw.contains('"error"')) {
      try {
        final map = jsonDecode(raw);
        if (map is Map && map['error'] != null && kDebugMode) {
          debugPrint('[LocalHub] server error: ${map['error']} ${map['detail'] ?? ''}');
        }
      } catch (_) {
        /* ignore */
      }
      return;
    }

    final env = PosSyncEnvelope.tryDecode(raw);
    if (env == null) return;

    if (env.type == PosSyncEventTypes.ack) {
      await _onAck(env.payload);
      return;
    }

    if (env.type == PosSyncEventTypes.syncResponse) {
      await _ingestSyncResponse(env);
      return;
    }

    if (env.type == PosSyncEventTypes.connect) {
      return;
    }

    // #region agent log
    agentDebugLog(
      hypothesisId: 'H3',
      location: 'local_hub_sync_coordinator.dart:_onRawMessage',
      message: 'sub_inbound_envelope',
      data: <String, Object?>{
        'type': env.type,
        'eventIdLen': env.eventId.length,
      },
    );
    // #endregion

    await _persistInboxAndApply(env, raw);
    final st = payloadTimestampMs(env.payload, fallbackSec: env.timestamp);
    await _maybeAdvanceWatermark(st);
    if (env.type == PosSyncEventTypes.dayClosingSettled) {
      _dayClosingLive?.notifyDayClosingChanged();
    } else {
      _ordersLive.notifyHubOrdersChanged();
    }
    await HubInboundSerialDispatcher.yieldToUi();
  }

  int payloadTimestampMs(Map<String, dynamic> p, {required int fallbackSec}) {
    final u = p['updatedAt'];
    if (u is num) return u.toInt();
    return fallbackSec * 1000;
  }

  Future<void> _maybeAdvanceWatermark(int candidateMs) async {
    final cur = _settings.lastJournalMs;
    if (candidateMs > cur) await _settings.saveLastJournalMs(candidateMs);
  }

  Future<void> _ingestSyncResponse(PosSyncEnvelope env) async {
    final p = env.payload;

    final list = p['events'];
    if (list is! List<dynamic>) {
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H5',
        location: 'local_hub_sync_coordinator.dart:_ingestSyncResponse',
        message: 'sync_response_missing_events_list',
        data: const <String, Object?>{},
      );
      // #endregion
      return;
    }

    final types = <String>[];
    for (final item in list) {
      if (item is Map) {
        final envMap = item['envelope'];
        if (envMap is Map && envMap['type'] != null) {
          types.add(envMap['type'].toString());
        }
      }
    }
    // #region agent log
    agentDebugLog(
      hypothesisId: 'H5',
      location: 'local_hub_sync_coordinator.dart:_ingestSyncResponse',
      message: 'sync_response_ingest_start',
      data: <String, Object?>{
        'eventCount': list.length,
        'types': types.join(','),
        'syncTimestamp': p['syncTimestamp'],
      },
    );
    // #endregion

    var dayClosingTouched = false;
    for (final item in list) {
      final inner = PosSyncJournalReplay.envelopeFromItem(item);
      if (inner == null) continue;
      final effMs = PosSyncJournalReplay.watermarkMs(item, inner);
      final encoded = inner.encode();
      await _persistInboxAndApply(inner, encoded);
      await _maybeAdvanceWatermark(effMs);
      if (inner.type == PosSyncEventTypes.dayClosingSettled) {
        dayClosingTouched = true;
      }
      await HubInboundSerialDispatcher.yieldToUi();
    }

    if (dayClosingTouched) {
      _dayClosingLive?.notifyDayClosingChanged();
    } else {
      _ordersLive.notifyHubOrdersChanged();
    }
  }

  Future<void> _persistInboxAndApply(PosSyncEnvelope env, String raw) async {
    final existing = await _db.syncQueueDao.inboxRowByEventId(env.eventId);
    if (existing != null) {
      if (existing.applied) return;
      try {
        await _applier.apply(existing.id, env, env.payload);
        await _db.syncQueueDao.markInboxApplied(existing.id);
      } catch (_) {
        /* keep applied=false; next replay retries */
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
    } catch (_) {
      /* Leave applied=false for crash recovery inspection; optional retry hooks later */
    }
  }

  Future<void> _onAck(Map<String, dynamic> payload) async {
    final forId = payload['forEventId']?.toString();
    final ok = payload['ok'] == true;
    if (forId == null || forId.isEmpty) return;

    final row = await _db.syncQueueDao.outboxRowById(forId);
    if (row == null) return;

    final now = DateTime.now();

    if (ok || payload['duplicate'] == true) {
      await _db.syncQueueDao.patchOutbox(
        forId,
        const SyncOutboxCompanion(
          status: Value('ACKED'),
          nextRetryAfter: Value(null),
        ),
      );
      await _tryFlushOutbox();
      return;
    }

    await _db.syncQueueDao.patchOutbox(
      forId,
      SyncOutboxCompanion(
        status: const Value('FAILED'),
        retryCount: Value(row.retryCount + 1),
        nextRetryAfter: Value(now.add(Duration(seconds: _nextBackoffSec(row.retryCount + 1)))),
      ),
    );
  }
}
