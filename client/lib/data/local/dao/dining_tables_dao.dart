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
  DiningTablesDao(AppDatabase db) : super(db);

  Future<void> upsertFloor(DiningFloorsCompanion data) => into(diningFloors).insertOnConflictUpdate(data);

  Future<void> upsertTable(DiningTablesCompanion data) => into(diningTables).insertOnConflictUpdate(data);

  Future<List<DiningFloor>> getFloors() => (select(diningFloors)..orderBy([(f) => OrderingTerm.asc(f.sortOrder), (f) => OrderingTerm.asc(f.id)])).get();

  Future<List<DiningTable>> getTablesByFloor(int floorId) => (select(diningTables)
        ..where((t) => t.floorId.equals(floorId))
        ..orderBy([(t) => OrderingTerm.asc(t.code)]))
      .get();

  Future<List<DiningTable>> getAllDiningTables() => select(diningTables).get();
}
