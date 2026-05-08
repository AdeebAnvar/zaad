import 'package:pos/domain/models/pagination_model.dart';

class KitchensModel {
  final List<KitchensCreatedUpdated> createdUpdated;
  final List<dynamic> deleted;
  final PaginationModel pagination;

  KitchensModel({
    required this.createdUpdated,
    required this.deleted,
    required this.pagination,
  });

  KitchensModel copyWith({
    List<KitchensCreatedUpdated>? createdUpdated,
    List<dynamic>? deleted,
    PaginationModel? pagination,
  }) =>
      KitchensModel(
        createdUpdated: createdUpdated ?? this.createdUpdated,
        deleted: deleted ?? this.deleted,
        pagination: pagination ?? this.pagination,
      );

  factory KitchensModel.fromJson(Map<String, dynamic> json) => KitchensModel(
        createdUpdated: (json["created_updated"] as List?)
                ?.map((x) => KitchensCreatedUpdated.fromJson(Map<String, dynamic>.from(x as Map)))
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

class KitchensCreatedUpdated {
  final int id;
  final String uuid;
  final int branchId;
  final String kitchenName;
  final String printerDetails;
  final String printerType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic deletedAt;

  KitchensCreatedUpdated({
    required this.id,
    required this.uuid,
    required this.branchId,
    required this.kitchenName,
    required this.printerDetails,
    required this.printerType,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  KitchensCreatedUpdated copyWith({
    int? id,
    String? uuid,
    int? branchId,
    String? kitchenName,
    String? printerDetails,
    String? printerType,
    DateTime? createdAt,
    DateTime? updatedAt,
    dynamic deletedAt,
  }) =>
      KitchensCreatedUpdated(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        branchId: branchId ?? this.branchId,
        kitchenName: kitchenName ?? this.kitchenName,
        printerDetails: printerDetails ?? this.printerDetails,
        printerType: printerType ?? this.printerType,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  factory KitchensCreatedUpdated.fromJson(Map<String, dynamic> json) => KitchensCreatedUpdated(
        id: (json["id"] as num?)?.toInt() ?? 0,
        uuid: json["uuid"]?.toString() ?? '',
        branchId: (json["branch_id"] as num?)?.toInt() ?? 0,
        kitchenName: json["kitchen_name"]?.toString() ?? '',
        printerDetails: json["printer_details"]?.toString() ?? '',
        printerType: json["printer_type"]?.toString() ?? '',
        createdAt:
            DateTime.tryParse(json["created_at"]?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt:
            DateTime.tryParse(json["updated_at"]?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        deletedAt: json["deleted_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "uuid": uuid,
        "branch_id": branchId,
        "kitchen_name": kitchenName,
        "printer_details": printerDetails,
        "printer_type": printerType,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
      };
}
