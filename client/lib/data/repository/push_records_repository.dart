/// Pushes local POS records to `POST /api/v1/push_records` (sales, credit_sales, settle_sales).
abstract class PushRecordsRepository {
  /// Reads unsynced [OrderLog]s, maps to API payload, POSTs, marks logs synced on 2xx.
  /// Includes pending day-closing rows in `settle_sales`. Returns counts for UI/logging.
  Future<PushRecordsOutcome> pushSalesAndCreditSalesFromLocal();
}

class PushRecordsOutcome {
  const PushRecordsOutcome({
    required this.ordersPosted,
    required this.creditRowsPosted,
    this.settleRowsPosted = 0,
    required this.httpStatus,
    this.message = '',
  });

  final int ordersPosted;
  final int creditRowsPosted;
  final int settleRowsPosted;
  final int? httpStatus;
  final String message;

  bool get ok => httpStatus != null && httpStatus! >= 200 && httpStatus! < 300;
}
