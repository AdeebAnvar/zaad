import 'package:pos/data/repository/branch_repository.dart';
import 'package:pos/data/repository/pull_data_repository.dart';
import 'package:pos/data/repository/settings_repository.dart';
import 'package:pos/data/repository/user_repository.dart';
import 'package:pos/domain/models/branch_model.dart';
import 'package:pos/domain/models/category_model.dart';
import 'package:pos/domain/models/item_model.dart';
import 'package:pos/domain/models/pull_data_model.dart';
import 'package:pos/domain/models/settings_model.dart';
import 'package:pos/domain/models/user_model.dart';

class StubPullDataRepository implements PullDataRepository {
  @override
  Stream<PullSyncProgress> get progressStream => const Stream.empty();

  @override
  bool get pendingDeferredLanHubMirror => false;

  @override
  Future<PullData> pullAndPersist({bool deferLanHubMirrorUntilAfterCloudSync = false}) =>
      throw UnimplementedError();

  @override
  Future<void> runDeferredLanHubMirrorBestEffort() => throw UnimplementedError();

  @override
  Future<void> upsertLanHubItemSnapshot(ItemCreatedUpdated item, {String? localImagePath}) =>
      throw UnimplementedError();

  @override
  Future<void> upsertLanHubCategory(CategoryCreatedUpdated category) => throw UnimplementedError();

  @override
  Future<void> applyMirroredPullPage(dynamic responseBody) => throw UnimplementedError();
}

class StubUserRepository implements UserRepository {
  @override
  Future<UserModel?> findLocalUser(String username, String password) => throw UnimplementedError();

  @override
  Future<void> saveUsersToLocal(List<UserModel> users) => throw UnimplementedError();
}

class StubBranchRepository implements BranchRepository {
  @override
  Future<void> saveBranchesToLocal(List<BranchModel> brancModelList, {bool downloadRemoteImages = true}) =>
      throw UnimplementedError();
}

class StubSettingsRepository implements SettingsRepository {
  @override
  Future<SettingsModel?> getSettingsFromLocal() => throw UnimplementedError();

  @override
  Future<void> saveSettingsToLocal(SettingsModel settingsModel) => throw UnimplementedError();
}
