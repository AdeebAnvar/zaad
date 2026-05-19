import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/auth/terminal_branch_scope.dart';
import 'package:pos/domain/models/user_model.dart';

void main() {
  group('TerminalBranchScope', () {
    test('filterUsers keeps only matching branch', () {
      final users = [
        UserModel(id: 1, branchId: 1, name: 'a', usertype: 'counter', mobilePassword: '', permissions: const []),
        UserModel(id: 2, branchId: 2, name: 'b', usertype: 'counter', mobilePassword: '', permissions: const []),
      ];
      final out = TerminalBranchScope.filterUsers(users, 1);
      expect(out, hasLength(1));
      expect(out.single.id, 1);
    });

    test('loginBlockMessage blocks wrong branch', () {
      final user = UserModel(
        id: 9,
        branchId: 2,
        name: 'counter2',
        usertype: 'counter',
        mobilePassword: '',
        permissions: const [],
      );
      final msg = TerminalBranchScope.loginBlockMessage(
        user: user,
        terminalBranchId: 1,
        terminalBranchName: 'Main Store',
      );
      expect(msg, isNotNull);
      expect(msg!, contains('branch 2'));
      expect(msg, contains('Branch 1'));
    });

    test('loginBlockMessage allows same branch', () {
      final user = UserModel(
        id: 1,
        branchId: 1,
        name: 'counter1',
        usertype: 'counter',
        mobilePassword: '',
        permissions: const [],
      );
      expect(
        TerminalBranchScope.loginBlockMessage(
          user: user,
          terminalBranchId: 1,
        ),
        isNull,
      );
    });
  });
}
