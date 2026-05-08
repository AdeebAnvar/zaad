import 'package:pos/domain/models/pagination_model.dart';

class FloorsModel {
  final List<FloorsCreatedUpdated> createdUpdated;
  final List<dynamic> deleted;
  final PaginationModel pagination;

  FloorsModel({
    required this.createdUpdated,
    required this.deleted,
    required this.pagination,
  });

  FloorsModel copyWith({
    List<FloorsCreatedUpdated>? createdUpdated,
    List<dynamic>? deleted,
    PaginationModel? pagination,
  }) =>
      FloorsModel(
        createdUpdated: createdUpdated ?? this.createdUpdated,
        deleted: deleted ?? this.deleted,
        pagination: pagination ?? this.pagination,
      );

  factory FloorsModel.fromJson(Map<String, dynamic> json) => FloorsModel(
        createdUpdated: (json["created_updated"] as List?)
                ?.map((x) => FloorsCreatedUpdated.fromJson(Map<String, dynamic>.from(x as Map)))
                .toList() ??
            const [],
        deleted: List<dynamic>.from(json["deleted"] as List? ?? const []),
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

class FloorsCreatedUpdated {
  final int id;
  final String uuid;
  final int branchId;
  final String? floorName;
  final String? floorSlug;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic deletedAt;
  final String? paymentMethodName;
  final String? paymentMethodSlug;
  final String? unitName;
  final String? unitSlug;

  FloorsCreatedUpdated({
    required this.id,
    required this.uuid,
    required this.branchId,
    this.floorName,
    this.floorSlug,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    this.paymentMethodName,
    this.paymentMethodSlug,
    this.unitName,
    this.unitSlug,
  });

  FloorsCreatedUpdated copyWith({
    int? id,
    String? uuid,
    int? branchId,
    String? floorName,
    String? floorSlug,
    DateTime? createdAt,
    DateTime? updatedAt,
    dynamic deletedAt,
    String? paymentMethodName,
    String? paymentMethodSlug,
    String? unitName,
    String? unitSlug,
  }) =>
      FloorsCreatedUpdated(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        branchId: branchId ?? this.branchId,
        floorName: floorName ?? this.floorName,
        floorSlug: floorSlug ?? this.floorSlug,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        paymentMethodName: paymentMethodName ?? this.paymentMethodName,
        paymentMethodSlug: paymentMethodSlug ?? this.paymentMethodSlug,
        unitName: unitName ?? this.unitName,
        unitSlug: unitSlug ?? this.unitSlug,
      );

  factory FloorsCreatedUpdated.fromJson(Map<String, dynamic> json) => FloorsCreatedUpdated(
        id: (json["id"] as num?)?.toInt() ?? 0,
        uuid: json["uuid"]?.toString() ?? '',
        branchId: (json["branch_id"] as num?)?.toInt() ?? 0,
        floorName: json["floor_name"]?.toString(),
        floorSlug: json["floor_slug"]?.toString(),
        createdAt:
            DateTime.tryParse(json["created_at"]?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt:
            DateTime.tryParse(json["updated_at"]?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        deletedAt: json["deleted_at"],
        paymentMethodName: json["payment_method_name"]?.toString(),
        paymentMethodSlug: json["payment_method_slug"]?.toString(),
        unitName: json["unit_name"]?.toString(),
        unitSlug: json["unit_slug"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "uuid": uuid,
        "branch_id": branchId,
        "floor_name": floorName,
        "floor_slug": floorSlug,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
        "payment_method_name": paymentMethodName,
        "payment_method_slug": paymentMethodSlug,
        "unit_name": unitName,
        "unit_slug": unitSlug,
      };
}
