import 'package:pos/data/repository/branch_repository.dart';
import 'package:pos/domain/models/branch_model.dart';

import '../local/drift_database.dart';

class BranchRepositoryImpl implements BranchRepository {
  final AppDatabase db;
  BranchRepositoryImpl(this.db);
  @override
  Future<void> saveBranchesToLocal(List<BranchModel> brancModelList) async {
    await db.delete(db.branches).go();

    await db.branchesDao.insertBranches(brancModelList);
  }
}
