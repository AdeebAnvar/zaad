import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/domain/models/user_model.dart';

/// Scopes order **list** queries (take-away / dine-in / delivery logs) by device role.
///
/// - MAIN hub (not SUB): optional [uiSelectedUserId] from log filters (all users when null).
/// - SUB hub (`LocalHubSettings.isHubSub`): always the signed-in [sessionUser] so each
///   tablet only sees that POS user's bills, regardless of which physical device they use.
///
/// Does not change sync or persistence — callers pass the result as `userId` to
/// [OrderRepository.filterOrders] only.
class HubLogOrderUserScope {
  HubLogOrderUserScope._();

  static int? effectiveFilterUserId({
    required LocalHubSettings hub,
    required UserModel? sessionUser,
    int? uiSelectedUserId,
  }) {
    if (hub.isHubSub) {
      return sessionUser?.id;
    }
    return uiSelectedUserId;
  }
}
