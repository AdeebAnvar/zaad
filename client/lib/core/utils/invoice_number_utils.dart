/// Single prefix for all channels (take away, dine in, delivery).
String invoicePrefixForOrderType(String orderType) {
  return 'INV';
}

/// Formats branch-scoped invoices like `INV-1-002`.
String formatShortInvoice(String prefix, int branchId, int n) {
  final normalizedBranchId = branchId > 0 ? branchId : 1;
  final suffix = n.toString().padLeft(3, '0');
  return '$prefix-$normalizedBranchId-$suffix';
}

/// Legacy fallback (should not be used for new carts when [OrderRepository.getNextInvoiceNumber] is available).
String generateInvoiceNumber() {
  final now = DateTime.now();
  final random = now.microsecondsSinceEpoch % 10000;
  return 'INV-${now.millisecondsSinceEpoch}-$random';
}
