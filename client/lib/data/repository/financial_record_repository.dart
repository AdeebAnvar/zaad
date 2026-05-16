import 'package:pos/data/local/drift_database.dart';
import 'package:pos/domain/models/financial_record_type.dart';

class ExpenseCategoryOption {
  const ExpenseCategoryOption({
    required this.id,
    required this.name,
    required this.slug,
  });

  final int id;
  final String name;
  final String slug;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ExpenseCategoryOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class PaymentMethodOption {
  const PaymentMethodOption({
    required this.id,
    required this.name,
    required this.slug,
  });

  final int id;
  final String name;
  final String slug;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PaymentMethodOption && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

class NewFinancialRecordInput {
  const NewFinancialRecordInput({
    required this.type,
    this.expenseCategoryId,
    this.expenseCategoryName,
    this.expenseCategorySlug,
    this.paymentMethodId,
    this.paymentMethodName,
    this.companyName,
    this.companyTrn,
    this.invoiceNo,
    this.staffName,
    this.joiningDate,
    this.exitDate,
    this.days,
    this.description,
    this.amountBeforeVat = 0,
    this.vatAmount = 0,
    required this.finalAmount,
  });

  final FinancialRecordType type;
  final int? expenseCategoryId;
  final String? expenseCategoryName;
  final String? expenseCategorySlug;
  final int? paymentMethodId;
  final String? paymentMethodName;
  final String? companyName;
  final String? companyTrn;
  final String? invoiceNo;
  final String? staffName;
  final DateTime? joiningDate;
  final DateTime? exitDate;
  final int? days;
  final String? description;
  final double amountBeforeVat;
  final double vatAmount;
  final double finalAmount;
}

abstract class FinancialRecordRepository {
  Future<List<ExpenseCategoryOption>> getExpenseCategories(int branchId);

  Future<List<PaymentMethodOption>> getPaymentMethods(int branchId);

  Future<List<FinancialRecord>> listRecords({
    required int branchId,
    required FinancialRecordType type,
    DateTime? from,
    DateTime? to,
  });

  Future<void> saveRecord(NewFinancialRecordInput input);

  Future<double> sumSinceCheckpoint({
    required int branchId,
    required FinancialRecordType type,
    DateTime? after,
  });
}
