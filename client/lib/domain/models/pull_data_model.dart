import 'dart:convert';

import 'package:pos/domain/models/category_model.dart';
import 'package:pos/domain/models/pagination_model.dart';
import 'package:pos/domain/models/customer_model.dart';
import 'package:pos/domain/models/delivery_partner_model.dart';
import 'package:pos/domain/models/driver_model.dart';
import 'package:pos/domain/models/expense_category_model.dart';
import 'package:pos/domain/models/item_model.dart';
import 'package:pos/domain/models/kitchen_model.dart';
import 'package:pos/domain/models/offer_model.dart';
import 'package:pos/domain/models/staff_model.dart';
import 'package:pos/domain/models/table_model.dart';
import 'package:pos/domain/models/toppings_model.dart';
import 'package:pos/domain/models/variation_model.dart';
import 'package:pos/domain/models/waiter_model.dart';

Map<String, dynamic>? _asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

T _parseChild<T>(dynamic raw, T Function(Map<String, dynamic> m) parse, T empty) {
  final m = _asJsonMap(raw);
  return m != null ? parse(m) : empty;
}

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

  factory PullData.fromJson(Map<String, dynamic> json) {
    final dataMap = _asJsonMap(json["data"]);
    final empty = _emptyPullDataModel();
    return PullData(
      success: json["success"] == true || json["success"]?.toString().toLowerCase() == 'true',
      message: json["message"]?.toString() ?? '',
      data: dataMap != null ? PullDataModel.fromJson(dataMap) : empty,
      errors: json["errors"],
    );
  }

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
  final OfferModel offers;
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
    required this.offers,
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
    OfferModel? offers,
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
        offers: offers ?? this.offers,
        // chairs: chairs ?? this.chairs,
      );

  factory PullDataModel.fromJson(Map<String, dynamic> json) {
    final p = PaginationModel.fallback();
    final emptyCategory = CategoryModel(createdUpdated: [], deleted: [], pagination: p);
    final emptyExpense = ExpenseCategoryModel(createdUpdated: [], deleted: [], pagination: p);
    final emptyDelivery = DeliveryServiceModel(createdUpdated: [], deleted: [], pagination: p);
    final emptyVariations = VariationsModel(createdUpdated: [], deleted: [], pagination: p);
    final emptyVarOptions = VariationOptionsModel(createdUpdated: [], deleted: [], pagination: p);
    final emptyTopping = ToppingModel(createdUpdated: [], deleted: [], pagination: p);
    final emptyKitchens = KitchensModel(createdUpdated: [], deleted: [], pagination: p);
    final emptyItem = ItemModel(createdUpdated: [], deleted: [], pagination: p);
    final emptyCustomer = CustomerModel(createdUpdated: [], deleted: [], pagination: p);
    final emptyDriver = DriverModel(createdUpdated: [], deleted: [], pagination: p);
    final emptyStaffs = StaffsModel(createdUpdated: [], deleted: [], pagination: p);
    final emptyWaiters = WaitersModel(createdUpdated: [], deleted: [], pagination: p);
    final emptyTables = TablesModel(createdUpdated: [], deleted: [], pagination: p);
    final emptyOffers = OfferModel(createdUpdated: [], deleted: [], pagination: p);

    return PullDataModel(
      category: _parseChild(json["category"], CategoryModel.fromJson, emptyCategory),
      unit: _parseChild(json["unit"], ExpenseCategoryModel.fromJson, emptyExpense),
      deliveryService: _parseChild(json["deliveryService"], DeliveryServiceModel.fromJson, emptyDelivery),
      variations: _parseChild(json["variations"], VariationsModel.fromJson, emptyVariations),
      variationOptions: _parseChild(json["variationOptions"], VariationOptionsModel.fromJson, emptyVarOptions),
      toppingCategories: _parseChild(json["toppingCategories"], ToppingModel.fromJson, emptyTopping),
      toppings: _parseChild(json["toppings"], ToppingModel.fromJson, emptyTopping),
      kitchens: _parseChild(json["kitchens"], KitchensModel.fromJson, emptyKitchens),
      item: _parseChild(json["item"], ItemModel.fromJson, emptyItem),
      expenseCategory: _parseChild(json["expenseCategory"], ExpenseCategoryModel.fromJson, emptyExpense),
      paymentMethods: _parseChild(json["paymentMethods"], ExpenseCategoryModel.fromJson, emptyExpense),
      customer: _parseChild(json["customer"], CustomerModel.fromJson, emptyCustomer),
      driver: _parseChild(json["driver"], DriverModel.fromJson, emptyDriver),
      staffs: _parseChild(json["staffs"], StaffsModel.fromJson, emptyStaffs),
      waiters: _parseChild(json["waiters"], WaitersModel.fromJson, emptyWaiters),
      floors: _parseChild(json["floors"], ExpenseCategoryModel.fromJson, emptyExpense),
      tables: _parseChild(json["tables"], TablesModel.fromJson, emptyTables),
      offers: _parseChild(json["offers"], OfferModel.fromJson, emptyOffers),
    );
  }

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
        "offers": offers.toJson(),
        // "chairs": chairs.toJson(),
      };
}

PullDataModel _emptyPullDataModel() {
  final p = PaginationModel.fallback();
  return PullDataModel(
    category: CategoryModel(createdUpdated: [], deleted: [], pagination: p),
    unit: ExpenseCategoryModel(createdUpdated: [], deleted: [], pagination: p),
    deliveryService: DeliveryServiceModel(createdUpdated: [], deleted: [], pagination: p),
    variations: VariationsModel(createdUpdated: [], deleted: [], pagination: p),
    variationOptions: VariationOptionsModel(createdUpdated: [], deleted: [], pagination: p),
    toppingCategories: ToppingModel(createdUpdated: [], deleted: [], pagination: p),
    toppings: ToppingModel(createdUpdated: [], deleted: [], pagination: p),
    kitchens: KitchensModel(createdUpdated: [], deleted: [], pagination: p),
    item: ItemModel(createdUpdated: [], deleted: [], pagination: p),
    expenseCategory: ExpenseCategoryModel(createdUpdated: [], deleted: [], pagination: p),
    paymentMethods: ExpenseCategoryModel(createdUpdated: [], deleted: [], pagination: p),
    customer: CustomerModel(createdUpdated: [], deleted: [], pagination: p),
    driver: DriverModel(createdUpdated: [], deleted: [], pagination: p),
    staffs: StaffsModel(createdUpdated: [], deleted: [], pagination: p),
    waiters: WaitersModel(createdUpdated: [], deleted: [], pagination: p),
    floors: ExpenseCategoryModel(createdUpdated: [], deleted: [], pagination: p),
    tables: TablesModel(createdUpdated: [], deleted: [], pagination: p),
    offers: OfferModel(createdUpdated: [], deleted: [], pagination: p),
  );
}
