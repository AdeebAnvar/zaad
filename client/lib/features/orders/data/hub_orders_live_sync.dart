import 'dart:async';

import 'package:flutter/foundation.dart';

/// Coalesces LAN hub order-cache changes (WebSocket `NEW_ORDER` / `ORDER_*` / `ORDER_DELETED`,
/// and post-`hydrateCacheIfConfigured`) so order-backed UIs can reload from Drift.
///
/// [revision] bumps are **debounced** to avoid list thrash when many WS events arrive at once.
class HubOrdersLiveSync {
  HubOrdersLiveSync();

  final ValueNotifier<int> revision = ValueNotifier<int>(0);
  Timer? _debounce;
  static const int _debounceMs = 400;

  void notifyHubOrdersChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      revision.value = revision.value + 1;
    });
  }
}
