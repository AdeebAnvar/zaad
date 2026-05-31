import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Assign once per order row (v4). Never derive from invoice or local row id.
String generateSalePushUuid() => _uuid.v4();

/// Reads a previously assigned uuid from an order-log / hub snapshot.
String? readSalePushUuidFromSnap(Map<String, dynamic> snap) {
  final v = snap['sale_push_uuid']?.toString().trim();
  return (v != null && v.isNotEmpty) ? v : null;
}

/// Credit row uuid derived from the sale uuid (stable while sale uuid is stable).
String deterministicCreditPushUuid(String saleUuid) =>
    _uuid.v5('6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'pos_credit|$saleUuid');

int orderIdFromSnap(Map<String, dynamic> snap) {
  final oidRaw = snap['order_id'];
  if (oidRaw is int) return oidRaw;
  return int.tryParse(oidRaw?.toString() ?? '') ?? 0;
}
