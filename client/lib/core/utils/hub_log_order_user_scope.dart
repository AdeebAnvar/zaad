import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/domain/models/user_model.dart';

/// Scopes order **list** queries by device role (logs, recent sales, credit sales, day closing).
///
/// - MAIN hub (not SUB): optional [uiSelectedUserId] from filters (`null` = all cashiers).
/// - SUB hub (`LocalHubSettings.isHubSub`): signed-in cashier only for take-away log,
///   recent sales, credit sales, and day closing.
/// - Delivery / dine-in logs pass [sharedBranchLogsOnSub] so every tablet sees open
///   branch orders synced from MAIN.
///
/// Does not change sync or persistence — callers pass the result as `userId` to repositories.
class HubLogOrderUserScope {
  HubLogOrderUserScope._();

  /// SUB → session cashier; MAIN → `null` (all users) unless a screen passes [uiSelectedUserId].
  static int? cashierReportUserId({
    required LocalHubSettings hub,
    required UserModel? sessionUser,
  }) =>
      effectiveFilterUserId(
        hub: hub,
        sessionUser: sessionUser,
        uiSelectedUserId: null,
      );

  static int? effectiveFilterUserId({
    required LocalHubSettings hub,
    required UserModel? sessionUser,
    int? uiSelectedUserId,
    /// When true on a SUB tablet, list all branch orders (not only this cashier).
    bool sharedBranchLogsOnSub = false,
  }) {
    if (hub.isHubSub && !sharedBranchLogsOnSub) {
      return sessionUser?.id;
    }
    return uiSelectedUserId;
  }
}
