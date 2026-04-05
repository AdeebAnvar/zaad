import 'package:pos/data/local/drift_database.dart';

/// Parse dine-in reference strings and build `floorId|TABLE | N pax` refs (aligned with Dine In floor plan).
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

  /// Whether [o] is assigned to [floorId] + [tableCodeUpper] (same rules as floor plan).
  static bool orderMatchesFloorTable(
    Order o,
    int floorId,
    String tableCodeUpper,
    Map<String, Set<int>> tableCodeToFloorIds,
  ) {
    final ref = o.referenceNumber;
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
      sum += extractPaxFromReference(o.referenceNumber);
    }
    return sum;
  }
}
