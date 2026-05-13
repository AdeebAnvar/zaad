import 'dart:convert';

import 'package:pos/data/local/drift_database.dart';

/// Parse dine-in reference strings and build `floorId|TABLE | N pax` refs (aligned with Dine In floor plan).
///
/// The leading `floorId|` segment is **storage routing** (same table code on different floors).
/// Staff-facing labels should use [stripLeadingFloorId] so e.g. `1|T3 | 2 pax` shows as `T3 | 2 pax`.
class DineInRefParser {
  DineInRefParser._();

  static String tableKey(String code) => code.trim().toUpperCase();

  static int? extractLeadingFloorId(String? referenceNumber) {
    final v = (referenceNumber ?? '').trim();
    final m = RegExp(r'^(\d+)\|(.+)$').firstMatch(v);
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }

  static String stripLeadingFloorId(String? referenceNumber) {
    final v = (referenceNumber ?? '').trim();
    final m = RegExp(r'^(\d+)\|(.+)$').firstMatch(v);
    if (m != null) return m.group(2)!.trim();
    return v;
  }

  static String extractTableCode(String? referenceNumber) {
    final v = stripLeadingFloorId(referenceNumber);
    if (v.isEmpty) return '';
    if (v.contains('|')) {
      return v.split('|').first.trim().toUpperCase();
    }
    return v.toUpperCase();
  }

  static int extractPaxFromReference(String? referenceNumber) {
    final v = stripLeadingFloorId(referenceNumber);
    if (v.isEmpty || !v.contains('|')) return 1;
    final after = v.split('|').skip(1).join('|').trim();
    final paxM = RegExp(r'(\d+)\s*pax', caseSensitive: false).firstMatch(after);
    if (paxM != null) return int.tryParse(paxM.group(1)!) ?? 1;
    final m = RegExp(r'(\d+)').firstMatch(after);
    if (m == null) return 1;
    return int.tryParse(m.group(1)!) ?? 1;
  }

  static String buildReference(int floorId, String tableCode, int pax) => '$floorId|$tableCode | $pax pax';

  /// Floor + table only (no pax). Used when seat handling is off: multiple orders per table without chair allocation.
  static String buildTableOnlyReference(int floorId, String tableCode) => '$floorId|${tableCode.trim()}';

  static const String hubMetadataAnchorKey = 'dine_in_anchor';

  /// Table/floor routing stored in [Order.hubMetadata] when the user leaves [Order.referenceNumber] empty.
  static String? dineInAnchorFromHubMetadata(String? hubMetadata) {
    try {
      if (hubMetadata == null || hubMetadata.trim().isEmpty) return null;
      final root = jsonDecode(hubMetadata);
      if (root is! Map) return null;
      final a = root[hubMetadataAnchorKey];
      if (a is String && a.trim().isNotEmpty) return a.trim();
    } catch (_) {}
    return null;
  }

  static String mergeHubMetadataAnchor(String? hubMetadata, String newAnchor) {
    final a = newAnchor.trim();
    if (a.isEmpty) return hubMetadata ?? '';
    try {
      Map<String, dynamic> map;
      if (hubMetadata != null && hubMetadata.trim().isNotEmpty) {
        final p = jsonDecode(hubMetadata);
        map = p is Map ? Map<String, dynamic>.from(p) : <String, dynamic>{};
      } else {
        map = <String, dynamic>{};
      }
      map[hubMetadataAnchorKey] = a;
      return jsonEncode(map);
    } catch (_) {
      return jsonEncode({hubMetadataAnchorKey: a});
    }
  }

  /// Floor-plan matching: explicit `referenceNumber`, else `hubMetadata.dine_in_anchor`, else legacy rows
  /// where the table routing lived only in `referenceNumber`.
  static String? dineInAnchorForMatching(Order o) {
    final r = o.referenceNumber?.trim();
    if (r != null && r.isNotEmpty) return r;
    final fromHub = dineInAnchorFromHubMetadata(o.hubMetadata);
    if (fromHub != null && fromHub.isNotEmpty) return fromHub;
    return null;
  }

  /// Whether [o] is assigned to [floorId] + [tableCodeUpper] (same rules as floor plan).
  static bool orderMatchesFloorTable(
    Order o,
    int floorId,
    String tableCodeUpper,
    Map<String, Set<int>> tableCodeToFloorIds,
  ) {
    final ref = dineInAnchorForMatching(o);
    if (ref == null || ref.isEmpty) return false;
    final leadFloor = extractLeadingFloorId(ref);
    final normalized = stripLeadingFloorId(ref);
    final code = tableKey(extractTableCode(normalized));
    if (code != tableCodeUpper) return false;
    if (leadFloor != null) return leadFloor == floorId;
    final floorsForCode = tableCodeToFloorIds[code];
    return floorsForCode != null && floorsForCode.length == 1 && floorsForCode.first == floorId;
  }

  /// Sum of pax from other active dine-in orders on that table (excluding [excludeOrderId]).
  static Future<int> occupiedPaxOnTableExcluding({
    required int floorId,
    required String tableCodeUpper,
    required int excludeOrderId,
    required AppDatabase db,
    required List<Order> activeDineInOrders,
  }) async {
    final allTables = await db.diningTablesDao.getAllDiningTables();
    final codeToFloors = <String, Set<int>>{};
    for (final t in allTables) {
      codeToFloors.putIfAbsent(tableKey(t.code), () => {}).add(t.floorId);
    }

    var sum = 0;
    for (final o in activeDineInOrders) {
      if (o.id == excludeOrderId) continue;
      if (!orderMatchesFloorTable(o, floorId, tableCodeUpper, codeToFloors)) continue;
      sum += extractPaxFromReference(dineInAnchorForMatching(o));
    }
    return sum;
  }
}
