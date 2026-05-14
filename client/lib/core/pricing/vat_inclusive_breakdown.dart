/// VAT extracted from a **tax-inclusive** total (same formula as receipt / preview).
({double netBeforeVat, double vatAmount}) vatBreakdownFromInclusive(
  double totalInclusive, {
  required String vatMode,
  required dynamic vatPercentRaw,
}) {
  final mode = vatMode.trim().toLowerCase();
  final pct = vatPercentRaw is num ? vatPercentRaw.toDouble() : double.tryParse('$vatPercentRaw') ?? 0.0;
  if (mode == 'no_vat' || pct <= 0) {
    return (netBeforeVat: totalInclusive, vatAmount: 0.0);
  }
  final divisor = 1 + pct / 100.0;
  final net = totalInclusive / divisor;
  return (netBeforeVat: net, vatAmount: totalInclusive - net);
}
