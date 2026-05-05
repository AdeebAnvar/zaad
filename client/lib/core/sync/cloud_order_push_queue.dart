import 'dart:convert';

import 'package:get_it/get_it.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/core/sync/outbound_push_coordinator.dart';

/// Ensures [`OrderLog`] has an unsynced JSON snapshot matching [`push_records`] mappings.
///
/// Uses **resurrection**: once a sale was synced, later edits (payments, status) reset the row
/// to `synced=false` so [OutboundPushCoordinator] uploads again from **Primary**.
Future<void> enqueueOrderLogSnapshotForCloudPush({
  required AppDatabase db,
  required Order order,
  required Map<String, dynamic> snapshotPayload,
}) async {
  if (GetIt.instance.isRegistered<LocalHubSettings>() &&
      GetIt.instance<LocalHubSettings>().blocksTenantCloudRest) {
    return;
  }

  final merged = Map<String, dynamic>.from(snapshotPayload)
    ..['order_id'] = order.id
    ..['cart_id'] = order.cartId;

  final jsonStr = jsonEncode(merged);

  final pending = await db.ordersDao.findUnsyncedLogByLocalOrderId(order.id);
  if (pending != null) {
    await db.ordersDao.updateOrderLogPayload(pending.id, jsonStr);
  } else {
    final latest = await db.ordersDao.findLatestOrderLogByLocalOrderId(order.id);
    if (latest != null) {
      await db.ordersDao.updateOrderLogPayload(latest.id, jsonStr);
      await db.ordersDao.setOrderLogsSyncedState(<int>[latest.id], synced: false);
    } else {
      await db.ordersDao.insertOrderLog(jsonStr);
    }
  }
  scheduleOutboundPushAfterLocalOrder();
}
