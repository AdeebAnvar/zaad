import 'package:pos/domain/models/pagination_model.dart';

class DriverModel {
  final List<DriverCreatedUpdated> createdUpdated;
  final List<dynamic> deleted;
  final PaginationModel pagination;

  DriverModel({
    required this.createdUpdated,
    required this.deleted,
    required this.pagination,
  });

  DriverModel copyWith({
    List<DriverCreatedUpdated>? createdUpdated,
    List<dynamic>? deleted,
    PaginationModel? pagination,
  }) =>
      DriverModel(
        createdUpdated: createdUpdated ?? this.createdUpdated,
        deleted: deleted ?? this.deleted,
        pagination: pagination ?? this.pagination,
      );

  factory DriverModel.fromJson(Map<String, dynamic> json) => DriverModel(
        createdUpdated: ((json["created_updated"] as List?) ?? const <dynamic>[])
            .whereType<Map>()
            .map((x) => DriverCreatedUpdated.fromJson(Map<String, dynamic>.from(x)))
            .toList(),
        deleted: List<dynamic>.from((json["deleted"] as List?) ?? const <dynamic>[]),
        pagination: json["pagination"] is Map
            ? PaginationModel.fromJson(Map<String, dynamic>.from(json["pagination"] as Map))
            : PaginationModel(
                currentPage: 1,
                lastPage: 1,
                perPage: 15,
                total: 0,
                hasMore: false,
              ),
      );

  Map<String, dynamic> toJson() => {
        "created_updated": List<dynamic>.from(createdUpdated.map((x) => x.toJson())),
        "deleted": List<dynamic>.from(deleted.map((x) => x)),
        "pagination": pagination.toJson(),
      };
}

class DriverCreatedUpdated {
  final int id;
  final String uuid;
  final int branchId;
  final String driverName;
  final String driverEmail;
  final String driverPhone;
  final String driverAddress;
  final DateTime dateOfJoin;
  final String driverCode;
  final String driverPin;
  final String driverLicense;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic deletedAt;

  DriverCreatedUpdated({
    required this.id,
    required this.uuid,
    required this.branchId,
    required this.driverName,
    required this.driverEmail,
    required this.driverPhone,
    required this.driverAddress,
    required this.dateOfJoin,
    required this.driverCode,
    required this.driverPin,
    required this.driverLicense,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  DriverCreatedUpdated copyWith({
    int? id,
    String? uuid,
    int? branchId,
    String? driverName,
    String? driverEmail,
    String? driverPhone,
    String? driverAddress,
    DateTime? dateOfJoin,
    String? driverCode,
    String? driverPin,
    String? driverLicense,
    DateTime? createdAt,
    DateTime? updatedAt,
    dynamic deletedAt,
  }) =>
      DriverCreatedUpdated(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        branchId: branchId ?? this.branchId,
        driverName: driverName ?? this.driverName,
        driverEmail: driverEmail ?? this.driverEmail,
        driverPhone: driverPhone ?? this.driverPhone,
        driverAddress: driverAddress ?? this.driverAddress,
        dateOfJoin: dateOfJoin ?? this.dateOfJoin,
        driverCode: driverCode ?? this.driverCode,
        driverPin: driverPin ?? this.driverPin,
        driverLicense: driverLicense ?? this.driverLicense,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  factory DriverCreatedUpdated.fromJson(Map<String, dynamic> json) => DriverCreatedUpdated(
        id: (json["id"] as num?)?.toInt() ?? 0,
        uuid: json["uuid"]?.toString() ?? '',
        branchId: (json["branch_id"] as num?)?.toInt() ?? 0,
        driverName: json["driver_name"]?.toString() ?? '',
        driverEmail: json["driver_email"]?.toString() ?? '',
        driverPhone: json["driver_phone"]?.toString() ?? '',
        driverAddress: json["driver_address"]?.toString() ?? '',
        dateOfJoin: DateTime.tryParse(json["date_of_join"]?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        driverCode: json["driver_code"]?.toString() ?? '',
        driverPin: json["driver_pin"]?.toString() ?? '',
        driverLicense: json["driver_license"]?.toString() ?? '',
        createdAt: DateTime.tryParse(json["created_at"]?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        updatedAt: DateTime.tryParse(json["updated_at"]?.toString() ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0),
        deletedAt: json["deleted_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "uuid": uuid,
        "branch_id": branchId,
        "driver_name": driverName,
        "driver_email": driverEmail,
        "driver_phone": driverPhone,
        "driver_address": driverAddress,
        "date_of_join": "${dateOfJoin.year.toString().padLeft(4, '0')}-${dateOfJoin.month.toString().padLeft(2, '0')}-${dateOfJoin.day.toString().padLeft(2, '0')}",
        "driver_code": driverCode,
        "driver_pin": driverPin,
        "driver_license": driverLicense,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
      };
}
