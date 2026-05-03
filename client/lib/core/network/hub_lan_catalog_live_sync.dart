import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pos/core/config/pos_app_runtime_config.dart';
import 'package:pos/core/network/pos_api_service.dart';
import 'package:pos/data/repository/pull_data_repository.dart';

/// When the LAN hub WebSocket reports `ITEMS_UPDATED` / `DATA_SYNCED`, re-pull the
/// mirror into Drift (debounced) and bump [catalogRevision] so UIs can refresh.
class HubLanCatalogLiveSync {
  HubLanCatalogLiveSync(
    this._runtime,
    this._pull,
    this._hubApi,
  );

  final PosAppRuntimeConfig _runtime;
  final PullDataRepository _pull;
  final PosApiService _hubApi;

  static const int _debounceMs = 2000;

  final ValueNotifier<int> catalogRevision = ValueNotifier<int>(0);

  Timer? _debounce;
  bool _busy = false;

  /// Call after [PullDataRepository.hydrateCatalogFromLanHub] succeeds so sale UIs refetch items.
  void notifyCatalogApplied() {
    catalogRevision.value = catalogRevision.value + 1;
  }

  /// Called from [HubWebSocketService] when the hub signals catalog / mirror changes.
  void onHubMasterDataSignal(String eventType) {
    if (!_runtime.isLocal) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      unawaited(_hydrate(eventType));
    });
  }

  Future<void> _hydrate(String reason) async {
    if (_busy) return;
    _busy = true;
    try {
      final r = await _pull.hydrateCatalogFromLanHub(_hubApi);
      if (r.ok) {
        if (kDebugMode) {
          debugPrint('[hub_live] catalog mirror applied ($reason) → rev ${catalogRevision.value}');
        }
      } else if (kDebugMode) {
        debugPrint('[hub_live] catalog hydrate skipped/failed ($reason): ${r.message}');
      }
    } finally {
      _busy = false;
    }
  }
}
