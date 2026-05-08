import 'package:pos/domain/models/pagination_model.dart';

class CustomerModel {
  final List<CustomerCreatedUpdated> createdUpdated;
  final List<dynamic> deleted;
  final PaginationModel pagination;

  CustomerModel({
    required this.createdUpdated,
    required this.deleted,
    required this.pagination,
  });

  CustomerModel copyWith({
    List<CustomerCreatedUpdated>? createdUpdated,
    List<dynamic>? deleted,
    PaginationModel? pagination,
  }) =>
      CustomerModel(
        createdUpdated: createdUpdated ?? this.createdUpdated,
        deleted: deleted ?? this.deleted,
        pagination: pagination ?? this.pagination,
      );

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        createdUpdated: (json["created_updated"] as List?)
                ?.map((x) => CustomerCreatedUpdated.fromJson(Map<String, dynamic>.from(x as Map)))
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

class CustomerCreatedUpdated {
  final int id;
  final String uuid;
  final int branchId;
  final String customerName;
  final String customerNumber;
  final String customerEmail;
  final String customerAddress;
  final String customerGender;
  final String cardNo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic deletedAt;

  CustomerCreatedUpdated({
    required this.id,
    required this.uuid,
    required this.branchId,
    required this.customerName,
    required this.customerNumber,
    required this.customerEmail,
    required this.customerAddress,
    required this.customerGender,
    required this.cardNo,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  CustomerCreatedUpdated copyWith({
    int? id,
    String? uuid,
    int? branchId,
    String? customerName,
    String? customerNumber,
    String? customerEmail,
    String? customerAddress,
    String? customerGender,
    String? cardNo,
    DateTime? createdAt,
    DateTime? updatedAt,
    dynamic deletedAt,
  }) =>
      CustomerCreatedUpdated(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        branchId: branchId ?? this.branchId,
        customerName: customerName ?? this.customerName,
        customerNumber: customerNumber ?? this.customerNumber,
        customerEmail: customerEmail ?? this.customerEmail,
        customerAddress: customerAddress ?? this.customerAddress,
        customerGender: customerGender ?? this.customerGender,
        cardNo: cardNo ?? this.cardNo,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  factory CustomerCreatedUpdated.fromJson(Map<String, dynamic> json) => CustomerCreatedUpdated(
        id: (json["id"] as num?)?.toInt() ?? 0,
        uuid: json["uuid"]?.toString() ?? '',
        branchId: (json["branch_id"] as num?)?.toInt() ?? 0,
        customerName: json["customer_name"]?.toString() ?? '',
        customerNumber: json["customer_number"]?.toString() ?? '',
        customerEmail: json["customer_email"]?.toString() ?? '',
        customerAddress: json["customer_address"]?.toString() ?? '',
        customerGender: json["customer_gender"]?.toString() ?? '',
        cardNo: json["card_no"]?.toString() ?? '',
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
        "customer_name": customerName,
        "customer_number": customerNumber,
        "customer_email": customerEmail,
        "customer_address": customerAddress,
        "customer_gender": customerGender,
        "card_no": cardNo,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
      };
}
