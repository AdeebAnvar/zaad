import 'package:pos/data/local/drift_database.dart';
import 'package:pos/domain/models/branch_model.dart';

/// Resolves the last issued pickup token for [branchId] within the current business period.
///
/// Uses the higher of:
/// - max local [Orders.pickupToken] since [day close cutoff], and
/// - [BranchModel.lastTokenNo] from bootstrap / COMPANY_SNAPSHOT (when > 0).
Future<int> resolveLastPickupTokenBaseline(
  AppDatabase db,
  int branchId, {
  DateTime? createdAfterExclusive,
}) async {
  final after = createdAfterExclusive ??
      await db.dayClosingCheckpointDao.lastSettledAtForBranch(branchId);
  final maxLocal =
      await db.ordersDao.maxPickupTokenForBranchSince(branchId, after) ?? 0;
  final branch = await db.branchesDao.getBranchById(branchId);
  final serverSeed = branch?.lastTokenNo ?? 0;
  final baseline = serverSeed > 0 ? serverSeed : 0;
  return maxLocal > baseline ? maxLocal : baseline;
}

/// Next pickup token = [resolveLastPickupTokenBaseline] + 1.
Future<int> nextPickupTokenForBranch(AppDatabase db, int branchId) async {
  final lastUsed = await resolveLastPickupTokenBaseline(db, branchId);
  return lastUsed + 1;
}
