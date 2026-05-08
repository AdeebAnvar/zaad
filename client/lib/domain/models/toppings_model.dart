import 'package:pos/domain/models/pagination_model.dart';

/// Handles int fields that may be encoded as int, num, or string in API JSON.
int? _parseIntLoose(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) {
    final t = value.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t) ?? num.tryParse(t)?.round();
  }
  return null;
}

class ToppingModel {
  final List<ToppingCategoriesCreatedUpdated> createdUpdated;
  final List<dynamic> deleted;
  final PaginationModel pagination;

  ToppingModel({
    required this.createdUpdated,
    required this.deleted,
    required this.pagination,
  });

  ToppingModel copyWith({
    List<ToppingCategoriesCreatedUpdated>? createdUpdated,
    List<dynamic>? deleted,
    PaginationModel? pagination,
  }) =>
      ToppingModel(
        createdUpdated: createdUpdated ?? this.createdUpdated,
        deleted: deleted ?? this.deleted,
        pagination: pagination ?? this.pagination,
      );

  factory ToppingModel.fromJson(Map<String, dynamic> json) => ToppingModel(
        createdUpdated: List<ToppingCategoriesCreatedUpdated>.from(
          (json["created_updated"] as List? ?? const <dynamic>[]).map(
            (x) => ToppingCategoriesCreatedUpdated.fromJson(
              Map<String, dynamic>.from(x as Map),
            ),
          ),
        ),
        deleted: List<dynamic>.from(
          (json["deleted"] as List? ?? const <dynamic>[]).map((x) => x),
        ),
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

class ToppingCategoriesCreatedUpdated {
  final int id;
  final String uuid;
  final String slug;
  final int branchId;
  final String name;
  final int? minSelect;
  final int? maxSelect;
  final int status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic deletedAt;
  final int? toppingsCategoryId;
  final String? price;
  final int? toppingType;

  ToppingCategoriesCreatedUpdated({
    required this.id,
    required this.uuid,
    required this.slug,
    required this.branchId,
    required this.name,
    this.minSelect,
    this.maxSelect,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    this.toppingsCategoryId,
    this.price,
    this.toppingType,
  });

  ToppingCategoriesCreatedUpdated copyWith({
    int? id,
    String? uuid,
    String? slug,
    int? branchId,
    String? name,
    int? minSelect,
    int? maxSelect,
    int? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    dynamic deletedAt,
    int? toppingsCategoryId,
    String? price,
    int? toppingType,
  }) =>
      ToppingCategoriesCreatedUpdated(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        slug: slug ?? this.slug,
        branchId: branchId ?? this.branchId,
        name: name ?? this.name,
        minSelect: minSelect ?? this.minSelect,
        maxSelect: maxSelect ?? this.maxSelect,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        toppingsCategoryId: toppingsCategoryId ?? this.toppingsCategoryId,
        price: price ?? this.price,
        toppingType: toppingType ?? this.toppingType,
      );

  factory ToppingCategoriesCreatedUpdated.fromJson(Map<String, dynamic> json) => ToppingCategoriesCreatedUpdated(
        id: _parseIntLoose(json["id"]) ?? 0,
        uuid: (json["uuid"] ?? '').toString(),
        slug: (json["slug"] ?? '').toString(),
        branchId: _parseIntLoose(json["branch_id"]) ?? 0,
        name: (json["name"] ?? '').toString(),
        // Category rows use min_select / max_select; individual toppings do not.
        minSelect: _parseIntLoose(json["min_select"] ?? json["minSelect"]),
        maxSelect: _parseIntLoose(json["max_select"] ?? json["maxSelect"]),
        status: _parseIntLoose(json["status"]) ?? 0,
        createdAt: DateTime.tryParse(json["created_at"]?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.tryParse(json["updated_at"]?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        deletedAt: json["deleted_at"],
        toppingsCategoryId: _parseIntLoose(
          json["toppings_category_id"] ??
              json["toppingsCategoryId"] ??
              json["topping_category_id"] ??
              json["toppingCategoryId"],
        ),
        price: json["price"]?.toString(),
        toppingType: _parseIntLoose(json["topping_type"] ?? json["toppingType"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "uuid": uuid,
        "slug": slug,
        "branch_id": branchId,
        "name": name,
        "min_select": minSelect,
        "max_select": maxSelect,
        "status": status,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
        "toppings_category_id": toppingsCategoryId,
        "price": price,
        "topping_type": toppingType,
      };
}
