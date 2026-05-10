import 'package:pos/data/repository/branch_repository.dart';
import 'package:pos/domain/models/branch_model.dart';

import '../local/drift_database.dart';

class BranchRepositoryImpl implements BranchRepository {
  final AppDatabase db;
  BranchRepositoryImpl(this.db);
  @override
  Future<void> saveBranchesToLocal(List<BranchModel> brancModelList,
      {bool downloadRemoteImages = true}) async {
    final existingOpeningCashByBranch = {
      for (final branch in await db.branchesDao.getAllBranches())
        branch.id: branch.openingCash,
    };
    final branchesToSave = brancModelList
        .map(
          (branch) => branch.copyWith(
            openingCash:
                existingOpeningCashByBranch[branch.id] ?? branch.openingCash,
          ),
        )
        .toList();

    await db.delete(db.branches).go();

    await db.branchesDao.insertBranches(branchesToSave,
        downloadRemoteImages: downloadRemoteImages);
  }
}
