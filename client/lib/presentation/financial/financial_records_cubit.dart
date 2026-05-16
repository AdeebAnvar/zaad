import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/financial_record_repository.dart';
import 'package:pos/domain/models/financial_record_type.dart';
import 'package:pos/presentation/financial/financial_records_state.dart';

class FinancialRecordsCubit extends Cubit<FinancialRecordsState> {
  FinancialRecordsCubit(this._repo, this.config) : super(FinancialRecordsInitial());

  final FinancialRecordRepository _repo;
  final FinancialFormConfig config;

  DateTime _from = DateTime.now().copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
  DateTime _to = DateTime.now().copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);

  Future<void> load() async {
    emit(FinancialRecordsLoading());
    try {
      final db = locator<AppDatabase>();
      final session = await db.sessionDao.getActiveSession();
      final branchId = session?.branchId ?? 1;

      final categories = config.type == FinancialRecordType.expense
          ? await _repo.getExpenseCategories(branchId)
          : <ExpenseCategoryOption>[];
      final payments = await _repo.getPaymentMethods(branchId);
      final records = await _repo.listRecords(
        branchId: branchId,
        type: config.type,
        from: _from,
        to: _to,
      );

      emit(
        FinancialRecordsLoaded(
          records: records,
          expenseCategories: categories,
          paymentMethods: payments,
          from: _from,
          to: _to,
        ),
      );
    } catch (e) {
      emit(FinancialRecordsError('$e'));
    }
  }

  Future<void> setDateRange(DateTime from, DateTime to) async {
    _from = from;
    _to = to;
    await load();
  }

  void setFilterQuery(String query) {
    final s = state;
    if (s is! FinancialRecordsLoaded) return;
    emit(
      FinancialRecordsLoaded(
        records: s.records,
        expenseCategories: s.expenseCategories,
        paymentMethods: s.paymentMethods,
        from: s.from,
        to: s.to,
        filterQuery: query,
      ),
    );
  }

  Future<void> save(NewFinancialRecordInput input) async {
    await _repo.saveRecord(input);
    await load();
  }
}
