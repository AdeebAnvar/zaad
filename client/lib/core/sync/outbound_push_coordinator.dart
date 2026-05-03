import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pos/core/config/pos_app_runtime_config.dart';
import 'package:pos/core/utils/network_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/push_records_repository.dart';

/// Triggers [PushRecordsRepository.pushSalesAndCreditSalesFromLocal] when online
/// — after each local sale/KOT order log, and when the network comes back.
class OutboundPushCoordinator {
  OutboundPushCoordinator(this._push, this._db, this._runtime);

  final PushRecordsRepository _push;
  final AppDatabase _db;
  final PosAppRuntimeConfig _runtime;

  StreamSubscription<ConnectivityResult>? _connectivitySub;
  Timer? _debounce;
  bool _flushInProgress = false;

  void ensureListening() {
    _connectivitySub ??= NetworkUtils.connectivityStream.listen((_) {
      scheduleFlush();
    });
  }

  void dispose() {
    _debounce?.cancel();
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  /// Coalesces bursts (multiple KOT lines, rapid sales, connectivity flaps).
  void scheduleFlush() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(flushPendingIfOnline());
    });
  }

  Future<void> flushPendingIfOnline() async {
    // Sub devices never flush to tenant APIs from Flutter. Hub host may use Local POS + CLOUD_SYNC_VIA_NODE.
    if (_runtime.isLanSatellite) return;
    if (_flushInProgress) return;
    final session = await _db.sessionDao.getActiveSession();
    if (session == null) return;
    if (!await NetworkUtils.hasInternetConnection()) return;
    _flushInProgress = true;
    try {
      final out = await _push.pushSalesAndCreditSalesFromLocal();
      if (kDebugMode) {
        debugPrint(
          '[OutboundPush] ok=${out.ok} http=${out.httpStatus} posted=${out.ordersPosted} creditRows=${out.creditRowsPosted}',
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
  final rt = g.isRegistered<PosAppRuntimeConfig>() ? g<PosAppRuntimeConfig>() : null;
  if (rt != null && rt.isLanSatellite) {
    return;
  }
  try {
    g<OutboundPushCoordinator>().scheduleFlush();
  } catch (_) {}
}
