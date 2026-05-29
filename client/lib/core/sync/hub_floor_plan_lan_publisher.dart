import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pos/core/network/lan_hub_health.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/sync/hub_order_lan_publisher.dart';
import 'package:pos/core/sync/pos_sync_wire.dart';
import 'package:pos/data/local/drift_database.dart';

/// After MAIN tenant pull, mirror dine-in floors/tables to SUB so both show the same layout.
class HubFloorPlanLanPublisher {
  HubFloorPlanLanPublisher._();

  static Future<void> publishForActiveBranch(AppDatabase db) async {
    final g = GetIt.instance;
    if (!g.isRegistered<LocalHubSettings>()) return;
    final hub = g<LocalHubSettings>();
    if (hub.blocksTenantCloudRest) return;
    if (hub.publishHubWsUrlOrLoopback.isEmpty) return;
    if (await LanHubReachability.resolvePublishWsUrl(hub) == null) return;

    final session = await db.sessionDao.getActiveSession();
    final branchId = session?.branchId ?? 1;

    final floors = await db.diningTablesDao.getFloorsForBranch(branchId);
    final tables = await db.diningTablesDao.getAllDiningTablesForBranch(branchId);

    final payload = <String, dynamic>{
      'branchId': branchId,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
      'floors': floors
          .map(
            (f) => <String, dynamic>{
              'id': f.id,
              'name': f.name,
              'sort_order': f.sortOrder,
              'branch_id': f.branchId,
              'record_uuid': f.recordUuid,
              'floor_slug': f.floorSlug,
            },
          )
          .toList(),
      'tables': tables
          .map(
            (t) => <String, dynamic>{
              'id': t.id,
              'floor_id': t.floorId,
              'code': t.code,
              'chairs': t.chairs,
              'status': t.status,
              'branch_id': t.branchId,
              'record_uuid': t.recordUuid,
              'table_name': t.pulledTableName,
              'table_slug': t.pulledTableSlug,
              'order_count': t.orderCount,
            },
          )
          .toList(),
    };

    await HubOrderLanPublisher.enqueueMainEventWithQueue(
      type: PosSyncEventTypes.floorPlanSnapshot,
      payload: payload,
      awaitFlush: false,
    );

    if (kDebugMode) {
      debugPrint(
        '[HubFloorPlanLanPublisher] queued floor plan branch=$branchId '
        'floors=${floors.length} tables=${tables.length}',
      );
    }
  }
}
