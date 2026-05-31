part of '../drift_database.dart';

/// Local-only “day closed” watermark per branch — excludes older orders from day closing aggregates.
class DayClosingCheckpoint extends Table {
  IntColumn get branchId => integer()();

  DateTimeColumn get lastSettledAt => dateTime()();

  @override
  Set<Column> get primaryKey => {branchId};
}

@DriftAccessor(tables: [DayClosingCheckpoint])
class DayClosingCheckpointDao extends DatabaseAccessor<AppDatabase>
    with _$DayClosingCheckpointDaoMixin {
  DayClosingCheckpointDao(super.db);

  Future<DateTime?> lastSettledAtForBranch(int branchId) async {
    final row = await (select(dayClosingCheckpoint)
          ..where((t) => t.branchId.equals(branchId)))
        .getSingleOrNull();
    return row?.lastSettledAt;
  }

  Future<void> upsertLastSettledAt(int branchId, DateTime at) async {
    await into(dayClosingCheckpoint).insertOnConflictUpdate(
      DayClosingCheckpointCompanion(
        branchId: Value(branchId),
        lastSettledAt: Value(at),
      ),
    );
  }

  Stream<DateTime?> watchLastSettledAtForBranch(int branchId) {
    return (select(dayClosingCheckpoint)..where((t) => t.branchId.equals(branchId)))
        .watch()
        .map((rows) => rows.isEmpty ? null : rows.single.lastSettledAt);
  }
}
