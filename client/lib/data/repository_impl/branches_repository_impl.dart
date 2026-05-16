import 'package:pos/data/repository/branch_repository.dart';
import 'package:pos/domain/models/branch_model.dart';

import '../local/drift_database.dart';

class BranchRepositoryImpl implements BranchRepository {
  final AppDatabase db;
  BranchRepositoryImpl(this.db);
  @override
  Future<void> saveBranchesToLocal(List<BranchModel> brancModelList,
      {bool downloadRemoteImages = true}) async {
    final existingBranches = await db.branchesDao.getAllBranches();
    final existingOpeningCashByBranch = {
      for (final branch in existingBranches) branch.id: branch.openingCash,
    };
    final existingDefaultOpeningCashByBranch = {
      for (final branch in existingBranches) branch.id: branch.defaultOpeningCash,
    };
    final branchesToSave = brancModelList.map((branch) {
      final localDefault = existingDefaultOpeningCashByBranch[branch.id];
      final localOpening = existingOpeningCashByBranch[branch.id];
      final effective = (localDefault != null && localDefault > 0)
          ? localDefault
          : (localOpening != null && localOpening > 0)
              ? localOpening
              : (branch.defaultOpeningCash ?? branch.openingCash ?? 0);
      return branch.copyWith(
        openingCash: effective,
        defaultOpeningCash: effective,
      );
    }).toList();

    await db.delete(db.branches).go();

    await db.branchesDao.insertBranches(branchesToSave,
        downloadRemoteImages: downloadRemoteImages);
  }
}
