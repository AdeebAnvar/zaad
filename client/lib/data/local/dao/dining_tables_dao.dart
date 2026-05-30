part of '../drift_database.dart';

class DiningFloors extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  /// [FloorsCreatedUpdated] when [PullDataModel.floors] represents dine-in floor
  TextColumn get recordUuid => text().nullable()();
  IntColumn get branchId => integer().nullable()();
  TextColumn get floorSlug => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class DiningTables extends Table {
  IntColumn get id => integer()();
  IntColumn get floorId => integer().references(DiningFloors, #id)();
  TextColumn get code => text()();
  IntColumn get chairs => integer().withDefault(const Constant(4))();
  TextColumn get status => text().withDefault(const Constant('free'))(); // free | allocated
  /// [TablesCreatedUpdated] from [TableSyncResponse]
  TextColumn get recordUuid => text().nullable()();
  IntColumn get branchId => integer().nullable()();
  /// Maps to API `table_name` from [TablesCreatedUpdated]; column cannot be named `tableName` (Drift reserved).
  TextColumn get pulledTableName => text().nullable()();
  TextColumn get pulledTableSlug => text().nullable()();
  IntColumn get orderCount => integer().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [DiningFloors, DiningTables])
class DiningTablesDao extends DatabaseAccessor<AppDatabase> with _$DiningTablesDaoMixin {
  DiningTablesDao(super.db);

  Future<void> upsertFloor(DiningFloorsCompanion data) => into(diningFloors).insertOnConflictUpdate(data);

  Future<void> upsertTable(DiningTablesCompanion data) => into(diningTables).insertOnConflictUpdate(data);

  Future<List<DiningFloor>> getFloors() => (select(diningFloors)
        ..where((f) => f.deletedAt.isNull())
        ..orderBy([(f) => OrderingTerm.asc(f.sortOrder), (f) => OrderingTerm.asc(f.id)]))
      .get();

  Future<List<DiningFloor>> getFloorsForBranch(int branchId) {
    return (select(diningFloors)
          ..where((f) => f.branchId.equals(branchId) | f.branchId.isNull())
          ..where((f) => f.deletedAt.isNull())
          ..orderBy([(f) => OrderingTerm.asc(f.sortOrder), (f) => OrderingTerm.asc(f.id)]))
        .get();
  }

  Future<List<DiningTable>> getTablesByFloor(int floorId) => (select(diningTables)
        ..where((t) => t.floorId.equals(floorId))
        ..where((t) => t.deletedAt.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.code)]))
      .get();

  Future<List<DiningTable>> getTablesByFloorForBranch(int floorId, int branchId) {
    return (select(diningTables)
          ..where((t) => t.floorId.equals(floorId))
          ..where((t) => t.branchId.equals(branchId) | t.branchId.isNull())
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.code)]))
        .get();
  }

  Future<List<DiningTable>> getAllDiningTables() => (select(diningTables)..where((t) => t.deletedAt.isNull())).get();

  Future<List<DiningTable>> getAllDiningTablesForBranch(int branchId) {
    return (select(diningTables)
          ..where((t) => t.branchId.equals(branchId) | t.branchId.isNull())
          ..where((t) => t.deletedAt.isNull()))
        .get();
  }

  /// Replaces dine-in layout on SUB after MAIN pull (removes stale tables MAIN no longer has).
  Future<void> applyFloorPlanSnapshot({
    required int branchId,
    required List<Map<String, dynamic>> floors,
    required List<Map<String, dynamic>> tables,
  }) async {
    await transaction(() async {
      final keepFloorIds = <int>{};
      for (final raw in floors) {
        final id = _coerceInt(raw['id']);
        if (id == null) continue;
        keepFloorIds.add(id);
        await upsertFloor(
          DiningFloorsCompanion.insert(
            id: Value(id),
            name: (raw['name'] ?? 'Floor').toString(),
            sortOrder: Value(_coerceInt(raw['sort_order'] ?? raw['sortOrder']) ?? 0),
            recordUuid: Value(raw['record_uuid']?.toString() ?? raw['recordUuid']?.toString()),
            branchId: Value(_coerceInt(raw['branch_id'] ?? raw['branchId']) ?? branchId),
            floorSlug: Value(raw['floor_slug']?.toString() ?? raw['floorSlug']?.toString()),
            deletedAt: const Value(null),
          ),
        );
      }

      final keepTableIds = <int>{};
      for (final raw in tables) {
        final id = _coerceInt(raw['id']);
        final floorId = _coerceInt(raw['floor_id'] ?? raw['floorId']);
        if (id == null || floorId == null) continue;
        keepTableIds.add(id);
        final code = (raw['code'] ?? raw['table_name'] ?? raw['tableName'] ?? '').toString().trim();
        if (code.isEmpty) continue;
        await upsertTable(
          DiningTablesCompanion.insert(
            id: Value(id),
            floorId: floorId,
            code: code,
            chairs: Value(_coerceInt(raw['chairs']) ?? 4),
            status: Value((raw['status'] ?? 'free').toString()),
            recordUuid: Value(raw['record_uuid']?.toString() ?? raw['recordUuid']?.toString()),
            branchId: Value(_coerceInt(raw['branch_id'] ?? raw['branchId']) ?? branchId),
            pulledTableName: Value(raw['table_name']?.toString() ?? raw['tableName']?.toString()),
            pulledTableSlug: Value(raw['table_slug']?.toString() ?? raw['tableSlug']?.toString()),
            orderCount: Value(_coerceInt(raw['order_count'] ?? raw['orderCount'])),
            deletedAt: const Value(null),
          ),
        );
      }

      final existingTables = await getAllDiningTablesForBranch(branchId);
      for (final t in existingTables) {
        if (!keepTableIds.contains(t.id)) {
          await (delete(diningTables)..where((x) => x.id.equals(t.id))).go();
        }
      }

      final existingFloors = await (select(diningFloors)
            ..where((f) => f.branchId.equals(branchId) | f.branchId.isNull())
            ..where((f) => f.deletedAt.isNull()))
          .get();
      for (final f in existingFloors) {
        if (!keepFloorIds.contains(f.id)) {
          await (delete(diningTables)..where((x) => x.floorId.equals(f.id))).go();
          await (delete(diningFloors)..where((x) => x.id.equals(f.id))).go();
        }
      }
    });
  }

  static int? _coerceInt(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }
}
