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
        createdUpdated: List<CategoryCreatedUpdated>.from(json["created_updated"].map((x) => CategoryCreatedUpdated.fromJson(x))),
        deleted: List<int>.from(json["deleted"].map((x) => x)),
        pagination: PaginationModel.fromJson(json["pagination"]),
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
        id: json["id"],
        uuid: json["uuid"],
        branchId: json["branch_id"],
        categoryName: json["category_name"],
        categorySlug: json["category_slug"],
        otherName: json["other_name"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
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
