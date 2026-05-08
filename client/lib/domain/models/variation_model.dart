import 'package:pos/core/constants/enums.dart';
import 'package:pos/domain/models/pagination_model.dart';

class VariationOptionsModel {
  final List<VariationOptionsCreatedUpdated> createdUpdated;
  final List<dynamic> deleted;
  final PaginationModel pagination;

  VariationOptionsModel({
    required this.createdUpdated,
    required this.deleted,
    required this.pagination,
  });

  VariationOptionsModel copyWith({
    List<VariationOptionsCreatedUpdated>? createdUpdated,
    List<dynamic>? deleted,
    PaginationModel? pagination,
  }) =>
      VariationOptionsModel(
        createdUpdated: createdUpdated ?? this.createdUpdated,
        deleted: deleted ?? this.deleted,
        pagination: pagination ?? this.pagination,
      );

  factory VariationOptionsModel.fromJson(Map<String, dynamic> json) => VariationOptionsModel(
        createdUpdated: (json["created_updated"] as List?)
                ?.map((x) => VariationOptionsCreatedUpdated.fromJson(Map<String, dynamic>.from(x as Map)))
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

class VariationOptionsCreatedUpdated {
  final int id;
  final String uuid;
  final int branchId;
  final int variationId;
  final String option;
  final String optionSlug;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic deletedAt;

  VariationOptionsCreatedUpdated({
    required this.id,
    required this.uuid,
    required this.branchId,
    required this.variationId,
    required this.option,
    required this.optionSlug,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  VariationOptionsCreatedUpdated copyWith({
    int? id,
    String? uuid,
    int? branchId,
    int? variationId,
    String? option,
    String? optionSlug,
    DateTime? createdAt,
    DateTime? updatedAt,
    dynamic deletedAt,
  }) =>
      VariationOptionsCreatedUpdated(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        branchId: branchId ?? this.branchId,
        variationId: variationId ?? this.variationId,
        option: option ?? this.option,
        optionSlug: optionSlug ?? this.optionSlug,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  factory VariationOptionsCreatedUpdated.fromJson(Map<String, dynamic> json) => VariationOptionsCreatedUpdated(
        id: (json["id"] as num?)?.toInt() ?? 0,
        uuid: json["uuid"]?.toString() ?? '',
        branchId: (json["branch_id"] as num?)?.toInt() ?? 0,
        variationId: (json["variation_id"] as num?)?.toInt() ?? 0,
        option: json["option"]?.toString() ?? '',
        optionSlug: json["option_slug"]?.toString() ?? '',
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
        "variation_id": variationId,
        "option": option,
        "option_slug": optionSlug,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
      };
}

class VariationsModel {
  final List<VariationsCreatedUpdated> createdUpdated;
  final List<dynamic> deleted;
  final PaginationModel pagination;

  VariationsModel({
    required this.createdUpdated,
    required this.deleted,
    required this.pagination,
  });

  VariationsModel copyWith({
    List<VariationsCreatedUpdated>? createdUpdated,
    List<dynamic>? deleted,
    PaginationModel? pagination,
  }) =>
      VariationsModel(
        createdUpdated: createdUpdated ?? this.createdUpdated,
        deleted: deleted ?? this.deleted,
        pagination: pagination ?? this.pagination,
      );

  factory VariationsModel.fromJson(Map<String, dynamic> json) => VariationsModel(
        createdUpdated: (json["created_updated"] as List?)
                ?.map((x) => VariationsCreatedUpdated.fromJson(Map<String, dynamic>.from(x as Map)))
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

class VariationsCreatedUpdated {
  final int id;
  final String uuid;
  final int branchId;
  final String name;
  final String variationSlug;
  final YesOrNo active;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic deletedAt;

  VariationsCreatedUpdated({
    required this.id,
    required this.uuid,
    required this.branchId,
    required this.name,
    required this.variationSlug,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  VariationsCreatedUpdated copyWith({
    int? id,
    String? uuid,
    int? branchId,
    String? name,
    String? variationSlug,
    YesOrNo? active,
    DateTime? createdAt,
    DateTime? updatedAt,
    dynamic deletedAt,
  }) =>
      VariationsCreatedUpdated(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        branchId: branchId ?? this.branchId,
        name: name ?? this.name,
        variationSlug: variationSlug ?? this.variationSlug,
        active: active ?? this.active,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  factory VariationsCreatedUpdated.fromJson(Map<String, dynamic> json) => VariationsCreatedUpdated(
        id: (json["id"] as num?)?.toInt() ?? 0,
        uuid: json["uuid"]?.toString() ?? '',
        branchId: (json["branch_id"] as num?)?.toInt() ?? 0,
        name: json["name"]?.toString() ?? '',
        variationSlug: json["variation_slug"]?.toString() ?? '',
        active: json["active"] == 'yes' ? YesOrNo.yes : YesOrNo.no,
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
        "name": name,
        "variation_slug": variationSlug,
        "active": active.name,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
      };
}
