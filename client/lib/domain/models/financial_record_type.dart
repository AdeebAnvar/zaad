enum FinancialRecordType {
  expense('expense'),
  salary('salary'),
  otherIncome('other_income');

  const FinancialRecordType(this.storageKey);
  final String storageKey;

  static FinancialRecordType? fromStorage(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    for (final t in FinancialRecordType.values) {
      if (t.storageKey == s) return t;
    }
    return null;
  }
}
