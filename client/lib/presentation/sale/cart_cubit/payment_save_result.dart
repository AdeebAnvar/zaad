/// Result of checkout Pay — order row is persisted; print / drawer may still run.
class PaymentSaveResult {
  const PaymentSaveResult({required Future<List<String>> printFuture})
      : _printFuture = printFuture;

  final Future<List<String>> _printFuture;

  Future<List<String>> get printFailures => _printFuture;
}
