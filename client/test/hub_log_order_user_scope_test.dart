import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/utils/hub_log_order_user_scope.dart';
import 'package:pos/domain/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('HubLogOrderUserScope', () {
    late LocalHubSettings hubSub;
    late LocalHubSettings hubMain;
    final cashier = UserModel(
      id: 7,
      branchId: 2,
      name: 'Ali',
      usertype: 'staff',
      mobilePassword: '',
      permissions: const <String>[],
    );

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LocalHubSettings.roleKey: 'hub_sub',
        LocalHubSettings.wsUrlKey: 'ws://192.168.1.10:3001/ws',
      });
      hubSub = LocalHubSettings(await SharedPreferences.getInstance());

      SharedPreferences.setMockInitialValues(<String, Object>{});
      hubMain = LocalHubSettings(await SharedPreferences.getInstance());
    });

    test('SUB recent sales / credit / day close use session cashier only', () {
      expect(
        HubLogOrderUserScope.cashierReportUserId(hub: hubSub, sessionUser: cashier),
        7,
      );
      expect(
        HubLogOrderUserScope.effectiveFilterUserId(
          hub: hubSub,
          sessionUser: cashier,
          uiSelectedUserId: 99,
        ),
        7,
      );
    });

    test('MAIN uses optional UI filter; null means all users', () {
      expect(
        HubLogOrderUserScope.cashierReportUserId(hub: hubMain, sessionUser: cashier),
        isNull,
      );
      expect(
        HubLogOrderUserScope.effectiveFilterUserId(
          hub: hubMain,
          sessionUser: cashier,
          uiSelectedUserId: 3,
        ),
        3,
      );
    });

    test('delivery / dine-in logs stay branch-wide on SUB', () {
      expect(
        HubLogOrderUserScope.effectiveFilterUserId(
          hub: hubSub,
          sessionUser: cashier,
          uiSelectedUserId: 99,
          sharedBranchLogsOnSub: true,
        ),
        99,
      );
      expect(
        HubLogOrderUserScope.effectiveFilterUserId(
          hub: hubSub,
          sessionUser: cashier,
          sharedBranchLogsOnSub: true,
        ),
        isNull,
      );
    });
  });
}
