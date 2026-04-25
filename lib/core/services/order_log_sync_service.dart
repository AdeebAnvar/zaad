import 'dart:convert';

import 'package:pos/core/utils/network_utils.dart';
import 'package:pos/data/local/drift_database.dart';

typedef OrderLogUploadFn = Future<bool> Function(List<Map<String, dynamic>> logs);

class OrderLogSyncService {
  OrderLogSyncService(this._uploadFn);

  final OrderLogUploadFn _uploadFn;

  Future<int> syncUnsyncedOrderLogs(AppDatabase db) async {
    final hasConnection = await NetworkUtils.hasInternetConnection();
    if (!hasConnection) return 0;

    final logs = await db.ordersDao.getUnsyncedOrderLogs();
    if (logs.isEmpty) return 0;

    final payload = logs
        .map((l) => {
              'id': l.id,
              'created_at': l.createdAt.toIso8601String(),
              'order': jsonDecode(l.orderJson),
            })
        .toList();

    final ok = await _uploadFn(payload);
    if (!ok) return 0;

    await db.ordersDao.markOrderLogsSynced(logs.map((e) => e.id).toList());
    return logs.length;
  }
}

