import 'package:flutter/foundation.dart';
import 'package:pos/core/debug/agent_debug_log.dart';

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
      final next = revision.value + 1;
      revision.value = next;
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H4',
        location: 'hub_orders_live_sync.dart:notifyHubOrdersChanged',
        message: 'hub_orders_revision_bump',
        data: <String, Object?>{'revision': next},
      );
      // #endregion
    });
  }
}
