import 'package:pos/data/repository/branch_repository.dart';
import 'package:pos/domain/models/branch_model.dart';

import '../local/drift_database.dart';

class BranchRepositoryImpl implements BranchRepository {
  final AppDatabase db;
  BranchRepositoryImpl(this.db);
  @override
  Future<void> saveBranchesToLocal(List<BranchModel> brancModelList,
      {bool downloadRemoteImages = true}) async {
    final preservedOpening =
        await db.branchesDao.getPreservedOpeningCashByBranchId();
    final branchesToSave = brancModelList.map((branch) {
      final preserved = preservedOpening[branch.id];
      final effective = (preserved != null && preserved > 0)
          ? preserved
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
