import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:uuid/uuid.dart';

/// Durably queues LAN hub writes when offline (LOCAL mode).
class LocalHubPendingQueue {
  LocalHubPendingQueue(this._db);

  final AppDatabase _db;

  /// Same id is stored in offline order [hubMetadata] `pending_action_id`.
  Future<String> enqueueCreateOrder({
    required int localOrderId,
    required Map<String, dynamic> hubBody,
    String? actionId,
  }) async {
    final id = actionId ?? const Uuid().v4();
    await _db.pendingActionsDao.insertRow(
      PendingActionsCompanion.insert(
        id: id,
        type: 'CREATE_ORDER',
        payload: jsonEncode({
          'local_order_id': localOrderId,
          'hub_body': hubBody,
        }),
      ),
    );
    return id;
  }

  Future<String> enqueueUpdateOrder({
    required int localOrderId,
    required String? serverOrderId,
    required Map<String, dynamic> patchBody,
  }) async {
    final id = const Uuid().v4();
    await _db.pendingActionsDao.insertRow(
      PendingActionsCompanion.insert(
        id: id,
        type: 'UPDATE_ORDER',
        payload: jsonEncode({
          'local_order_id': localOrderId,
          'server_order_id': serverOrderId,
          'patch_body': patchBody,
        }),
      ),
    );
    return id;
  }

  Future<String> enqueueDeleteOrder({
    required int localOrderId,
    required String serverOrderId,
  }) async {
    final id = const Uuid().v4();
    await _db.pendingActionsDao.insertRow(
      PendingActionsCompanion.insert(
        id: id,
        type: 'DELETE_ORDER',
        payload: jsonEncode({
          'local_order_id': localOrderId,
          'server_order_id': serverOrderId,
        }),
      ),
    );
    return id;
  }

  Future<void> replacePendingCreatePayload({
    required int localOrderId,
    required Map<String, dynamic> hubBody,
  }) async {
    final row =
        await _db.pendingActionsDao.findPendingCreateForLocalOrder(localOrderId);
    if (row == null) return;
    await _db.pendingActionsDao.updateRow(
      row.id,
      PendingActionsCompanion(
        payload: Value(jsonEncode({
          'local_order_id': localOrderId,
          'hub_body': hubBody,
        })),
      ),
    );
  }

  Future<void> markSynced(String id) async {
    await _db.pendingActionsDao.updateRow(
      id,
      const PendingActionsCompanion(status: Value('SYNCED')),
    );
  }

  Future<void> markFailed(String id) async {
    await _db.pendingActionsDao.updateRow(
      id,
      const PendingActionsCompanion(status: Value('FAILED')),
    );
  }

  Future<void> bumpRetry(String id, int retryCount, DateTime? nextRetryAfter) async {
    await _db.pendingActionsDao.updateRow(
      id,
      PendingActionsCompanion(
        retryCount: Value(retryCount),
        nextRetryAfter: Value(nextRetryAfter),
      ),
    );
  }

  Future<void> cancelPendingCreate(int localOrderId) async {
    final row =
        await _db.pendingActionsDao.findPendingCreateForLocalOrder(localOrderId);
    if (row == null) return;
    await _db.pendingActionsDao.deleteById(row.id);
  }
}
