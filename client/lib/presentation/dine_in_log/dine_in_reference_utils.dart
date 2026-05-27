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
      final map = Map<String, dynamic>.from(root);

      final direct = map[hubMetadataAnchorKey];
      if (direct is String && direct.trim().isNotEmpty) return direct.trim();

      final snap = map['snapshot'];
      if (snap is Map) {
        final fromSnap = _anchorFromMap(Map<String, dynamic>.from(snap));
        if (fromSnap != null) return fromSnap;
      }

      final meta = map['metadata'];
      if (meta is Map) {
        final flutter = meta['flutter'];
        if (flutter is Map) {
          final fromFlutter = _anchorFromMap(Map<String, dynamic>.from(flutter));
          if (fromFlutter != null) return fromFlutter;
        }
      }
    } catch (_) {}
    return null;
  }

  static String? _anchorFromMap(Map<String, dynamic> map) {
    final a = map[hubMetadataAnchorKey];
    if (a is String && a.trim().isNotEmpty) return a.trim();
    final ref = map['reference_number']?.toString().trim() ?? '';
    if (ref.isNotEmpty && extractLeadingFloorId(ref) != null) return ref;
    return null;
  }

  /// Floor/table routing from a LAN order snapshot (top-level flutter spread or metadata.flutter).
  static String? routingAnchorFromLanSnapshot(
    Map<String, dynamic> snap, [
    Map<String, dynamic>? flutterSnap,
  ]) {
    final fromSnap = _anchorFromMap(snap);
    if (fromSnap != null) return fromSnap;
    if (flutterSnap != null) {
      return _anchorFromMap(flutterSnap);
    }
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

  /// Staff KOT label and/or table routing for log cards (prefers visible staff ref).
  static String? dineInAnchorForMatching(Order o) {
    final r = o.referenceNumber?.trim();
    if (r != null && r.isNotEmpty) return r;
    final fromHub = dineInAnchorFromHubMetadata(o.hubMetadata);
    if (fromHub != null && fromHub.isNotEmpty) return fromHub;
    return null;
  }

  /// Floor/table routing only — ignores plain staff KOT text like `ead` on [Order.referenceNumber].
  static String? dineInRoutingAnchorForMatching(Order o) {
    final fromHub = dineInAnchorFromHubMetadata(o.hubMetadata);
    if (fromHub != null && fromHub.isNotEmpty) return fromHub;
    final r = o.referenceNumber?.trim();
    if (r != null && r.isNotEmpty && extractLeadingFloorId(r) != null) return r;
    return null;
  }

  /// Whether [o] is assigned to [floorId] + [tableCodeUpper] (same rules as floor plan).
  static bool orderMatchesFloorTable(
    Order o,
    int floorId,
    String tableCodeUpper,
    Map<String, Set<int>> tableCodeToFloorIds,
  ) {
    final ref = dineInRoutingAnchorForMatching(o);
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
    required int branchId,
  }) async {
    final allTables = await db.diningTablesDao.getAllDiningTablesForBranch(branchId);
    final codeToFloors = <String, Set<int>>{};
    for (final t in allTables) {
      codeToFloors.putIfAbsent(tableKey(t.code), () => {}).add(t.floorId);
    }

    var sum = 0;
    for (final o in activeDineInOrders) {
      if (o.id == excludeOrderId) continue;
      if (!orderMatchesFloorTable(o, floorId, tableCodeUpper, codeToFloors)) continue;
      sum += extractPaxFromReference(dineInRoutingAnchorForMatching(o));
    }
    return sum;
  }
}
