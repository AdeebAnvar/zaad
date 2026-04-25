import 'package:pos/domain/models/branch_model.dart';

abstract class BranchRepository {
  void saveBranchesToLocal(List<BranchModel> brancModelList);
}
