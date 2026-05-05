import 'package:flutter/foundation.dart';
import 'package:pos/data/local/drift_database.dart';

/// Trims and removes trailing slashes so two equivalent roots compare equal.
String? normalizedTenantBaseUrl(String? raw) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty) return null;
  var s = t;
  while (s.endsWith('/')) {
    s = s.substring(0, s.length - 1);
  }
  return s.isEmpty ? null : s;
}

/// After a **different** tenant REST base URL is saved, remove local data that
/// would mix with the new company (orders, sync queues, catalog mirrors, etc.).
/// Does **not** touch [Users], [Branches], or [Settings] — those are replaced by connect.
Future<void> clearLocalDataForNewTenant(AppDatabase db) async {
  await db.transaction(() async {
    await db.delete(db.cartItems).go();
    await db.delete(db.orderLogs).go();
    await db.delete(db.orders).go();
    await db.delete(db.carts).go();

    await db.delete(db.customers).go();
    await db.delete(db.pendingActions).go();
    await db.delete(db.syncOutbox).go();
    await db.delete(db.syncInbox).go();
    await db.delete(db.settleSalesOutbox).go();
    await db.delete(db.dayClosingCheckpoint).go();
    await db.delete(db.sessions).go();

    await db.delete(db.syncPaginationStates).go();
    await db.delete(db.pullCategoryRows).go();
    await db.delete(db.pullFloorRows).go();
    await db.delete(db.pullDeliveryServiceRows).go();
    await db.delete(db.pullItemRows).go();

    await db.delete(db.itemToppings).go();
    await db.delete(db.toppingGroups).go();
    await db.delete(db.itemVariants).go();
    await db.delete(db.items).go();

    await db.delete(db.kitchenPrinters).go();
    await db.delete(db.kitchens).go();
    await db.delete(db.categories).go();

    await db.delete(db.deliveryPartners).go();
    await db.delete(db.drivers).go();
    await db.delete(db.diningTables).go();
    await db.delete(db.diningFloors).go();
  });
  if (kDebugMode) {
    debugPrint('[tenant_switch] cleared transactional + catalog + sync state for new tenant base URL');
  }
}
