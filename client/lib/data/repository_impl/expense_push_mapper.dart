import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository_impl/push_local_to_push_records_mapper.dart';
import 'package:pos/domain/models/financial_record_type.dart';

/// Maps local [FinancialRecord] rows to `push_records.expenses[]` elements.
///
/// All three modules (expense, salary, other income) share the `expenses` array;
/// [type] / [record_type] distinguishes them for the server.
class ExpensePushMapper {
  ExpensePushMapper._();

  static List<Map<String, dynamic>> mapRecords(List<FinancialRecord> rows) {
    return rows.map(_mapOne).toList();
  }

  static Map<String, dynamic> _mapOne(FinancialRecord r) {
    final ts = PushLocalToPushRecordsMapper.formatApiDateTime(r.createdAt);
    final amount = r.finalAmount;
    final type = r.recordType.trim().toLowerCase();
    final paymentTypeId = r.paymentMethodId;

    final base = <String, dynamic>{
      'uuid': r.uuid,
      'branch_id': r.branchId,
      'user_id': r.userId,
      'type': type,
      'record_type': type,
      'payment_type_id': paymentTypeId,
      'payment_method_id': paymentTypeId,
      'payment_method_name': r.paymentMethodName,
      'amount': amount,
      'final_amount': amount,
      'description': r.description,
      'created_at': ts,
      'updated_at': ts,
    };

    switch (FinancialRecordType.fromStorage(type)) {
      case FinancialRecordType.expense:
        base.addAll({
          'expense_category_id': r.expenseCategoryId,
          'expense_category_name': r.expenseCategoryName,
          'expense_category_slug': r.expenseCategorySlug,
          'company_name': r.companyName,
          'company_trn': r.companyTrn,
          'invoice_no': r.invoiceNo,
          'total_before_vat': r.amountBeforeVat,
          'amount_before_vat': r.amountBeforeVat,
          'vat_amount': r.vatAmount,
          'purchase': amount,
        });
      case FinancialRecordType.salary:
        base.addAll({
          'staff_name': r.staffName,
          'joining_date': r.joiningDate != null
              ? PushLocalToPushRecordsMapper.formatApiDateTime(r.joiningDate!)
              : null,
          'exit_date':
              r.exitDate != null ? PushLocalToPushRecordsMapper.formatApiDateTime(r.exitDate!) : null,
          'days': r.days,
          'salary': amount,
        });
      case FinancialRecordType.otherIncome:
        base.addAll({
          'other_income': amount,
          'source': r.description,
        });
      case null:
        break;
    }

    return base;
  }
}
