import 'package:pos/domain/models/pagination_model.dart';

class TablesModel {
  final List<TablesCreatedUpdated> createdUpdated;
  final List<dynamic> deleted;
  final PaginationModel pagination;

  TablesModel({
    required this.createdUpdated,
    required this.deleted,
    required this.pagination,
  });

  TablesModel copyWith({
    List<TablesCreatedUpdated>? createdUpdated,
    List<dynamic>? deleted,
    PaginationModel? pagination,
  }) =>
      TablesModel(
        createdUpdated: createdUpdated ?? this.createdUpdated,
        deleted: deleted ?? this.deleted,
        pagination: pagination ?? this.pagination,
      );

  factory TablesModel.fromJson(Map<String, dynamic> json) => TablesModel(
        createdUpdated: (json["created_updated"] as List?)
                ?.map((x) => TablesCreatedUpdated.fromJson(Map<String, dynamic>.from(x as Map)))
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

class TablesCreatedUpdated {
  final int id;
  final String uuid;
  final int branchId;
  final int floorId;
  final String tableName;
  final String tableSlug;
  final int orderCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic deletedAt;

  TablesCreatedUpdated({
    required this.id,
    required this.uuid,
    required this.branchId,
    required this.floorId,
    required this.tableName,
    required this.tableSlug,
    required this.orderCount,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });

  TablesCreatedUpdated copyWith({
    int? id,
    String? uuid,
    int? branchId,
    int? floorId,
    String? tableName,
    String? tableSlug,
    int? orderCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    dynamic deletedAt,
  }) =>
      TablesCreatedUpdated(
        id: id ?? this.id,
        uuid: uuid ?? this.uuid,
        branchId: branchId ?? this.branchId,
        floorId: floorId ?? this.floorId,
        tableName: tableName ?? this.tableName,
        tableSlug: tableSlug ?? this.tableSlug,
        orderCount: orderCount ?? this.orderCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  factory TablesCreatedUpdated.fromJson(Map<String, dynamic> json) => TablesCreatedUpdated(
        id: (json["id"] as num?)?.toInt() ?? 0,
        uuid: json["uuid"]?.toString() ?? '',
        branchId: (json["branch_id"] as num?)?.toInt() ?? 0,
        floorId: (json["floor_id"] as num?)?.toInt() ?? 0,
        tableName: json["table_name"]?.toString() ?? '',
        tableSlug: json["table_slug"]?.toString() ?? '',
        orderCount: (json["order_count"] as num?)?.toInt() ?? 0,
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
        "floor_id": floorId,
        "table_name": tableName,
        "table_slug": tableSlug,
        "order_count": orderCount,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "deleted_at": deletedAt,
      };
}
