import 'package:pos/domain/models/pagination_model.dart';

/// Local-time weekday + optional clock window for synced offers.
///
/// [days] uses lowercased English keys (`monday` … `sunday`). When [startTime] and [offerHours]
/// are set, the offer is active only in `[start, start + offerHours)` on each matching calendar day
/// (e.g. Monday 10:00 + 24h → through Tuesday 09:59:59.999).
class OfferSchedule {
  OfferSchedule._();

  static const _weekdayKeys = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];

  /// ISO weekday: 1 = Monday … 7 = Sunday ([DateTime.weekday]).
  static String weekdayKey(DateTime d) => _weekdayKeys[d.weekday - 1];

  static double? coerceOfferHours(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) {
      final d = raw.toDouble();
      return d > 0 ? d : null;
    }
    final d = double.tryParse(raw.toString().trim());
    if (d == null || d <= 0) return null;
    return d;
  }

  /// Parses `HH:mm:ss`, `HH:mm`, or `HH` (24h clock).
  static ({int hour, int minute, int second})? parseStartTime(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final parts = t.split(':');
    if (parts.isEmpty) return null;
    final h = int.tryParse(parts[0].trim());
    if (h == null || h < 0 || h > 23) return null;
    final m = parts.length > 1 ? int.tryParse(parts[1].trim()) ?? 0 : 0;
    if (m < 0 || m > 59) return null;
    var secPart = parts.length > 2 ? parts[2].trim() : '0';
    secPart = secPart.split('.').first;
    final s = int.tryParse(secPart) ?? 0;
    if (s < 0 || s > 59) return null;
    return (hour: h, minute: m, second: s);
  }

  /// Without a time window: [days] empty → always `true` (manual dropdown); else today must match a day.
  /// With a time window: each matching calendar day in a small look-back window is checked for `[start, end)`.
  static bool isActiveAt(
    DateTime now, {
    required List<String> days,
    String? startTime,
    double? offerHours,
  }) {
    final st = startTime?.trim();
    final hours = offerHours;
    final hasWindow = st != null && st.isNotEmpty && hours != null && hours > 0;
    if (!hasWindow) {
      if (days.isEmpty) return true;
      return days.contains(weekdayKey(now));
    }
    final clock = parseStartTime(st);
    if (clock == null) {
      if (days.isEmpty) return true;
      return days.contains(weekdayKey(now));
    }
    final duration = Duration(seconds: (hours * 3600).round());
    final today0 = DateTime(now.year, now.month, now.day);
    for (var delta = -8; delta <= 1; delta++) {
      final d = today0.add(Duration(days: delta));
      final key = weekdayKey(d);
      if (days.isNotEmpty && !days.contains(key)) continue;
      final start = DateTime(d.year, d.month, d.day, clock.hour, clock.minute, clock.second);
      final end = start.add(duration);
      if (!now.isBefore(start) && now.isBefore(end)) return true;
    }
    return false;
  }
}

class OfferModel {
  final List<OfferCreatedUpdated> createdUpdated;
  final List<int> deleted;
  final PaginationModel pagination;

  OfferModel({
    required this.createdUpdated,
    required this.deleted,
    required this.pagination,
  });

  OfferModel copyWith({
    List<OfferCreatedUpdated>? createdUpdated,
    List<int>? deleted,
    PaginationModel? pagination,
  }) =>
      OfferModel(
        createdUpdated: createdUpdated ?? this.createdUpdated,
        deleted: deleted ?? this.deleted,
        pagination: pagination ?? this.pagination,
      );

  factory OfferModel.fromJson(Map<String, dynamic> json) => OfferModel(
        createdUpdated: (json["created_updated"] as List?)
                ?.map((x) => OfferCreatedUpdated.fromJson(Map<String, dynamic>.from(x as Map)))
                .toList() ??
            const [],
        deleted: (json["deleted"] as List?)?.map((x) => (x as num).toInt()).toList() ?? const [],
        pagination: json["pagination"] is Map
            ? PaginationModel.fromJson(Map<String, dynamic>.from(json["pagination"] as Map))
            : PaginationModel.fallback(),
      );

  Map<String, dynamic> toJson() => {
        "created_updated": List<dynamic>.from(createdUpdated.map((x) => x.toJson())),
        "deleted": List<dynamic>.from(deleted.map((x) => x)),
        "pagination": pagination.toJson(),
      };
}

class OfferCreatedUpdated {
  final int id;
  final String uuid;
  final int branchId;
  /// Legacy sync field; new API may omit.
  final String promocode;
  final String fromDate;
  final String toDate;
  final String value;
  final String type;
  final int active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic deletedAt;
  final String offerName;
  final List<int> itemIds;
  final List<int> categoryIds;
  /// 1 = all items; 0 = restricted to [itemIds] and/or [categoryIds].
  final int isAllItems;
  /// Lowercased weekday names, e.g. `monday`. Empty = eligible for manual dropdown (no day gate).
  final List<String> days;
  /// Local start clock, e.g. `10:00:00`. With [offerHours] gates auto-day availability.
  final String? startTime;
  /// Duration length in hours (may be fractional). End = start + offerHours on each matching day.
  final double? offerHours;

