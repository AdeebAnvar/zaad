import 'package:flutter/foundation.dart';

/// Lightweight [revision] notifier so order-backed UIs can trigger a Drift reload.
/// Coalesces only same-tick bursts without adding visible delay.
class HubOrdersLiveSync {
  HubOrdersLiveSync();

  final ValueNotifier<int> revision = ValueNotifier<int>(0);
  bool _queued = false;

  void notifyHubOrdersChanged() {
    if (_queued) return;
    _queued = true;
    Future<void>.microtask(() {
      _queued = false;
      revision.value = revision.value + 1;
    });
  }
}
