import 'package:drift/drift.dart';
import 'package:pos/core/sync/outbound_push_coordinator.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/financial_record_repository.dart';
import 'package:pos/domain/models/financial_record_type.dart';
import 'package:uuid/uuid.dart';

/// Reads expense categories / payment methods from local pull-sync tables
/// (`pull_records.expenseCategory`, `pull_records.paymentMethods`).
class FinancialRecordRepositoryImpl implements FinancialRecordRepository {
  FinancialRecordRepositoryImpl(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  @override
  Future<List<ExpenseCategoryOption>> getExpenseCategories(int branchId) async {
    final rows = await _db.pullDataDao.getExpenseCategoriesForBranch(branchId);
    final seen = <int>{};
    final out = <ExpenseCategoryOption>[];
    for (final r in rows) {
      if (!seen.add(r.id)) continue;
      final slug = r.categorySlug.trim();
      final name = _expenseCategoryLabel(
        storedName: r.categoryName,
        slug: slug,
        id: r.id,
      );
      if (name.isEmpty) continue;
      out.add(ExpenseCategoryOption(id: r.id, name: name, slug: slug));
    }
    return out;
  }

  /// Prefer real expense category names; avoid legacy pull rows that fell back to floor codes like "TA".
  static String _expenseCategoryLabel({
    required String storedName,
    required String slug,
    required int id,
  }) {
    final slugLabel = _humanizeSlug(slug);
    final name = storedName.trim();
    if (name.isEmpty) return slugLabel.isNotEmpty ? slugLabel : 'Category $id';
    if (name.length <= 3 && slugLabel.length > name.length) return slugLabel;
    return name;
  }

  static String _humanizeSlug(String slug) {
    if (slug.trim().isEmpty) return '';
    return slug
        .trim()
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w.length == 1 ? w.toUpperCase() : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  @override
  Future<List<PaymentMethodOption>> getPaymentMethods(int branchId) async {
    final rows = await _db.pullDataDao.getPaymentMethodsForBranch(branchId);
    return rows
        .map((r) {
          final name = (r.paymentMethodName ?? r.floorName ?? '').trim();
          final slug = (r.paymentMethodSlug ?? r.floorSlug ?? '').trim();
          return PaymentMethodOption(
            id: r.id,
            name: name.isNotEmpty ? name : 'Payment ${r.id}',
            slug: slug,
          );
        })
        .toList();
  }

  @override
  Future<List<FinancialRecord>> listRecords({
    required int branchId,
    required FinancialRecordType type,
    DateTime? from,
    DateTime? to,
  }) =>
      _db.financialRecordsDao.listForBranch(
        branchId: branchId,
        recordType: type.storageKey,
        from: from,
        to: to,
      );

  @override
  Future<void> saveRecord(NewFinancialRecordInput input) async {
    final session = await _db.sessionDao.getActiveSession();
    final branchId = session?.branchId ?? 1;
    final userId = session?.userId;

    await _db.financialRecordsDao.insertRecord(
      FinancialRecordsCompanion.insert(
        uuid: _uuid.v4(),
        branchId: branchId,
        recordType: input.type.storageKey,
        expenseCategoryId: Value(input.expenseCategoryId),
        expenseCategoryName: Value(input.expenseCategoryName),
        expenseCategorySlug: Value(input.expenseCategorySlug),
        paymentMethodId: Value(input.paymentMethodId),
        paymentMethodName: Value(input.paymentMethodName),
        companyName: Value(input.companyName),
        companyTrn: Value(input.companyTrn),
        invoiceNo: Value(input.invoiceNo),
        staffName: Value(input.staffName),
        joiningDate: Value(input.joiningDate),
        exitDate: Value(input.exitDate),
        days: Value(input.days),
        description: Value(input.description),
        amountBeforeVat: Value(input.amountBeforeVat),
        vatAmount: Value(input.vatAmount),
        finalAmount: input.finalAmount,
        userId: Value(userId),
      ),
    );
    scheduleOutboundPushAfterFinancialRecord();
  }

  @override
  Future<double> sumSinceCheckpoint({
    required int branchId,
    required FinancialRecordType type,
    DateTime? after,
  }) =>
      _db.financialRecordsDao.sumFinalAmount(
        branchId: branchId,
        recordType: type.storageKey,
        lastSettledAt: after,
      );
}
