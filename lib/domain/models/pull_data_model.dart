import 'dart:convert';

import 'package:pos/data/local/drift_database.dart';
import 'package:pos/domain/models/category_model.dart';
import 'package:pos/domain/models/customer_model.dart';
import 'package:pos/domain/models/delivery_partner_model.dart';
import 'package:pos/domain/models/driver_model.dart';
import 'package:pos/domain/models/expense_category_model.dart';
import 'package:pos/domain/models/item_model.dart';
import 'package:pos/domain/models/kitchen_model.dart';
import 'package:pos/domain/models/staff_model.dart';
import 'package:pos/domain/models/table_model.dart';
import 'package:pos/domain/models/toppings_model.dart';
import 'package:pos/domain/models/variation_model.dart';
import 'package:pos/domain/models/waiter_model.dart';

PullData pullDataFromJson(String str) => PullData.fromJson(json.decode(str));

String pullDataToJson(PullData data) => json.encode(data.toJson());

class PullData {
  final bool success;
  final String message;
  final PullDataModel data;
  final dynamic errors;

  PullData({
    required this.success,
    required this.message,
    required this.data,
    required this.errors,
  });

  PullData copyWith({
    bool? success,
    String? message,
    PullDataModel? data,
    dynamic errors,
  }) =>
      PullData(
        success: success ?? this.success,
        message: message ?? this.message,
        data: data ?? this.data,
        errors: errors ?? this.errors,
      );

  factory PullData.fromJson(Map<String, dynamic> json) => PullData(
        success: json["success"],
        message: json["message"],
        data: PullDataModel.fromJson(json["data"]),
        errors: json["errors"],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data.toJson(),
        "errors": errors,
      };
}

class PullDataModel {
  final CategoryModel category;
  final ExpenseCategoryModel unit;
  final DeliveryServiceModel deliveryService;
  final VariationsModel variations;
  final VariationOptionsModel variationOptions;
  final ToppingModel toppingCategories;
  final ToppingModel toppings;
  final KitchensModel kitchens;
  final ItemModel item;
  final ExpenseCategoryModel expenseCategory;
  final ExpenseCategoryModel paymentMethods;
  final CustomerModel customer;
  final DriverModel driver;
  final StaffsModel staffs;
  final WaitersModel waiters;
  final ExpenseCategoryModel floors;
  final TablesModel tables;
  // final Category chairs;

  PullDataModel({
    required this.category,
    required this.unit,
    required this.deliveryService,
    required this.variations,
    required this.variationOptions,
    required this.toppingCategories,
    required this.toppings,
    required this.kitchens,
    required this.item,
    required this.expenseCategory,
    required this.paymentMethods,
    required this.customer,
    required this.driver,
    required this.staffs,
    required this.waiters,
    required this.floors,
    required this.tables,
    // required this.chairs,
  });

  PullDataModel copyWith({
    CategoryModel? category,
    ExpenseCategoryModel? unit,
    DeliveryServiceModel? deliveryService,
    VariationsModel? variations,
    VariationOptionsModel? variationOptions,
    ToppingModel? toppingCategories,
    ToppingModel? toppings,
    KitchensModel? kitchens,
    ItemModel? item,
    ExpenseCategoryModel? expenseCategory,
    ExpenseCategoryModel? paymentMethods,
    CustomerModel? customer,
    DriverModel? driver,
    StaffsModel? staffs,
    WaitersModel? waiters,
    ExpenseCategoryModel? floors,
    TablesModel? tables,
    // Category? chairs,
  }) =>
      PullDataModel(
        category: category ?? this.category,
        unit: unit ?? this.unit,
        deliveryService: deliveryService ?? this.deliveryService,
        variations: variations ?? this.variations,
        variationOptions: variationOptions ?? this.variationOptions,
        toppingCategories: toppingCategories ?? this.toppingCategories,
        toppings: toppings ?? this.toppings,
        kitchens: kitchens ?? this.kitchens,
        item: item ?? this.item,
        expenseCategory: expenseCategory ?? this.expenseCategory,
        paymentMethods: paymentMethods ?? this.paymentMethods,
        customer: customer ?? this.customer,
        driver: driver ?? this.driver,
        staffs: staffs ?? this.staffs,
        waiters: waiters ?? this.waiters,
        floors: floors ?? this.floors,
        tables: tables ?? this.tables,
        // chairs: chairs ?? this.chairs,
      );

  factory PullDataModel.fromJson(Map<String, dynamic> json) => PullDataModel(
        category: CategoryModel.fromJson(json["category"]),
        unit: ExpenseCategoryModel.fromJson(json["unit"]),
        deliveryService: DeliveryServiceModel.fromJson(json["deliveryService"]),
        variations: VariationsModel.fromJson(json["variations"]),
        variationOptions: VariationOptionsModel.fromJson(json["variationOptions"]),
        toppingCategories: ToppingModel.fromJson(json["toppingCategories"]),
        toppings: ToppingModel.fromJson(json["toppings"]),
        kitchens: KitchensModel.fromJson(json["kitchens"]),
        item: ItemModel.fromJson(json["item"]),
        expenseCategory: ExpenseCategoryModel.fromJson(json["expenseCategory"]),
        paymentMethods: ExpenseCategoryModel.fromJson(json["paymentMethods"]),
        customer: CustomerModel.fromJson(json["customer"]),
        driver: DriverModel.fromJson(json["driver"]),
        staffs: StaffsModel.fromJson(json["staffs"]),
        waiters: WaitersModel.fromJson(json["waiters"]),
        floors: ExpenseCategoryModel.fromJson(json["floors"]),
        tables: TablesModel.fromJson(json["tables"]),
        // chairs: Category.fromJson(json["chairs"]),
      );

  Map<String, dynamic> toJson() => {
        "category": category.toJson(),
        "unit": unit.toJson(),
        "deliveryService": deliveryService.toJson(),
        "variations": variations.toJson(),
        "variationOptions": variationOptions.toJson(),
        "toppingCategories": toppingCategories.toJson(),
        "toppings": toppings.toJson(),
        "kitchens": kitchens.toJson(),
        "item": item.toJson(),
        "expenseCategory": expenseCategory.toJson(),
        "paymentMethods": paymentMethods.toJson(),
        "customer": customer.toJson(),
        "driver": driver.toJson(),
        "staffs": staffs.toJson(),
        "waiters": waiters.toJson(),
        "floors": floors.toJson(),
        "tables": tables.toJson(),
        // "chairs": chairs.toJson(),
      };
}
