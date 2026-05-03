import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:pos/core/config/pos_app_runtime_config.dart';
import 'package:pos/core/network/hub_connection_status_service.dart';
import 'package:pos/core/network/pos_api_service.dart';
import 'package:pos/core/network/pos_server_settings.dart';
import 'package:pos/core/network/websocket_service.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/features/orders/data/hub_orders_sync.dart';
import 'package:pos/features/orders/data/local_hub_pending_queue.dart';
import 'package:pos/core/utils/network_utils.dart';

/// Flushes [pending_actions] to the LAN hub when connectivity allows.
class OfflineHubSyncWorker {
  OfflineHubSyncWorker({
    required AppDatabase db,
    required LocalHubPendingQueue queue,
    required PosApiService hubApi,
    required HubOrdersSync hubSync,
    required HubConnectionStatusService connection,
    required PosAppRuntimeConfig runtime,
    required HubWebSocketService ws,
    required PosServerSettings settings,
  })  : _db = db,
        _queue = queue,
        _hubApi = hubApi,
        _hubSync = hubSync,
        _connection = connection,
        _runtime = runtime,
        _ws = ws,
        _settings = settings;

  static const int _maxRetries = 25;

  final AppDatabase _db;
  final LocalHubPendingQueue _queue;
  final PosApiService _hubApi;
  final HubOrdersSync _hubSync;
  final HubConnectionStatusService _connection;
  final PosAppRuntimeConfig _runtime;
  final HubWebSocketService _ws;
  final PosServerSettings _settings;

  Timer? _timer;
  StreamSubscription<ConnectivityResult>? _connectivitySub;
  bool _tickRunning = false;

  bool get _eligible =>
      _runtime.isLocal && (_settings.hubRoot ?? '').trim().isNotEmpty;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) => unawaited(_tickSafe()));
  }

  /// Wi‑Fi / mobile data changes — retry hub queue immediately (not only on the 12s timer).
  void ensureConnectivityListener() {
    _connectivitySub ??= NetworkUtils.connectivityStream.listen((_) {
      unawaited(_onConnectivityBounce());
    });
  }

  Future<void> _onConnectivityBounce() async {
    if (!_eligible) return;
    await _connection.notifyOnlineReconcile();
    if (!_connection.shouldRunOutboundWorker) return;

    final failed = await _db.pendingActionsDao.countFailed();
    if (failed > 0) {
      await _db.pendingActionsDao.resetFailedToPending();
      if (kDebugMode) {
        debugPrint('[offline_hub_worker] re-queued $failed FAILED LAN hub actions after connectivity change');
      }
    }

    await _tickSafe();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  Future<void> _tickSafe() async {
    if (!_eligible || _tickRunning) return;
    _tickRunning = true;
    try {
      await _tick();
    } finally {
      _tickRunning = false;
    }
  }

  Future<void> _tick() async {
    await _connection.notifyOnlineReconcile();

    if (!_connection.shouldRunOutboundWorker) {
      return;
    }

    final rows = await _db.pendingActionsDao.pendingReady(DateTime.now());
    if (rows.isEmpty) return;

    _connection.setWorkerSyncing(true);
    try {
      for (final row in rows) {
        if (!_connection.shouldRunOutboundWorker) break;
        try {
          await _processRow(row);
        } catch (e, st) {
          debugPrint('[offline_hub_worker] row ${row.id} failed: $e\n$st');
          await _failRow(row, e.toString());
        }
      }

      if (_connection.shouldRunOutboundWorker) {
        await _ws.hydrateCacheIfConfigured();
      }
    } finally {
      _connection.setWorkerSyncing(false);
    }
  }

  Future<void> _failRow(PendingAction row, String message) async {
    final next = row.retryCount + 1;
    if (next >= _maxRetries) {
      await _queue.markFailed(row.id);
      debugPrint('[offline_hub_worker] FAILED permanently ${row.id} ($message)');
      return;
    }
    final backoffSec = math.min(120, 2 * math.pow(2, math.min(next, 6)).toInt());
    await _queue.bumpRetry(
      row.id,
      next,
      DateTime.now().add(Duration(seconds: backoffSec)),
    );
  }

  Future<void> _processRow(PendingAction row) async {
    final decoded = jsonDecode(row.payload);
    if (decoded is! Map<String, dynamic>) {
      await _queue.markFailed(row.id);
      return;
    }

    switch (row.type) {
      case 'CREATE_ORDER':
        await _syncCreate(row.id, decoded);
        break;
      case 'UPDATE_ORDER':
        await _syncUpdate(row, decoded);
        break;
      case 'DELETE_ORDER':
        await _syncDelete(row.id, decoded);
        break;
      default:
        await _queue.markFailed(row.id);
    }
  }

  Future<void> _syncCreate(String actionId, Map<String, dynamic> payload) async {
    final localId = payload['local_order_id'] as int?;
    final hubBody = payload['hub_body'];
    if (localId == null || hubBody is! Map<String, dynamic>) {
      await _queue.markFailed(actionId);
      return;
    }

    final res = await _hubApi.createOrder(hubBody);
    await _hubSync.applyHubEnvelopeMergeLocal(localOrderId: localId, body: res);
    await _db.pendingActionsDao.deleteById(actionId);
  }

  Future<void> _syncUpdate(PendingAction row, Map<String, dynamic> payload) async {
    final localId = payload['local_order_id'] as int?;
    final patchBody = payload['patch_body'];
    if (localId == null || patchBody is! Map<String, dynamic>) {
      await _queue.markFailed(row.id);
      return;
    }

    final orderRow = await _db.ordersDao.getOrderById(localId);
    var sid = (payload['server_order_id'] as String?)?.trim();
    sid = (sid == null || sid.isEmpty) ? orderRow?.serverOrderId?.trim() : sid;
    if (sid == null || sid.isEmpty) {
      await _failRow(row, 'no server_order_id');
      return;
    }

    final envelope = await _hubApi.patchOrder(serverOrderId: sid, body: patchBody);
    await _hubSync.applyHubEnvelope(envelope);
    await _db.pendingActionsDao.deleteById(row.id);
  }

  Future<void> _syncDelete(String actionId, Map<String, dynamic> payload) async {
    final sid = (payload['server_order_id'] as String?)?.trim();
    if (sid == null || sid.isEmpty) {
      await _queue.markFailed(actionId);
      return;
    }
    await _hubApi.deleteOrderByServerId(sid);
    await _db.pendingActionsDao.deleteById(actionId);
  }
}
