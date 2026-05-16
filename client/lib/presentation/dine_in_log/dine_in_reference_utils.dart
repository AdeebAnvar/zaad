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

  static String buildReference(int floorId, String tableCode, int pax, {List<int>? seatIndices}) {
    final code = tableCode.trim();
    final base = '$floorId|$code | $pax pax';
    if (seatIndices == null || seatIndices.isEmpty) return base;
    final unique = seatIndices.where((i) => i > 0).toSet().toList()..sort();
    if (unique.isEmpty) return base;
    return '$base | seats: ${unique.join(',')}';
  }

  /// Floor + table only (no pax). Used when seat handling is off: multiple orders per table without chair allocation.
  static String buildTableOnlyReference(int floorId, String tableCode) => '$floorId|${tableCode.trim()}';

  static final RegExp _seatsTrailerRe = RegExp(r'\|\s*seats?\s*:\s*([\d,\s]+)', caseSensitive: false);

  /// Explicit 1-based seat numbers from ref trailer (`| seats: 1,3`), else `null` (legacy pax-only rows).
  static List<int>? extractSeatIndicesFromReference(String? referenceNumber) {
    final v = stripLeadingFloorId(referenceNumber).trim();
    if (v.isEmpty) return null;
    final m = _seatsTrailerRe.firstMatch(v);
    if (m == null) return null;
    final raw = m.group(1) ?? '';
    final out = <int>[];
    for (final part in raw.split(',')) {
      final n = int.tryParse(part.trim());
      if (n != null && n > 0) out.add(n);
    }
    return out.isEmpty ? null : out;
  }

  /// `floorId|TABLE` identity for merge / same-table rules (ignores pax & seats).
  static String? routingBaseKey(String? anchor) {
    final ref = (anchor ?? '').trim();
    if (ref.isEmpty) return null;
    final floor = extractLeadingFloorId(ref);
    final code = tableKey(extractTableCode(ref));
    if (code.isEmpty) return null;
    if (floor != null) return '$floor|$code';
    return code;
  }

  static bool sameTableRouting(String? a, String? b) {
    final ka = routingBaseKey(a);
    final kb = routingBaseKey(b);
    if (ka == null || kb == null) return false;
    return ka == kb;
  }

  /// Blocked 1-based seats: explicit `seats:` from refs, then legacy pax-only orders fill lowest free seats in [id] order.
  static Set<int> computeBlockedSeatsForTable({
    required int chairCapacity,
    required Iterable<Order> ordersOnTable,
    int? excludeOrderId,
  }) {
    if (chairCapacity <= 0) return {};
    final explicitTaken = <int>{};
    final legacyOrders = <Order>[];
    for (final o in ordersOnTable) {
      if (excludeOrderId != null && o.id == excludeOrderId) continue;
      final anchor = dineInAnchorForMatching(o);
      if (anchor == null || anchor.isEmpty) continue;
      final seats = extractSeatIndicesFromReference(anchor);
      if (seats != null && seats.isNotEmpty) {
        for (final s in seats) {
          if (s >= 1 && s <= chairCapacity) explicitTaken.add(s);
        }
      } else {
        legacyOrders.add(o);
      }
    }
    legacyOrders.sort((a, b) => a.id.compareTo(b.id));
    final blocked = Set<int>.from(explicitTaken);
    for (final o in legacyOrders) {
      final anchor = dineInAnchorForMatching(o)!;
      var pax = extractPaxFromReference(anchor);
      if (pax < 1) pax = 1;
      pax = pax.clamp(1, chairCapacity);
      var filled = 0;
      var seat = 1;
      while (filled < pax && seat <= chairCapacity) {
        if (!blocked.contains(seat)) {
          blocked.add(seat);
          filled++;
        }
        seat++;
      }
    }
    return blocked;
  }

  static const String hubMetadataAnchorKey = 'dine_in_anchor';

  /// Table/floor routing is stored in [Order.hubMetadata] under [hubMetadataAnchorKey].
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

  /// Floor/table/seat routing: **`hubMetadata.dine_in_anchor` first**, then legacy `referenceNumber`.
  static String? dineInAnchorForMatching(Order o) {
    final fromHub = dineInAnchorFromHubMetadata(o.hubMetadata);
    if (fromHub != null && fromHub.isNotEmpty) return fromHub;
    final r = o.referenceNumber?.trim();
    if (r != null && r.isNotEmpty) return r;
    return null;
  }

  /// KOT / ticket line: dine-in uses table anchor only; other channels use `referenceNumber` or invoice.
  static String printableRoutingLabel(Order? o) {
    if (o == null) return '';
    final ot = (o.orderType ?? '').trim().toLowerCase();
    if (ot == 'dine_in') {
      final a = dineInAnchorForMatching(o);
      if (a != null && a.isNotEmpty) return stripLeadingFloorId(a);
      return o.invoiceNumber;
    }
    final r = o.referenceNumber?.trim();
    if (r != null && r.isNotEmpty) return r;
    return o.invoiceNumber;
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
