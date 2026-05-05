import 'dart:async';

import 'package:flutter/foundation.dart';

/// Debounced [revision] notifier so order-backed UIs can trigger a Drift reload together.
/// (Reserved for future realtime; no WebSocket wiring in cloud-only builds.)
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
