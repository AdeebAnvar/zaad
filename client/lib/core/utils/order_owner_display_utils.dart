import 'dart:convert';

import 'package:pos/data/local/drift_database.dart';

/// Displays who created/placed an order on order log screens.
///
/// Hub-mirrored rows may carry [Order.hubMetadata] (wrapper JSON); the nested
/// `snapshot` may include `cashier_name` from the originating terminal.
Future<String?> resolveOrderOwnerDisplayName({
  required AppDatabase db,
  required Order order,
  required Future<int?> Function() currentSessionUserId,
}) async {
  final metaName = cashierNameFromHubMetadata(order.hubMetadata);
  if (metaName != null && metaName.isNotEmpty) return metaName;

  final uid = order.userId;
  if (uid != null) {
    final u = await db.usersDao.findUserById(uid);
    final n = u?.name.trim() ?? '';
    if (n.isNotEmpty) return n;
  }

  // Legacy local rows (no hub mirror): treat missing user as current session.
  if (order.serverOrderId == null || order.serverOrderId!.trim().isEmpty) {
    final sid = await currentSessionUserId();
    if (sid != null) {
      final u = await db.usersDao.findUserById(sid);
      final n = u?.name.trim() ?? '';
      if (n.isNotEmpty) return n;
    }
  }

  return null;
}

/// Reads `snapshot.cashier_name` from hub order mirror JSON (see [SyncInboxApplier]).
String? cashierNameFromHubMetadata(String? hubMetadataJson) {
  if (hubMetadataJson == null || hubMetadataJson.isEmpty) return null;
  try {
    final root = jsonDecode(hubMetadataJson);
    if (root is! Map<String, dynamic>) return null;
    final snap = root['snapshot'];
    if (snap is! Map<String, dynamic>) return null;
    final n = snap['cashier_name']?.toString().trim() ?? '';
    return n.isEmpty ? null : n;
  } catch (_) {
    return null;
  }
}

int? coerceUserId(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw.toString());
}
