import 'package:pos/domain/models/pagination_model.dart';

class DeliveryServiceModel {
  final List<DeliveryServiceCreatedUpdated> createdUpdated;
  final List<dynamic> deleted;
  final PaginationModel pagination;

  DeliveryServiceModel({
    required this.createdUpdated,
    required this.deleted,
    required this.pagination,
  });

  DeliveryServiceModel copyWith({
    List<DeliveryServiceCreatedUpdated>? createdUpdated,
    List<dynamic>? deleted,
    PaginationModel? pagination,
  }) =>
      DeliveryServiceModel(
        createdUpdated: createdUpdated ?? this.createdUpdated,
        deleted: deleted ?? this.deleted,
        pagination: pagination ?? this.pagination,
      );

  factory DeliveryServiceModel.fromJson(Map<String, dynamic> json) => DeliveryServiceModel(
        createdUpdated: (json["created_updated"] as List?)
                ?.map((x) => DeliveryServiceCreatedUpdated.fromJson(Map<String, dynamic>.from(x as Map)))
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

class DeliveryServiceCreatedUpdated {
  final int id;
  final String uuid;
  final int branchId;
  final String serviceName;
  final String serviceNameSlug;
  final dynamic driverStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic deletedAt;

  DeliveryServiceCreatedUpdated({
    required this.id,
    required this.uuid,
    required this.branchId,
    required this.serviceName,
    required this.serviceNameSlug,
    required this.driverStatus,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  DeliveryServiceCreatedUpdated copyWith({
    int? id,
    String? uuid,
    int? branchId,
    String? serviceName,
    String? serviceNameSlug,
    dynamic driverStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    dynamic deletedAt,
  }) =>
      DeliveryServiceCreatedUpdated(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        branchId: branchId ?? this.branchId,
        serviceName: serviceName ?? this.serviceName,
        serviceNameSlug: serviceNameSlug ?? this.serviceNameSlug,
        driverStatus: driverStatus ?? this.driverStatus,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  factory DeliveryServiceCreatedUpdated.fromJson(Map<String, dynamic> json) => DeliveryServiceCreatedUpdated(
        id: (json["id"] as num?)?.toInt() ?? 0,
        uuid: json["uuid"]?.toString() ?? '',
        branchId: (json["branch_id"] as num?)?.toInt() ?? 0,
        serviceName: json["service_name"]?.toString() ?? '',
        serviceNameSlug: json["service_name_slug"]?.toString() ?? '',
        driverStatus: json["driver_status"],
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
        "service_name": serviceName,
        "service_name_slug": serviceNameSlug,
        "driver_status": driverStatus,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
      };
}
