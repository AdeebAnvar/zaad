import 'package:pos/core/constants/enums.dart';
import 'package:pos/domain/models/pagination_model.dart';

class ItemModel {
  final List<ItemCreatedUpdated> createdUpdated;
  final List<dynamic> deleted;
  final PaginationModel pagination;

  ItemModel({
    required this.createdUpdated,
    required this.deleted,
    required this.pagination,
  });

  ItemModel copyWith({
    List<ItemCreatedUpdated>? createdUpdated,
    List<dynamic>? deleted,
    PaginationModel? pagination,
  }) =>
      ItemModel(
        createdUpdated: createdUpdated ?? this.createdUpdated,
        deleted: deleted ?? this.deleted,
        pagination: pagination ?? this.pagination,
      );
  factory ItemModel.fromJson(Map<String, dynamic> json) => ItemModel(
        createdUpdated: (json["created_updated"] as List? ?? []).map((x) => ItemCreatedUpdated.fromJson(x)).toList(),
        deleted: (json["deleted"] as List? ?? []),
        pagination: PaginationModel.fromJson(json["pagination"]), // create an empty constructor if needed
      );
  Map<String, dynamic> toJson() => {
        "created_updated": List<dynamic>.from(createdUpdated.map((x) => x.toJson())),
        "deleted": List<dynamic>.from(deleted.map((x) => x)),
        "pagination": pagination.toJson(),
      };
}

class ItemCreatedUpdated {
  final int id;
  final String uuid;
  final int branchId;
  final int categoryId;
  final int unitId;
  final String itemName;
  final String itemSlug;
  final String itemOtherName;
  final String kitchenIds;
  final dynamic toppingIds;
  final YesOrNo tax;
  final dynamic taxPercent;
  final int minimumQty;
  final String itemType;
  final String stockApplicable;
  final String ingredient;
  final OrderType orderType;
  final String deliveryService;
  final String image;
  final String expiryDate;
  final YesOrNo active;
  final int isVariant;
  final List<dynamic> itemVariations;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic deletedAt;
  final List<Itemprice> itemprice;

  ItemCreatedUpdated({
    required this.id,
    required this.uuid,
    required this.branchId,
    required this.categoryId,
    required this.unitId,
    required this.itemName,
    required this.itemSlug,
    required this.itemOtherName,
    required this.kitchenIds,
    required this.toppingIds,
    required this.tax,
    required this.taxPercent,
    required this.minimumQty,
    required this.itemType,
    required this.stockApplicable,
    required this.ingredient,
    required this.orderType,
    required this.deliveryService,
    required this.image,
    required this.expiryDate,
    required this.active,
    required this.isVariant,
    required this.itemVariations,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.itemprice,
  });

  ItemCreatedUpdated copyWith({
    int? id,
    String? uuid,
    int? branchId,
    int? categoryId,
    int? unitId,
    String? itemName,
    String? itemSlug,
    dynamic itemOtherName,
    String? kitchenIds,
    dynamic toppingIds,
    YesOrNo? tax,
    dynamic taxPercent,
    int? minimumQty,
    String? itemType,
    String? stockApplicable,
    String? ingredient,
    OrderType? orderType,
    String? deliveryService,
    String? image,
    dynamic expiryDate,
    YesOrNo? active,
    int? isVariant,
    List<dynamic>? itemVariations,
    DateTime? createdAt,
    DateTime? updatedAt,
    dynamic deletedAt,
    List<Itemprice>? itemprice,
  }) =>
      ItemCreatedUpdated(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        branchId: branchId ?? this.branchId,
        categoryId: categoryId ?? this.categoryId,
        unitId: unitId ?? this.unitId,
        itemName: itemName ?? this.itemName,
        itemSlug: itemSlug ?? this.itemSlug,
        itemOtherName: itemOtherName ?? this.itemOtherName,
        kitchenIds: kitchenIds ?? this.kitchenIds,
        toppingIds: toppingIds ?? this.toppingIds,
        tax: tax ?? this.tax,
        taxPercent: taxPercent ?? this.taxPercent,
        minimumQty: minimumQty ?? this.minimumQty,
        itemType: itemType ?? this.itemType,
        stockApplicable: stockApplicable ?? this.stockApplicable,
        ingredient: ingredient ?? this.ingredient,
        orderType: orderType ?? this.orderType,
        deliveryService: deliveryService ?? this.deliveryService,
        image: image ?? this.image,
        expiryDate: expiryDate ?? this.expiryDate,
        active: active ?? this.active,
        isVariant: isVariant ?? this.isVariant,
        itemVariations: itemVariations ?? this.itemVariations,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        itemprice: itemprice ?? this.itemprice,
      );
  factory ItemCreatedUpdated.fromJson(Map<String, dynamic> json) => ItemCreatedUpdated(
        id: json["id"] ?? 0,
        uuid: json["uuid"] ?? '',
        branchId: json["branch_id"] ?? 0,
        categoryId: json["category_id"] ?? 0,
        unitId: json["unit_id"] ?? 0,
        itemName: json["item_name"] ?? '',
        itemSlug: json["item_slug"] ?? '',
        itemOtherName: json["item_other_name"] ?? '',
        kitchenIds: json["kitchen_ids"] ?? '',
        toppingIds: json["topping_ids"],
        tax: json["tax"] == 'yes' ? YesOrNo.yes : YesOrNo.no,
        taxPercent: json["tax_percent"],
        minimumQty: json["minimum_qty"] ?? 0,
        itemType: json["item_type"] ?? '',
        stockApplicable: json["stock_applicable"] ?? '',
        ingredient: json["ingredient"] ?? '',
        orderType: json["order_type"] != null ? fromValue(json["order_type"]) : OrderType.counterSale,
        deliveryService: json["delivery_service"] ?? '',
        image: json["image"] ?? '',
        expiryDate: json["expiry_date"] ?? '',
        active: json["active"] == 'yes' ? YesOrNo.yes : YesOrNo.no,
        isVariant: json["is_variant"] ?? 0,
        itemVariations: (json["item_variations"] as List? ?? []),
        createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : DateTime.now(),
        updatedAt: json["updated_at"] != null ? DateTime.parse(json["updated_at"]) : DateTime.now(),
        deletedAt: json["deleted_at"],
        itemprice: (json["itemprice"] as List? ?? []).map((x) => Itemprice.fromJson(x)).toList(),
      );
  Map<String, dynamic> toJson() => {
        "id": id,
        "uuid": uuid,
        "branch_id": branchId,
        "category_id": categoryId,
        "unit_id": unitId,
        "item_name": itemName,
        "item_slug": itemSlug,
        "item_other_name": itemOtherName,
        "kitchen_ids": kitchenIds,
        "topping_ids": toppingIds,
        "tax": tax.name,
        "tax_percent": taxPercent,
        "minimum_qty": minimumQty,
        "item_type": itemType,
        "stock_applicable": stockApplicable,
        "ingredient": ingredient,
        "order_type": orderType.value,
        "delivery_service": deliveryService,
        "image": image,
        "expiry_date": expiryDate,
        "active": active.name,
        "is_variant": isVariant,
        "item_variations": List<dynamic>.from(itemVariations.map((x) => x)),
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
        "itemprice": List<dynamic>.from(itemprice.map((x) => x.toJson())),
      };
}

