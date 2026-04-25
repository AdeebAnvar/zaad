import 'package:pos/domain/models/pagination_model.dart';

class StaffsModel {
  final List<StaffsCreatedUpdated> createdUpdated;
  final List<dynamic> deleted;
  final PaginationModel pagination;

  StaffsModel({
    required this.createdUpdated,
    required this.deleted,
    required this.pagination,
  });

  StaffsModel copyWith({
    List<StaffsCreatedUpdated>? createdUpdated,
    List<dynamic>? deleted,
    PaginationModel? pagination,
  }) =>
      StaffsModel(
        createdUpdated: createdUpdated ?? this.createdUpdated,
        deleted: deleted ?? this.deleted,
        pagination: pagination ?? this.pagination,
      );

  factory StaffsModel.fromJson(Map<String, dynamic> json) => StaffsModel(
        createdUpdated: List<StaffsCreatedUpdated>.from(json["created_updated"].map((x) => StaffsCreatedUpdated.fromJson(x))),
        deleted: List<dynamic>.from(json["deleted"].map((x) => x)),
        pagination: PaginationModel.fromJson(json["pagination"]),
      );

  Map<String, dynamic> toJson() => {
        "created_updated": List<dynamic>.from(createdUpdated.map((x) => x.toJson())),
        "deleted": List<dynamic>.from(deleted.map((x) => x)),
        "pagination": pagination.toJson(),
      };
}

class StaffsCreatedUpdated {
  final int id;
  final String uuid;
  final int branchId;
  final String staffName;
  final String staffEmail;
  final String staffPhone;
  final String staffAddress;
  final DateTime dateOfJoin;
  final String staffCode;
  final String staffPin;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic deletedAt;

  StaffsCreatedUpdated({
    required this.id,
    required this.uuid,
    required this.branchId,
    required this.staffName,
    required this.staffEmail,
    required this.staffPhone,
    required this.staffAddress,
    required this.dateOfJoin,
    required this.staffCode,
    required this.staffPin,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  StaffsCreatedUpdated copyWith({
    int? id,
    String? uuid,
    int? branchId,
    String? staffName,
    String? staffEmail,
    String? staffPhone,
    String? staffAddress,
    DateTime? dateOfJoin,
    String? staffCode,
    String? staffPin,
    DateTime? createdAt,
    DateTime? updatedAt,
    dynamic deletedAt,
  }) =>
      StaffsCreatedUpdated(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        branchId: branchId ?? this.branchId,
        staffName: staffName ?? this.staffName,
        staffEmail: staffEmail ?? this.staffEmail,
        staffPhone: staffPhone ?? this.staffPhone,
        staffAddress: staffAddress ?? this.staffAddress,
        dateOfJoin: dateOfJoin ?? this.dateOfJoin,
        staffCode: staffCode ?? this.staffCode,
        staffPin: staffPin ?? this.staffPin,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  factory StaffsCreatedUpdated.fromJson(Map<String, dynamic> json) => StaffsCreatedUpdated(
        id: json["id"],
        uuid: json["uuid"],
        branchId: json["branch_id"],
        staffName: json["staff_name"],
        staffEmail: json["staff_email"],
        staffPhone: json["staff_phone"],
        staffAddress: json["staff_address"],
        dateOfJoin: DateTime.parse(json["date_of_join"]),
        staffCode: json["staff_code"],
        staffPin: json["staff_pin"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        deletedAt: json["deleted_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "uuid": uuid,
        "branch_id": branchId,
        "staff_name": staffName,
        "staff_email": staffEmail,
        "staff_phone": staffPhone,
        "staff_address": staffAddress,
        "date_of_join": "${dateOfJoin.year.toString().padLeft(4, '0')}-${dateOfJoin.month.toString().padLeft(2, '0')}-${dateOfJoin.day.toString().padLeft(2, '0')}",
        "staff_code": staffCode,
        "staff_pin": staffPin,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
      };
}
