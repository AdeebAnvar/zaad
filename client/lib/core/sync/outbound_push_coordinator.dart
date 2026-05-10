import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/utils/network_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/push_records_repository.dart';

/// Triggers [PushRecordsRepository.pushSalesAndCreditSalesFromLocal] when online
/// — after each local sale/KOT order log, and when the network comes back.
class OutboundPushCoordinator {
  OutboundPushCoordinator(this._push, this._db);

  final PushRecordsRepository _push;
  final AppDatabase _db;

  StreamSubscription<ConnectivityResult>? _connectivitySub;
  Timer? _debounce;
  bool _flushInProgress = false;
  bool _maintenancePaused = false;

  /// Pauses scheduled + connectivity-triggered flushes (used by [UpdaterManager] teardown).
  void suspendForMaintenance() {
    _maintenancePaused = true;
    _debounce?.cancel();
    _debounce = null;
  }

  void resumeAfterMaintenance() {
    _maintenancePaused = false;
  }

  /// Hot path for updater / maintenance: defer shutdown until cloud push completes.
  bool get isFlushWorkInFlight => _flushInProgress;

  void ensureListening() {
    _connectivitySub ??= NetworkUtils.connectivityStream.listen((_) {
      if (!_maintenancePaused) {
        scheduleFlush();
      }
    });
  }

  void dispose() {
    _debounce?.cancel();
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  /// Coalesces bursts (multiple KOT lines, rapid sales, connectivity flaps).
  void scheduleFlush() {
    if (_maintenancePaused) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(flushPendingIfOnline());
    });
  }

  Future<void> flushPendingIfOnline() async {
    if (_maintenancePaused) return;
    if (_flushInProgress) return;
    final g = GetIt.instance;
    if (g.isRegistered<LocalHubSettings>() && g<LocalHubSettings>().blocksTenantCloudRest) {
      return;
    }
    final session = await _db.sessionDao.getActiveSession();
    if (session == null) return;
    if (!await NetworkUtils.hasInternetConnection()) return;
    _flushInProgress = true;
    try {
      final out = await _push.pushSalesAndCreditSalesFromLocal();
      if (kDebugMode) {
        debugPrint(
          '[OutboundPush] ok=${out.ok} http=${out.httpStatus} posted=${out.ordersPosted} creditRows=${out.creditRowsPosted} settleRows=${out.settleRowsPosted}',
        );
      }
    } catch (e, st) {
      debugPrint('[OutboundPush] error: $e\n$st');
    } finally {
      _flushInProgress = false;
    }
  }
}

/// Call after a new [OrderLog] row is written (e.g. [OrderRepository.createOrder]).
void scheduleOutboundPushAfterLocalOrder() {
  final g = GetIt.instance;
  if (!g.isRegistered<OutboundPushCoordinator>()) return;
  if (g.isRegistered<LocalHubSettings>() && g<LocalHubSettings>().blocksTenantCloudRest) {
    return;
  }
  try {
    g<OutboundPushCoordinator>().scheduleFlush();
  } catch (_) {}
}
