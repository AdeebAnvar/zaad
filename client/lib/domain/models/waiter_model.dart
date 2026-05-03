import 'package:pos/domain/models/pagination_model.dart';

class WaitersModel {
  final List<WaitersCreatedUpdated> createdUpdated;
  final List<dynamic> deleted;
  final PaginationModel pagination;

  WaitersModel({
    required this.createdUpdated,
    required this.deleted,
    required this.pagination,
  });

  WaitersModel copyWith({
    List<WaitersCreatedUpdated>? createdUpdated,
    List<dynamic>? deleted,
    PaginationModel? pagination,
  }) =>
      WaitersModel(
        createdUpdated: createdUpdated ?? this.createdUpdated,
        deleted: deleted ?? this.deleted,
        pagination: pagination ?? this.pagination,
      );

  factory WaitersModel.fromJson(Map<String, dynamic> json) => WaitersModel(
        createdUpdated: List<WaitersCreatedUpdated>.from(json["created_updated"].map((x) => WaitersCreatedUpdated.fromJson(x))),
        deleted: List<dynamic>.from(json["deleted"].map((x) => x)),
        pagination: PaginationModel.fromJson(json["pagination"]),
      );

  Map<String, dynamic> toJson() => {
        "created_updated": List<dynamic>.from(createdUpdated.map((x) => x.toJson())),
        "deleted": List<dynamic>.from(deleted.map((x) => x)),
        "pagination": pagination.toJson(),
      };
}

class WaitersCreatedUpdated {
  final int id;
  final String uuid;
  final int branchId;
  final String waiterName;
  final String waiterPhone;
  final String waiterCode;
  final String waiterPin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic deletedAt;

  WaitersCreatedUpdated({
    required this.id,
    required this.uuid,
    required this.branchId,
    required this.waiterName,
    required this.waiterPhone,
    required this.waiterCode,
    required this.waiterPin,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  WaitersCreatedUpdated copyWith({
    int? id,
    String? uuid,
    int? branchId,
    String? waiterName,
    String? waiterPhone,
    String? waiterCode,
    String? waiterPin,
    DateTime? createdAt,
    DateTime? updatedAt,
    dynamic deletedAt,
  }) =>
      WaitersCreatedUpdated(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        branchId: branchId ?? this.branchId,
        waiterName: waiterName ?? this.waiterName,
        waiterPhone: waiterPhone ?? this.waiterPhone,
        waiterCode: waiterCode ?? this.waiterCode,
        waiterPin: waiterPin ?? this.waiterPin,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  factory WaitersCreatedUpdated.fromJson(Map<String, dynamic> json) => WaitersCreatedUpdated(
        id: json["id"],
        uuid: json["uuid"],
        branchId: json["branch_id"],
        waiterName: json["waiter_name"],
        waiterPhone: json["waiter_phone"],
        waiterCode: json["waiter_code"],
        waiterPin: json["waiter_pin"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        deletedAt: json["deleted_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "uuid": uuid,
        "branch_id": branchId,
        "waiter_name": waiterName,
        "waiter_phone": waiterPhone,
        "waiter_code": waiterCode,
        "waiter_pin": waiterPin,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
      };
}
