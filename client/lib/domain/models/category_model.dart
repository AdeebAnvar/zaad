import 'package:pos/domain/models/pagination_model.dart';

class CategoryModel {
  final List<CategoryCreatedUpdated> createdUpdated;
  final List<int> deleted;
  final PaginationModel pagination;

  CategoryModel({
    required this.createdUpdated,
    required this.deleted,
    required this.pagination,
  });

  CategoryModel copyWith({
    List<CategoryCreatedUpdated>? createdUpdated,
    List<int>? deleted,
    PaginationModel? pagination,
  }) =>
      CategoryModel(
        createdUpdated: createdUpdated ?? this.createdUpdated,
        deleted: deleted ?? this.deleted,
        pagination: pagination ?? this.pagination,
      );

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        createdUpdated: (json["created_updated"] as List?)
                ?.map((x) => CategoryCreatedUpdated.fromJson(Map<String, dynamic>.from(x as Map)))
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

class CategoryCreatedUpdated {
  final int id;
  final String uuid;
  final int branchId;
  final String categoryName;
  final String categorySlug;
  final dynamic otherName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic deletedAt;

  CategoryCreatedUpdated({
    required this.id,
    required this.uuid,
    required this.branchId,
    required this.categoryName,
    required this.categorySlug,
    required this.otherName,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  CategoryCreatedUpdated copyWith({
    int? id,
    String? uuid,
    int? branchId,
    String? categoryName,
    String? categorySlug,
    dynamic otherName,
    DateTime? createdAt,
    DateTime? updatedAt,
    dynamic deletedAt,
  }) =>
      CategoryCreatedUpdated(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        branchId: branchId ?? this.branchId,
        categoryName: categoryName ?? this.categoryName,
        categorySlug: categorySlug ?? this.categorySlug,
        otherName: otherName ?? this.otherName,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  factory CategoryCreatedUpdated.fromJson(Map<String, dynamic> json) => CategoryCreatedUpdated(
        id: (json["id"] as num?)?.toInt() ?? 0,
        uuid: json["uuid"]?.toString() ?? '',
        branchId: (json["branch_id"] as num?)?.toInt() ?? 0,
        categoryName: json["category_name"]?.toString() ?? '',
        categorySlug: json["category_slug"]?.toString() ?? '',
        otherName: json["other_name"],
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
        "category_name": categoryName,
        "category_slug": categorySlug,
        "other_name": otherName,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
      };
}