  OfferCreatedUpdated({
    required this.id,
    required this.uuid,
    required this.branchId,
    required this.promocode,
    required this.fromDate,
    required this.toDate,
    required this.value,
    required this.type,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.offerName,
    required this.itemIds,
    required this.categoryIds,
    required this.isAllItems,
    required this.days,
    this.startTime,
    this.offerHours,
  });

  OfferCreatedUpdated copyWith({
    int? id,
    String? uuid,
    int? branchId,
    String? promocode,
    String? fromDate,
    String? toDate,
    String? value,
    String? type,
    int? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    dynamic deletedAt,
    String? offerName,
    List<int>? itemIds,
    List<int>? categoryIds,
    int? isAllItems,
    List<String>? days,
    String? startTime,
    double? offerHours,
  }) =>
      OfferCreatedUpdated(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        branchId: branchId ?? this.branchId,
        promocode: promocode ?? this.promocode,
        fromDate: fromDate ?? this.fromDate,
        toDate: toDate ?? this.toDate,
        value: value ?? this.value,
        type: type ?? this.type,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        offerName: offerName ?? this.offerName,
        itemIds: itemIds ?? this.itemIds,
        categoryIds: categoryIds ?? this.categoryIds,
        isAllItems: isAllItems ?? this.isAllItems,
        days: days ?? this.days,
        startTime: startTime ?? this.startTime,
        offerHours: offerHours ?? this.offerHours,
      );

  static List<int> _intList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is num) return [raw.toInt()];
    final single = int.tryParse(raw.toString().trim());
    if (raw is! List && single != null) return [single];
    if (raw is! List) return const [];
    final out = <int>[];
    for (final e in raw) {
      if (e is num) {
        out.add(e.toInt());
      } else {
        final parsed = int.tryParse(e.toString().trim());
        if (parsed != null) out.add(parsed);
      }
    }
    return out;
  }

  static List<String> _dayList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString().toLowerCase().trim()).where((s) => s.isNotEmpty).toList();
  }

  /// API may send `active` or `is_active` (0/1, bool, or string).
  static int _coerceActiveFlag(Map<String, dynamic> json) {
    final v = json['active'] ?? json['is_active'];
    if (v == null) return 0;
    if (v is bool) return v ? 1 : 0;
    if (v is num) return v.toInt() != 0 ? 1 : 0;
    final s = v.toString().trim().toLowerCase();
    if (s == '1' || s == 'true' || s == 'yes' || s == 'active') return 1;
    return 0;
  }

  factory OfferCreatedUpdated.fromJson(Map<String, dynamic> json) => OfferCreatedUpdated(
        id: (json["id"] as num?)?.toInt() ?? 0,
        uuid: json["uuid"]?.toString() ?? '',
        branchId: (json["branch_id"] as num?)?.toInt() ?? 0,
        promocode: json["promocode"]?.toString() ?? '',
        fromDate: json["from_date"]?.toString() ?? '',
        toDate: json["to_date"]?.toString() ?? '',
        value: json["value"]?.toString() ?? '',
        type: json["type"]?.toString() ?? '',
        active: _coerceActiveFlag(json),
        createdAt:
            DateTime.tryParse(json["created_at"]?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt:
            DateTime.tryParse(json["updated_at"]?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        deletedAt: json["deleted_at"],
        offerName: json["offer_name"]?.toString() ?? '',
        itemIds: _intList(json["item_id"]),
        categoryIds: _intList(json["category_id"]),
        isAllItems: (json["is_all_items"] as num?)?.toInt() ?? 0,
        days: _dayList(json["day"] ?? json["days"]),
        startTime: _nullableTrimmed(json["start_time"]),
        offerHours: OfferSchedule.coerceOfferHours(json["offer_hour"]),
      );

  static String? _nullableTrimmed(dynamic v) {
    final s = v?.toString().trim();
    if (s == null || s.isEmpty) return null;
    return s;
  }

  Map<String, dynamic> toJson() {
    final st = startTime;
    final oh = offerHours;
    return {
      "id": id,
      "uuid": uuid,
      "branch_id": branchId,
      "promocode": promocode,
      "from_date": fromDate,
      "to_date": toDate,
      "value": value,
      "type": type,
      "active": active,
      "is_active": active,
      "created_at": createdAt.toIso8601String(),
      "updated_at": updatedAt.toIso8601String(),
      "deleted_at": deletedAt,
      "offer_name": offerName,
      "item_id": List<int>.from(itemIds),
      "category_id": List<int>.from(categoryIds),
      "is_all_items": isAllItems,
      "day": List<String>.from(days),
      if (st != null && st.trim().isNotEmpty) "start_time": st,
      if (oh != null && oh > 0) "offer_hour": oh,
    };
  }
}
