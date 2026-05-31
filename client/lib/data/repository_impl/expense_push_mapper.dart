import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository_impl/push_local_to_push_records_mapper.dart';
import 'package:pos/domain/models/financial_record_type.dart';
import 'package:uuid/uuid.dart';

/// Maps local [FinancialRecord] rows to `push_records.expenses[]` elements.
class ExpensePushMapper {
  ExpensePushMapper._();

  static const Uuid _uuid = Uuid();

  static List<Map<String, dynamic>> mapRecords(List<FinancialRecord> rows) {
    return rows.map(_mapOne).toList();
  }

  static Map<String, dynamic> _mapOne(FinancialRecord r) {
    return switch (FinancialRecordType.fromStorage(r.recordType)) {
      FinancialRecordType.expense => _mapExpense(r),
      FinancialRecordType.salary => _mapSalary(r),
      FinancialRecordType.otherIncome => _mapOtherIncome(r),
      null => _mapLegacy(r),
    };
  }

  /// Server contract for `push_records.expenses[]` when `type` is `expense`.
  static Map<String, dynamic> _mapExpense(FinancialRecord r) {
    final ts = PushLocalToPushRecordsMapper.formatApiDateTime(r.createdAt);
    final uuid = _resolveUuid(r.uuid);
    return <String, dynamic>{
      'uuid': uuid,
      'expense_cat_id': _asRequiredIdString(r.expenseCategoryId),
      'invoice_no': _nullIfBlank(r.invoiceNo),
      'company_name': _nullIfBlank(r.companyName),
      'company_trn': _nullIfBlank(r.companyTrn),
      'description': _nullIfBlank(r.description),
      'total_before_vat': r.amountBeforeVat,
      'vat': r.vatAmount,
      'total_amount': r.finalAmount,
      'payment_type_id': _asRequiredIdString(r.paymentMethodId),
      'user_id': _asRequiredIdString(r.userId),
      'branch_id': _asRequiredIdString(r.branchId),
      'created_at': ts,
    };
  }

  static Map<String, dynamic> _mapSalary(FinancialRecord r) {
    final ts = PushLocalToPushRecordsMapper.formatApiDateTime(r.createdAt);
    final amount = r.finalAmount;
    return <String, dynamic>{
      'uuid': _resolveUuid(r.uuid),
      'branch_id': r.branchId,
      'user_id': r.userId,
      'type': FinancialRecordType.salary.storageKey,
      'record_type': FinancialRecordType.salary.storageKey,
      'payment_type_id': r.paymentMethodId,
      'payment_method_id': r.paymentMethodId,
      'payment_method_name': r.paymentMethodName,
      'amount': amount,
      'final_amount': amount,
      'description': r.description,
      'staff_name': r.staffName,
      'joining_date': r.joiningDate != null
          ? PushLocalToPushRecordsMapper.formatApiDateTime(r.joiningDate!)
          : null,
      'exit_date':
          r.exitDate != null ? PushLocalToPushRecordsMapper.formatApiDateTime(r.exitDate!) : null,
      'days': r.days,
      'salary': amount,
      'created_at': ts,
      'updated_at': ts,
    };
  }

  static Map<String, dynamic> _mapOtherIncome(FinancialRecord r) {
    final ts = PushLocalToPushRecordsMapper.formatApiDateTime(r.createdAt);
    final amount = r.finalAmount;
    return <String, dynamic>{
      'uuid': _resolveUuid(r.uuid),
      'branch_id': r.branchId,
      'user_id': r.userId,
      'type': FinancialRecordType.otherIncome.storageKey,
      'record_type': FinancialRecordType.otherIncome.storageKey,
      'payment_type_id': r.paymentMethodId,
      'payment_method_id': r.paymentMethodId,
      'payment_method_name': r.paymentMethodName,
      'amount': amount,
      'final_amount': amount,
      'description': r.description,
      'other_income': amount,
      'source': r.description,
      'created_at': ts,
      'updated_at': ts,
    };
  }

  static Map<String, dynamic> _mapLegacy(FinancialRecord r) {
    final ts = PushLocalToPushRecordsMapper.formatApiDateTime(r.createdAt);
    final amount = r.finalAmount;
    final type = r.recordType.trim().toLowerCase();
    return <String, dynamic>{
      'uuid': _resolveUuid(r.uuid),
      'branch_id': r.branchId,
      'user_id': r.userId,
      'type': type,
      'record_type': type,
      'payment_type_id': r.paymentMethodId,
      'payment_method_id': r.paymentMethodId,
      'payment_method_name': r.paymentMethodName,
      'amount': amount,
      'final_amount': amount,
      'description': r.description,
      'created_at': ts,
      'updated_at': ts,
    };
  }

  static String _resolveUuid(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isNotEmpty) return trimmed;
    return _uuid.v4();
  }

  static String? _nullIfBlank(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  static String _asRequiredIdString(int? id) => '${id ?? 0}';
}
