import 'package:pos/domain/models/pagination_model.dart';

class ExpenseCategoryModel {
  final List<ExpenseCategoryCreatedUpdated> createdUpdated;
  final List<dynamic> deleted;
  final PaginationModel pagination;

  ExpenseCategoryModel({
    required this.createdUpdated,
    required this.deleted,
    required this.pagination,
  });

  ExpenseCategoryModel copyWith({
    List<ExpenseCategoryCreatedUpdated>? createdUpdated,
    List<dynamic>? deleted,
    PaginationModel? pagination,
  }) =>
      ExpenseCategoryModel(
        createdUpdated: createdUpdated ?? this.createdUpdated,
        deleted: deleted ?? this.deleted,
        pagination: pagination ?? this.pagination,
      );

  factory ExpenseCategoryModel.fromJson(Map<String, dynamic> json) => ExpenseCategoryModel(
        createdUpdated: (json["created_updated"] as List?)
                ?.map((x) => ExpenseCategoryCreatedUpdated.fromJson(Map<String, dynamic>.from(x as Map)))
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

class ExpenseCategoryCreatedUpdated {
  final int id;
  final String uuid;
  final int branchId;
  final String? expenseCategoryName;
  final String? expenseCategorySlug;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic deletedAt;
  final String? floorName;
  final String? floorSlug;
  final String? paymentMethodName;
  final String? paymentMethodSlug;
  final String? unitName;
  final String? unitSlug;

  ExpenseCategoryCreatedUpdated({
    required this.id,
    required this.uuid,
    required this.branchId,
    this.expenseCategoryName,
    this.expenseCategorySlug,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
    this.floorName,
    this.floorSlug,
    this.paymentMethodName,
    this.paymentMethodSlug,
    this.unitName,
    this.unitSlug,
  });

  ExpenseCategoryCreatedUpdated copyWith({
    int? id,
    String? uuid,
    int? branchId,
    String? expenseCategoryName,
    String? expenseCategorySlug,
    DateTime? createdAt,
    DateTime? updatedAt,
    dynamic deletedAt,
    String? floorName,
    String? floorSlug,
    String? paymentMethodName,
    String? paymentMethodSlug,
    String? unitName,
    String? unitSlug,
  }) =>
      ExpenseCategoryCreatedUpdated(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        branchId: branchId ?? this.branchId,
        expenseCategoryName: expenseCategoryName ?? this.expenseCategoryName,
        expenseCategorySlug: expenseCategorySlug ?? this.expenseCategorySlug,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        floorName: floorName ?? this.floorName,
        floorSlug: floorSlug ?? this.floorSlug,
        paymentMethodName: paymentMethodName ?? this.paymentMethodName,
        paymentMethodSlug: paymentMethodSlug ?? this.paymentMethodSlug,
        unitName: unitName ?? this.unitName,
        unitSlug: unitSlug ?? this.unitSlug,
      );

  factory ExpenseCategoryCreatedUpdated.fromJson(Map<String, dynamic> json) => ExpenseCategoryCreatedUpdated(
        id: (json["id"] as num?)?.toInt() ?? 0,
        uuid: json["uuid"]?.toString() ?? '',
        branchId: (json["branch_id"] as num?)?.toInt() ?? 0,
        expenseCategoryName: json["expense_category_name"]?.toString(),
        expenseCategorySlug: json["expense_category_slug"]?.toString(),
        createdAt:
            DateTime.tryParse(json["created_at"]?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt:
            DateTime.tryParse(json["updated_at"]?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        deletedAt: json["deleted_at"],
        floorName: json["floor_name"]?.toString(),
        floorSlug: json["floor_slug"]?.toString(),
        paymentMethodName: json["payment_method_name"]?.toString(),
        paymentMethodSlug: json["payment_method_slug"]?.toString(),
        unitName: json["unit_name"]?.toString(),
        unitSlug: json["unit_slug"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "uuid": uuid,
        "branch_id": branchId,
        "expense_category_name": expenseCategoryName,
        "expense_category_slug": expenseCategorySlug,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
        "floor_name": floorName,
        "floor_slug": floorSlug,
        "payment_method_name": paymentMethodName,
        "payment_method_slug": paymentMethodSlug,
        "unit_name": unitName,
        "unit_slug": unitSlug,
      };
}
