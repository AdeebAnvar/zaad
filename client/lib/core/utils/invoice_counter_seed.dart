import 'package:pos/core/utils/invoice_number_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/domain/models/branch_model.dart';

/// After bootstrap / connect / hub snapshot, align local invoice counters with
/// server [BranchModel.lastReceipt]:
///
/// - `last_receipt` null/empty → no seed → next sale starts at `…-001`
/// - `last_receipt` `INV-4-1110` → next sale is `INV-4-1111` (last suffix + 1)
///
/// Inserts one sentinel cart at the last used invoice when local max is lower
/// (same idea as [tools/seed_invoice_counter.sql]).
Future<void> seedInvoiceCountersFromBranches(
  AppDatabase db,
  List<BranchModel> branches,
) async {
  for (final branch in branches) {
    await seedInvoiceCounterForBranchIfNeeded(db, branch);
  }
}

Future<void> seedInvoiceCounterForBranchIfNeeded(
  AppDatabase db,
  BranchModel branch,
) async {
  final raw = branch.lastReceipt?.trim() ?? '';
  if (raw.isEmpty) return;

  final parsed = parseBranchScopedInvoice(raw);
  if (parsed == null) return;
  if (parsed.branchId != branch.id) return;

  final prefix = branch.prefixInv.trim().isNotEmpty
      ? branch.prefixInv.trim()
      : parsed.prefix;
  final bid = branch.id;

  final oMax =
      await db.ordersDao.maxInvoiceNumericSuffixForPrefix(prefix, branchId: bid);
  final cMax =
      await db.cartsDao.maxInvoiceNumericSuffixForPrefix(prefix, branchId: bid);
  final localMax = oMax > cMax ? oMax : cMax;
  if (localMax >= parsed.suffix) return;

  final invoice = formatShortInvoice(prefix, bid, parsed.suffix);
  if (await db.cartsDao.getCartByInvoice(invoice) != null) return;

  await db.cartsDao.createCart(
    invoice,
    orderType: 'take_away',
    branchId: bid,
  );
}
