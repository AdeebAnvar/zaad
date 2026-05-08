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
        createdUpdated: (json["created_updated"] as List?)
                ?.map((x) => StaffsCreatedUpdated.fromJson(Map<String, dynamic>.from(x as Map)))
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
        id: (json["id"] as num?)?.toInt() ?? 0,
        uuid: json["uuid"]?.toString() ?? '',
        branchId: (json["branch_id"] as num?)?.toInt() ?? 0,
        staffName: json["staff_name"]?.toString() ?? '',
        staffEmail: json["staff_email"]?.toString() ?? '',
        staffPhone: json["staff_phone"]?.toString() ?? '',
        staffAddress: json["staff_address"]?.toString() ?? '',
        dateOfJoin:
            DateTime.tryParse(json["date_of_join"]?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        staffCode: json["staff_code"]?.toString() ?? '',
        staffPin: json["staff_pin"]?.toString() ?? '',
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
