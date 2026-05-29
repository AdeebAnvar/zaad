/// Pushes local POS records to `POST /api/v1/push_records` (sales, credit_sales, expenses, settle_sales).
abstract class PushRecordsRepository {
  /// Reads unsynced [OrderLog]s, financial records, customers; POSTs; marks synced on 2xx.
  Future<PushRecordsOutcome> pushSalesAndCreditSalesFromLocal();
}

class PushRecordsOutcome {
  const PushRecordsOutcome({
    required this.ordersPosted,
    required this.creditRowsPosted,
    this.settleRowsPosted = 0,
    this.expensesPosted = 0,
    required this.httpStatus,
    this.message = '',
  });

  final int ordersPosted;
  final int creditRowsPosted;
  final int settleRowsPosted;

  /// Expense + salary + other income rows in `expenses[]`.
  final int expensesPosted;
  final int? httpStatus;
  final String message;

  bool get ok => httpStatus != null && httpStatus! >= 200 && httpStatus! < 300;
}
