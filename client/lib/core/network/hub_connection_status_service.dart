import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pos/core/config/pos_app_runtime_config.dart';
import 'package:pos/core/network/base_url_resolver.dart';
import 'package:pos/core/network/pos_server_settings.dart';
import 'package:pos/core/network/websocket_service.dart';

/// UI-facing hub reachability for LOCAL installs (HTTP health + WebSocket).
enum HubConnectionUiStatus {
  online,
  offline,
  syncing,
}

class HubConnectionStatusService extends ChangeNotifier {
  HubConnectionStatusService({
    required PosAppRuntimeConfig runtime,
    required PosServerSettings settings,
    required HubWebSocketService ws,
    required BaseUrlResolver resolver,
  })  : _runtime = runtime,
        _settings = settings,
        _ws = ws,
        _resolver = resolver {
    _ws.connection.addListener(_onWsChanged);
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => unawaited(_pingHealth()));
    unawaited(_pingHealth());
  }

  final PosAppRuntimeConfig _runtime;
  final PosServerSettings _settings;
  final HubWebSocketService _ws;
  final BaseUrlResolver _resolver;

  Timer? _timer;
  bool _lastPingOk = false;
  DateTime _lastPingAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _workerSyncing = false;

  bool get _eligible =>
      _runtime.isLocal && (_settings.hubRoot ?? '').trim().isNotEmpty;

  HubConnectionUiStatus get status {
    if (!_eligible) return HubConnectionUiStatus.online;
    if (_workerSyncing) return HubConnectionUiStatus.syncing;
    if (_ws.connection.value == PosHubConnectionState.connected) {
      return HubConnectionUiStatus.online;
    }
    final fresh = DateTime.now().difference(_lastPingAt) < const Duration(seconds: 14);
    if (_lastPingOk && fresh) return HubConnectionUiStatus.online;
    return HubConnectionUiStatus.offline;
  }

  bool get shouldRunOutboundWorker =>
      _eligible &&
      (_ws.connection.value == PosHubConnectionState.connected ||
          (_lastPingOk &&
              DateTime.now().difference(_lastPingAt) < const Duration(seconds: 14)));

  void setWorkerSyncing(bool value) {
    if (!_eligible) return;
    if (_workerSyncing == value) return;
    _workerSyncing = value;
    notifyListeners();
  }

  void _onWsChanged() {
    if (_eligible) notifyListeners();
  }

  Future<void> _pingHealth() async {
    if (!_eligible) {
      _lastPingOk = false;
      return;
    }
    final base = _settings.hubRoot;
    if (base == null || base.isEmpty) {
      _lastPingOk = false;
      return;
    }
    try {
      final ok = await _resolver.healthOk(base);
      _lastPingOk = ok;
      _lastPingAt = DateTime.now();
      if (_eligible) notifyListeners();
    } catch (_) {
      _lastPingOk = false;
      _lastPingAt = DateTime.now();
      if (_eligible) notifyListeners();
    }
  }

  /// After reconnect, refresh hub projection (best-effort).
  Future<void> notifyOnlineReconcile() async {
    if (!_eligible) return;
    await _pingHealth();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ws.connection.removeListener(_onWsChanged);
    super.dispose();
  }
}
