import 'package:pos/domain/models/pagination_model.dart';

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
        createdUpdated: List<ToppingCategoriesCreatedUpdated>.from(json["created_updated"].map((x) => ToppingCategoriesCreatedUpdated.fromJson(x))),
        deleted: List<dynamic>.from(json["deleted"].map((x) => x)),
        pagination: PaginationModel.fromJson(json["pagination"]),
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
        id: json["id"],
        uuid: json["uuid"],
        slug: json["slug"],
        branchId: json["branch_id"],
        name: json["name"],
        minSelect: json["min_select"],
        maxSelect: json["max_select"],
        status: json["status"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        deletedAt: json["deleted_at"],
        toppingsCategoryId: json["toppings_category_id"],
        price: json["price"],
        toppingType: json["topping_type"],
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
