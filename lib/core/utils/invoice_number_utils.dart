/// Prefix per channel: Take away `TA`, Dine in `DI`, Delivery `DL`.
String invoicePrefixForOrderType(String orderType) {
  switch (orderType) {
    case 'dine_in':
      return 'DI';
    case 'delivery':
      return 'DL';
    default:
      return 'TA';
  }
}

/// Formats `TA01`, `DL12`; expands past 99 without padding (`TA100`).
String formatShortInvoice(String prefix, int n) {
  if (n < 100) {
    return '$prefix${n.toString().padLeft(2, '0')}';
  }
  return '$prefix$n';
}

/// Legacy fallback (should not be used for new carts when [OrderRepository.getNextInvoiceNumber] is available).
String generateInvoiceNumber() {
  final now = DateTime.now();
  final random = now.microsecondsSinceEpoch % 10000;
  return 'INV-${now.millisecondsSinceEpoch}-$random';
}