class Itemprice {
  final int id;
  final int branchId;
  final int itemId;
  final String? barcode;
  final int costPrice;
  final double price;
  final int stock;
  final int totalCostPrice;
  final String ingredientAdded;
  final String priceItemType;
  final dynamic combination;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic deletedAt;
  final dynamic variationOptionIds;
  final List<dynamic> variationOptions;

  Itemprice({
    required this.id,
    required this.branchId,
    required this.itemId,
    required this.barcode,
    required this.costPrice,
    required this.price,
    required this.stock,
    required this.totalCostPrice,
    required this.ingredientAdded,
    required this.priceItemType,
    required this.combination,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    required this.variationOptionIds,
    required this.variationOptions,
  });

  Itemprice copyWith({
    int? id,
    int? branchId,
    int? itemId,
    String? barcode,
    int? costPrice,
    double? price,
    int? stock,
    int? totalCostPrice,
    String? ingredientAdded,
    String? priceItemType,
    dynamic combination,
    DateTime? createdAt,
    DateTime? updatedAt,
    dynamic deletedAt,
    dynamic variationOptionIds,
    List<dynamic>? variationOptions,
  }) =>
      Itemprice(
        id: id ?? this.id,
        branchId: branchId ?? this.branchId,
        itemId: itemId ?? this.itemId,
        barcode: barcode ?? this.barcode,
        costPrice: costPrice ?? this.costPrice,
        price: price ?? this.price,
        stock: stock ?? this.stock,
        totalCostPrice: totalCostPrice ?? this.totalCostPrice,
        ingredientAdded: ingredientAdded ?? this.ingredientAdded,
        priceItemType: priceItemType ?? this.priceItemType,
        combination: combination ?? this.combination,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        variationOptionIds: variationOptionIds ?? this.variationOptionIds,
        variationOptions: variationOptions ?? this.variationOptions,
      );
  factory Itemprice.fromJson(Map<String, dynamic> json) => Itemprice(
        id: json["id"] ?? 0,
        branchId: json["branch_id"] ?? 0,
        itemId: json["item_id"] ?? 0,
        barcode: json["barcode"],
        costPrice: json["cost_price"] ?? 0,
        price: (json["price"] ?? 0).toDouble(),
        stock: json["stock"] ?? 0,
        totalCostPrice: json["total_cost_price"] ?? 0,
        ingredientAdded: json["ingredient_added"] ?? '',
        priceItemType: json["price_item_type"] ?? '',
        combination: json["combination"],
        createdAt: json["created_at"] != null ? DateTime.parse(json["created_at"]) : DateTime.now(),
        updatedAt: json["updated_at"] != null ? DateTime.parse(json["updated_at"]) : DateTime.now(),
        deletedAt: json["deleted_at"],
        variationOptionIds: json["variation_option_ids"],
        variationOptions: (json["variation_options"] as List? ?? []),
      );
  Map<String, dynamic> toJson() => {
        "id": id,
        "branch_id": branchId,
        "item_id": itemId,
        "barcode": barcode,
        "cost_price": costPrice,
        "price": price,
        "stock": stock,
        "total_cost_price": totalCostPrice,
        "ingredient_added": ingredientAdded,
        "price_item_type": priceItemType,
        "combination": combination,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
        "variation_option_ids": variationOptionIds,
        "variation_options": List<dynamic>.from(variationOptions.map((x) => x)),
      };
}

OrderType fromValue(String? value) {
  if (value == null) return OrderType.counterSale;

  return OrderType.values.firstWhere(
    (e) => e.value == value,
    orElse: () => OrderType.counterSale,
  );
}
