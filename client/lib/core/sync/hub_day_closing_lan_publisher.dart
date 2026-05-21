import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/sync/hub_order_lan_publisher.dart';
import 'package:pos/core/sync/local_hub_sync_coordinator.dart';
import 'package:pos/core/sync/pos_sync_wire.dart';

/// Broadcasts branch day-closing checkpoint to all LAN hub peers (MAIN ⇄ SUB).
class HubDayClosingLanPublisher {
  HubDayClosingLanPublisher._();

  static void scheduleBranchSettled({
    required int branchId,
    required DateTime settledAt,
  }) {
    if (branchId <= 0) return;

    Future.microtask(() async {
      final hub = _eligibleHubOrNull();
      if (hub == null) return;

      final payload = <String, dynamic>{
        'branchId': branchId,
        'lastSettledAt': settledAt.toIso8601String(),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      try {
        if (hub.isHubSub) {
          final g = GetIt.instance;
          if (!g.isRegistered<LocalHubSyncCoordinator>()) return;
          await g<LocalHubSyncCoordinator>().enqueueOutbound(
            PosSyncEventTypes.dayClosingSettled,
            payload,
          );
        } else {
          await HubOrderLanPublisher.enqueueMainEventWithQueue(
            type: PosSyncEventTypes.dayClosingSettled,
            payload: payload,
          );
        }
        if (kDebugMode) {
          debugPrint(
            '[HubDayClosingLanPublisher] queued DAY_CLOSING_SETTLED branch=$branchId at=${settledAt.toIso8601String()}',
          );
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[HubDayClosingLanPublisher] publish failed: $e');
        }
      }
    });
  }

  static LocalHubSettings? _eligibleHubOrNull() {
    try {
      final g = GetIt.instance;
      if (!g.isRegistered<LocalHubSettings>()) return null;
      final hub = g<LocalHubSettings>();
      if (hub.publishHubWsUrlOrLoopback.isEmpty) return null;
      return hub;
    } catch (_) {
      return null;
    }
  }
}
