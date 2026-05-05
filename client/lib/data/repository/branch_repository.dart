import 'package:pos/domain/models/branch_model.dart';

abstract class BranchRepository {
  /// When [downloadRemoteImages] is false (e.g. LAN SUB), skips HTTP and uses
  /// [BranchModel.localImage] only — supply paths from hub inline snapshots.
  Future<void> saveBranchesToLocal(List<BranchModel> brancModelList, {bool downloadRemoteImages = true});
}
