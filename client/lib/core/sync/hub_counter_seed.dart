import 'package:pos/core/sync/hub_counter_client.dart';
import 'package:pos/core/utils/invoice_number_utils.dart';
import 'package:pos/core/utils/pickup_token_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/domain/models/branch_model.dart';

/// Pushes local max invoice suffix + pickup token to the LAN hub so SUB tablets
/// continue the same sequences after MAIN reconnect / hub restart.
Future<void> seedHubCountersFromLocalDb(AppDatabase db, {int? branchId}) async {
  if (branchId != null) {
    final branch = await db.branchesDao.getBranchById(branchId);
    if (branch == null) return;
    await _seedHubCounterForBranch(db, branch);
    return;
  }
  final branches = await db.branchesDao.getAllBranches();
  for (final branch in branches) {
    await _seedHubCounterForBranch(db, branch);
  }
}

Future<void> _seedHubCounterForBranch(AppDatabase db, BranchModel branch) async {
    final bid = branch.id;
    if (bid <= 0) return;
    final prefix = branch.prefixInv.trim().isNotEmpty
        ? branch.prefixInv.trim()
        : invoicePrefixForOrderType('take_away');

    final oMax =
        await db.ordersDao.maxInvoiceNumericSuffixForPrefix(prefix, branchId: bid);
    final cMax =
        await db.cartsDao.maxInvoiceNumericSuffixForPrefix(prefix, branchId: bid);
    final invoiceMax = oMax > cMax ? oMax : cMax;

    final tokenBaseline = await resolveLastPickupTokenBaseline(db, bid);
    final tokenMax = tokenBaseline > 0 ? tokenBaseline : (branch.lastTokenNo ?? 0);

    await HubCounterClient.seedFromLocalMax(
      branchId: bid,
      prefix: prefix,
      lastInvoiceSuffix: invoiceMax,
      lastPickupToken: tokenMax,
    );
}
