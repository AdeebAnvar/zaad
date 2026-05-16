import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/financial_record_repository.dart';
import 'package:pos/domain/models/financial_record_type.dart';

sealed class FinancialRecordsState {}

class FinancialRecordsInitial extends FinancialRecordsState {}

class FinancialRecordsLoading extends FinancialRecordsState {}

class FinancialRecordsLoaded extends FinancialRecordsState {
  FinancialRecordsLoaded({
    required this.records,
    required this.expenseCategories,
    required this.paymentMethods,
    required this.from,
    required this.to,
    this.filterQuery = '',
  });

  final List<FinancialRecord> records;
  final List<ExpenseCategoryOption> expenseCategories;
  final List<PaymentMethodOption> paymentMethods;
  final DateTime from;
  final DateTime to;
  final String filterQuery;

  List<FinancialRecord> get filteredRecords {
    final q = filterQuery.trim().toLowerCase();
    if (q.isEmpty) return records;
    return records.where((r) {
      final haystack = [
        r.expenseCategoryName,
        r.companyName,
        r.invoiceNo,
        r.staffName,
        r.description,
        r.paymentMethodName,
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }
}

class FinancialRecordsError extends FinancialRecordsState {
  FinancialRecordsError(this.message);
  final String message;
}

class FinancialFormConfig {
  const FinancialFormConfig({
    required this.type,
    required this.screenTitle,
    required this.logTitle,
    required this.logSubtitle,
    required this.createDialogTitle,
    required this.addButtonLabel,
    required this.emptyMessage,
  });

  final FinancialRecordType type;
  final String screenTitle;
  final String logTitle;
  final String logSubtitle;
  final String createDialogTitle;
  final String addButtonLabel;
  final String emptyMessage;

  static const expense = FinancialFormConfig(
    type: FinancialRecordType.expense,
    screenTitle: 'Expense',
    logTitle: 'Expense Log',
    logSubtitle: 'View and monitor daily expenses',
    createDialogTitle: 'CREATE EXPENSE',
    addButtonLabel: 'Add Expense',
    emptyMessage: 'NO RECORDS FOUND',
  );

  static const salary = FinancialFormConfig(
    type: FinancialRecordType.salary,
    screenTitle: 'Salary',
    logTitle: 'Salary Log',
    logSubtitle: 'View and monitor staff salary payments',
    createDialogTitle: 'CREATE SALARY',
    addButtonLabel: 'Add Salary',
    emptyMessage: 'NO RECORDS FOUND',
  );

  static const otherIncome = FinancialFormConfig(
    type: FinancialRecordType.otherIncome,
    screenTitle: 'Other Income',
    logTitle: 'Other Income Log',
    logSubtitle: 'View and monitor other income records',
    createDialogTitle: 'RECORD OTHER INCOME',
    addButtonLabel: 'Record Other Income',
    emptyMessage: 'NO RECORDS FOUND',
  );
}
