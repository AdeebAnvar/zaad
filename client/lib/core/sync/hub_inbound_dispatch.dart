import 'dart:async';

import 'package:flutter/foundation.dart';

/// Serializes hub WebSocket inbound work so messages are not applied in parallel
/// (parallel apply spikes RAM and freezes the UI on mobile).
class HubInboundSerialDispatcher {
  Future<void> _tail = Future<void>.value();

  /// Enqueue [work]; each job runs after the previous finishes, then yields one frame.
  void dispatch(Future<void> Function() work) {
    _tail = _tail.then((_) async {
      try {
        await work();
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('[HubInbound] handler error: $e\n$st');
        }
      }
      await Future<void>.delayed(Duration.zero);
    });
  }

  /// Between journal replay events — keeps UI responsive on home / sale screens.
  static Future<void> yieldToUi() => Future<void>.delayed(Duration.zero);
}
