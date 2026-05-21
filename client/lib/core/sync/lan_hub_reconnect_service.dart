import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/sync/local_hub_primary_inbound_coordinator.dart';
import 'package:pos/core/sync/local_hub_sync_coordinator.dart';
import 'package:pos/core/utils/network_utils.dart';

/// Keeps LAN hub WebSockets alive without asking staff to restart the app.
///
/// - Retries immediately when Wi‑Fi/LAN returns
/// - Re-handshakes when the app returns from background
/// - Periodic watchdog if a coordinator lost its socket while hub settings are valid
class LanHubReconnectService with WidgetsBindingObserver {
  LanHubReconnectService(this._settings);

  final LocalHubSettings _settings;

  StreamSubscription<ConnectivityResult>? _connectivitySub;
  Timer? _watchdog;
  bool _started = false;
  bool _kickInFlight = false;

  void ensureStarted() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _connectivitySub = NetworkUtils.connectivityStream.listen(_onConnectivity);
    _watchdog = Timer.periodic(const Duration(seconds: 45), (_) => unawaited(_watchdogTick()));
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_connectivitySub?.cancel());
    _connectivitySub = null;
    _watchdog?.cancel();
    _watchdog = null;
    _started = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(kickReconnectNow(reason: 'app_resumed'));
    }
  }

  void _onConnectivity(ConnectivityResult result) {
    if (result != ConnectivityResult.none) {
      unawaited(kickReconnectNow(reason: 'connectivity_restored'));
    }
  }

  Future<void> _watchdogTick() async {
    final g = GetIt.instance;
    if (!g.isRegistered<LocalHubSyncCoordinator>() ||
        !g.isRegistered<LocalHubPrimaryInboundCoordinator>()) {
      return;
    }

    final sub = g<LocalHubSyncCoordinator>();
    final main = g<LocalHubPrimaryInboundCoordinator>();

    final subNeedsSocket = _settings.isHubSub &&
        (_settings.hubWsUrl?.trim().isNotEmpty ?? false) &&
        !sub.hasActiveSocket;
    final mainNeedsSocket =
        !_settings.blocksTenantCloudRest && _settings.publishHubWsUrlOrLoopback.trim().isNotEmpty && !main.hasActiveSocket;

    if (subNeedsSocket || mainNeedsSocket) {
      await kickReconnectNow(reason: 'watchdog');
    }
  }

  /// Interrupt backoff sleeps and reopen hub sockets (safe to call often).
  Future<void> kickReconnectNow({String reason = 'manual'}) async {
    if (_kickInFlight) return;
    _kickInFlight = true;
    try {
      final g = GetIt.instance;
      if (g.isRegistered<LocalHubSyncCoordinator>()) {
        g<LocalHubSyncCoordinator>().requestFastReconnect();
      }
      if (g.isRegistered<LocalHubPrimaryInboundCoordinator>()) {
        g<LocalHubPrimaryInboundCoordinator>().requestFastReconnect();
      }
      if (kDebugMode) {
        debugPrint('[LanHubReconnect] kick ($reason)');
      }
    } finally {
      _kickInFlight = false;
    }
  }
}
