import 'package:pos/domain/models/branch_model.dart';

abstract class BranchRepository {
  Future<void> saveBranchesToLocal(List<BranchModel> brancModelList);
}
