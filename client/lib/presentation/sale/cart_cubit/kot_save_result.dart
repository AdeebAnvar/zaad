/// Result of [CartCubit.saveKOT] — persistence is complete; kitchen print may still run.
class KotSaveResult {
  const KotSaveResult({required Future<List<String>> printFuture})
      : _printFuture = printFuture;

  final Future<List<String>> _printFuture;

  /// Failed printer labels after background KOT print finishes (may be empty).
  Future<List<String>> get printFailures => _printFuture;
}
