import 'package:pos/domain/models/pagination_model.dart';

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
      );

  factory OfferCreatedUpdated.fromJson(Map<String, dynamic> json) => OfferCreatedUpdated(
        id: (json["id"] as num?)?.toInt() ?? 0,
        uuid: json["uuid"]?.toString() ?? '',
        branchId: (json["branch_id"] as num?)?.toInt() ?? 0,
        promocode: json["promocode"]?.toString() ?? '',
        fromDate: json["from_date"]?.toString() ?? '',
        toDate: json["to_date"]?.toString() ?? '',
        value: json["value"]?.toString() ?? '',
        type: json["type"]?.toString() ?? '',
        active: (json["active"] as num?)?.toInt() ?? 0,
        createdAt:
            DateTime.tryParse(json["created_at"]?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt:
            DateTime.tryParse(json["updated_at"]?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        deletedAt: json["deleted_at"],
        offerName: json["offer_name"]?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "uuid": uuid,
        "branch_id": branchId,
        "promocode": promocode,
        "from_date": fromDate,
        "to_date": toDate,
        "value": value,
        "type": type,
        "active": active,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
        "offer_name": offerName,
      };
}
