/// Parsed `PREFIX-branchId-suffix` invoice (e.g. `INV-4-1155`).
class ParsedBranchInvoice {
  const ParsedBranchInvoice({
    required this.prefix,
    required this.branchId,
    required this.suffix,
  });

  final String prefix;
  final int branchId;
  final int suffix;
}

/// Parses branch-scoped invoices like `INV-4-1155`. Returns null when unrecognized.
ParsedBranchInvoice? parseBranchScopedInvoice(String? raw) {
  final s = raw?.trim() ?? '';
  if (s.isEmpty) return null;
  final match = RegExp(r'^([A-Za-z0-9]+)-(\d+)-(\d+)$').firstMatch(s);
  if (match == null) return null;
  final branchId = int.tryParse(match.group(2)!);
  final suffix = int.tryParse(match.group(3)!);
  if (branchId == null || branchId <= 0 || suffix == null || suffix <= 0) {
    return null;
  }
  return ParsedBranchInvoice(
    prefix: match.group(1)!,
    branchId: branchId,
    suffix: suffix,
  );
}

/// Single prefix for all channels (take away, dine in, delivery).
String invoicePrefixForOrderType(String orderType) {
  return 'INV';
}

/// Formats branch-scoped invoices like `INV-1-002`.
String formatShortInvoice(String prefix, int branchId, int n) {
  if (branchId <= 0) {
    throw ArgumentError.value(branchId, 'branchId', 'must be a positive branch id');
  }
  final normalizedBranchId = branchId;
  final suffix = n.toString().padLeft(3, '0');
  return '$prefix-$normalizedBranchId-$suffix';
}

/// Placeholder on [Carts] until KOT / payment — must not match [formatShortInvoice] pattern.
String draftCartInvoiceForId(int cartId) => '_draft-$cartId';

/// True for in-progress counter carts (excluded from invoice MAX suffix queries).
bool isDraftCartInvoice(String? raw) {
  final s = raw?.trim() ?? '';
  return s == '_draft-pending' || s.startsWith('_draft-');
}

/// Legacy fallback (should not be used for new carts when [OrderRepository.getNextInvoiceNumber] is available).
String generateInvoiceNumber() {
  final now = DateTime.now();
  final random = now.microsecondsSinceEpoch % 10000;
  return 'INV-${now.millisecondsSinceEpoch}-$random';
}
