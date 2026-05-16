import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/financial_record_repository.dart';
import 'package:pos/data/repository_impl/financial_record_repository_impl.dart';
import 'package:pos/domain/models/financial_record_type.dart';
import 'package:pos/presentation/financial/financial_form_dialogs.dart';
import 'package:pos/presentation/financial/financial_records_state.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';

/// Opens create expense / salary / other income as an overlay (same pattern as cash drawer).
///
/// Category / payment dropdowns use data already synced from `pull_records`
/// (`expenseCategory`, `paymentMethods`) — no extra API call.
Future<void> showFinancialCreatePopup(
  BuildContext context,
  FinancialFormConfig config,
) async {
  final db = locator<AppDatabase>();
  final repo = FinancialRecordRepositoryImpl(db);
  final session = await db.sessionDao.getActiveSession();
  final branchId = session?.branchId ?? 1;

  List<ExpenseCategoryOption> categories = const [];
  if (config.type == FinancialRecordType.expense) {
    categories = await repo.getExpenseCategories(branchId);
    if (categories.isEmpty && context.mounted) {
      CustomSnackBar.showWarning(
        message: 'No expense categories found. Run sync (pull) to load categories from the server.',
      );
    }
  }
  final paymentMethods = await repo.getPaymentMethods(branchId);
  if (paymentMethods.isEmpty && context.mounted) {
    CustomSnackBar.showWarning(
      message: 'No payment methods found. Run sync (pull) to load payment types from the server.',
    );
  }

  if (!context.mounted) return;

  await showFinancialCreateDialog(
    context: context,
    config: config,
    categories: categories,
    paymentMethods: paymentMethods,
    onSave: (input) => repo.saveRecord(input),
  );
}
