import 'package:pos/domain/models/item_topping_model.dart' show ItemTopping;
import 'package:pos/domain/models/item_variant_model.dart';

class ItemModel {
  final int id;
  final String name;
  final String otherName;
  final String categoryName;
  final String categoryOtherName;
  final String barcode;
  final String sku;
  final double price;
  int stock;
  final String imagePath;
  String localImagePath;
  final int categoryId;
  final int? kitchenId;
  final String? kitchenName;
  final List<ItemVariant> variants;
  final List<ItemTopping> toppings;

  ItemModel({
    required this.id,
    required this.name,
    required this.otherName,
    required this.sku,
    required this.price,
    required this.stock,
    required this.imagePath,
    this.localImagePath = '',
    required this.categoryId,
    required this.categoryName,
    required this.categoryOtherName,
    required this.barcode,
    this.kitchenId,
    this.kitchenName,
    this.variants = const [],
    this.toppings = const [],
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'] as int,
      name: json['name'] as String,
      otherName: json['other_name'] as String? ?? '',
      sku: json['sku'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
      imagePath: json['image_path'] as String,
      localImagePath: json['local_image_path'] as String? ?? '',
      categoryId: json['category_id'] as int,
      categoryName: json['category_name'] as String,
      categoryOtherName: json['category_other_name'] as String? ?? '',
      barcode: json['barcode'] as String? ?? '',
      kitchenId: json['kitchen_id'] as int?,
      kitchenName: json['kitchen_name'] as String?,
      variants: (json['variants'] as List<dynamic>?)?.map((e) => ItemVariant.fromJson(e)).toList() ?? [],
      toppings: (json['toppings'] as List<dynamic>?)?.map((e) => ItemTopping.fromJson(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'other_name': otherName,
      'sku': sku,
      'price': price,
      'stock': stock,
      'image_path': imagePath,
      'local_image_path': localImagePath,
      'category_id': categoryId,
      'category_name': categoryName,
      'category_other_name': categoryOtherName,
      'barcode': barcode,
      'kitchen_id': kitchenId,
      'kitchen_name': kitchenName,
      'variants': variants.map((e) => e.toJson()).toList(),
      'toppings': toppings.map((e) => e.toJson()).toList(),
    };
  }

  bool get hasVariants => variants.isNotEmpty;
  bool get hasToppings => toppings.isNotEmpty;
}
