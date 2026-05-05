part of '../drift_database.dart';

/// Pending `settle_sales` rows for POST `/api/v1/push_records` (retry until synced).
class SettleSalesOutbox extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text()();

  IntColumn get branchId => integer()();

  /// Full API object JSON for one settle_sales element.
  TextColumn get payloadJson => text()();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftAccessor(tables: [SettleSalesOutbox])
class SettleSalesOutboxDao extends DatabaseAccessor<AppDatabase>
    with _$SettleSalesOutboxDaoMixin {
  SettleSalesOutboxDao(super.db);

  Future<int> insertPending(SettleSalesOutboxCompanion row) =>
      into(settleSalesOutbox).insert(row);

  Future<List<SettleSalesOutboxData>> getUnsyncedForBranch(int branchId) {
    return (select(settleSalesOutbox)
          ..where((t) => t.synced.equals(false))
          ..where((t) => t.branchId.equals(branchId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> markSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    await (update(settleSalesOutbox)..where((t) => t.id.isIn(ids))).write(
      SettleSalesOutboxCompanion(synced: Value(true)),
    );
  }
}
