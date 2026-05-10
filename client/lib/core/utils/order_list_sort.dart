import 'package:pos/data/local/drift_database.dart';

/// Newest first: [Order.createdAt] descending, then [Order.id] descending.
int compareOrdersNewestFirst(Order a, Order b) {
  final byTime = b.createdAt.compareTo(a.createdAt);
  if (byTime != 0) return byTime;
  return b.id.compareTo(a.id);
}

/// Sort [orders] in place (newest first).
void sortOrdersNewestFirst(List<Order> orders) {
  orders.sort(compareOrdersNewestFirst);
}
