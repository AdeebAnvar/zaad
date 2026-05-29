part of '../drift_database.dart';

/// Local expense, salary, and other-income entries (synced via `push_records.expenses`).
class FinancialRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get uuid => text()();

  IntColumn get branchId => integer()();

  /// `expense` | `salary` | `other_income`
  TextColumn get recordType => text()();

  IntColumn get expenseCategoryId => integer().nullable()();
  TextColumn get expenseCategoryName => text().nullable()();
  TextColumn get expenseCategorySlug => text().nullable()();

  IntColumn get paymentMethodId => integer().nullable()();
  TextColumn get paymentMethodName => text().nullable()();

  TextColumn get companyName => text().nullable()();
  TextColumn get companyTrn => text().nullable()();
  TextColumn get invoiceNo => text().nullable()();

  TextColumn get staffName => text().nullable()();
  DateTimeColumn get joiningDate => dateTime().nullable()();
  DateTimeColumn get exitDate => dateTime().nullable()();
  IntColumn get days => integer().nullable()();

  TextColumn get description => text().nullable()();

  RealColumn get amountBeforeVat => real().withDefault(const Constant(0))();
  RealColumn get vatAmount => real().withDefault(const Constant(0))();
  RealColumn get finalAmount => real()();

  IntColumn get userId => integer().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}

@DriftAccessor(tables: [FinancialRecords])
class FinancialRecordsDao extends DatabaseAccessor<AppDatabase> with _$FinancialRecordsDaoMixin {
  FinancialRecordsDao(super.db);

  Future<int> insertRecord(FinancialRecordsCompanion row) => into(financialRecords).insert(row);

  Future<List<FinancialRecord>> listForBranch({
    required int branchId,
    required String recordType,
    DateTime? from,
    DateTime? to,
  }) {
    final q = select(financialRecords)
      ..where((t) => t.branchId.equals(branchId))
      ..where((t) => t.recordType.equals(recordType));
    if (from != null) {
      q.where((t) => t.createdAt.isBiggerOrEqualValue(from));
    }
    if (to != null) {
      q.where((t) => t.createdAt.isSmallerOrEqualValue(to));
    }
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.get();
  }

  /// Sum [finalAmount] for records after [lastSettledAt] (same window as day-closing sales).
  Future<double> sumFinalAmount({
    required int branchId,
    required String recordType,
    DateTime? lastSettledAt,
  }) async {
    final q = selectOnly(financialRecords)
      ..addColumns([financialRecords.finalAmount.sum()])
      ..where(financialRecords.branchId.equals(branchId))
      ..where(financialRecords.recordType.equals(recordType));
    if (lastSettledAt != null) {
      q.where(financialRecords.createdAt.isBiggerThanValue(lastSettledAt));
    }
    final row = await q.getSingleOrNull();
    return row?.read(financialRecords.finalAmount.sum()) ?? 0.0;
  }

  /// Rows since last day close (exclusive of [lastSettledAt], matching sales window).
  Future<List<FinancialRecord>> listSinceClose({
    required int branchId,
    required String recordType,
    DateTime? lastSettledAt,
  }) {
    final q = select(financialRecords)
      ..where((t) => t.branchId.equals(branchId))
      ..where((t) => t.recordType.equals(recordType));
    if (lastSettledAt != null) {
      q.where((t) => t.createdAt.isBiggerThanValue(lastSettledAt));
    }
    q.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return q.get();
  }

  Future<List<FinancialRecord>> getUnsyncedForBranch(int branchId) {
    return (select(financialRecords)
          ..where((t) => t.branchId.equals(branchId))
          ..where((t) => t.synced.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<void> markSynced(List<int> ids) async {
    if (ids.isEmpty) return;
    await (update(financialRecords)..where((t) => t.id.isIn(ids))).write(
      const FinancialRecordsCompanion(synced: Value(true)),
    );
  }

  /// Latest TRN per company name from expense rows (name + TRN both required).
  Future<List<({String name, String trn})>> listExpenseCompanySuggestions({
    required int branchId,
  }) async {
    final rows = await (select(financialRecords)
          ..where((t) => t.branchId.equals(branchId))
          ..where((t) => t.recordType.equals('expense'))
          ..where((t) => t.companyName.isNotNull())
          ..where((t) => t.companyTrn.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();

    final seen = <String>{};
    final out = <({String name, String trn})>[];
    for (final r in rows) {
      final name = r.companyName?.trim() ?? '';
      final trn = r.companyTrn?.trim() ?? '';
      if (name.isEmpty || trn.isEmpty) continue;
      final key = name.toLowerCase();
      if (!seen.add(key)) continue;
      out.add((name: name, trn: trn));
    }
    return out;
  }
}
