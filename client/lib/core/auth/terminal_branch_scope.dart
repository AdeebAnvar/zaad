import 'package:pos/data/local/drift_database.dart';
import 'package:pos/domain/models/branch_model.dart';
import 'package:pos/domain/models/user_model.dart';

/// Branch isolation for a MAIN installation + its SUB tablets.
class TerminalBranchScope {
  TerminalBranchScope._();

  static List<UserModel> filterUsers(List<UserModel> users, int branchId) =>
      users.where((u) => u.branchId == branchId).toList();

  static List<BranchModel> filterBranches(List<BranchModel> branches, int branchId) =>
      branches.where((b) => b.id == branchId).toList();

  /// `null` = allowed; otherwise show this on the login screen.
  static String? loginBlockMessage({
    required UserModel user,
    required int terminalBranchId,
    String? terminalBranchName,
  }) {
    if (user.branchId == terminalBranchId) return null;
    final branchLabel = terminalBranchName?.trim();
    final terminalLabel = branchLabel != null && branchLabel.isNotEmpty
        ? 'Branch $terminalBranchId ($branchLabel)'
        : 'Branch $terminalBranchId';
    return 'This device is registered to $terminalLabel. '
        '"${user.name}" belongs to branch ${user.branchId} and cannot log in here. '
        'Use a cashier assigned to the same branch, or link this device from the correct MAIN PC.';
  }

  static Future<String?> branchDisplayName(AppDatabase db, int branchId) async {
    final b = await db.branchesDao.getBranchById(branchId);
    return b?.branchName;
  }
}
