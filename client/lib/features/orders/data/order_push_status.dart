/// Maps local `[Orders.status]` / `order_type` to REST / tenant push contract:
/// `pending` | `out_of_delivery` | `delivered` | `reject`.
///
/// Take-away & dine-in reuse hub lifecycle words: open bills → `pending`, settled → `delivered`.
class OrderPushStatus {
  OrderPushStatus._();

  static String normalizedOrderType(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    if (s == 'delivery') return 'delivery';
    if (s == 'dine_in' || s == 'dine-in') return 'dine_in';
    return 'take_away';
  }

  /// Value sent on `/push_records` sales and Hub order JSON `status`.
  static String toRemote({
    required String? orderType,
    required String? localStatus,
  }) {
    if (normalizedOrderType(orderType) != 'delivery') {
      final s = (localStatus ?? '').trim().toLowerCase();
      if (s == 'completed' || s == 'delivered') return 'delivered';
      if (s == 'cancelled' || s == 'canceled' || s == 'reject') return 'reject';
      return 'pending';
    }
    final s = (localStatus ?? '').trim().toLowerCase();
    if (s == 'completed' || s == 'delivered') return 'delivered';
    if (s == 'cancelled' || s == 'canceled' || s == 'reject') return 'reject';
    if (s == 'out_of_delivery' ||
        s == 'assigned' ||
        s == 'dispatched' ||
        s == 'out_for_delivery') {
      return 'out_of_delivery';
    }
    return 'pending';
  }

  /// Higher rank = further along the delivery lifecycle (used for LAN merge).
  static int lifecycleRank(String? localStatus) {
    final s = (localStatus ?? '').trim().toLowerCase();
    if (s == 'cancelled' || s == 'canceled' || s == 'reject') return 100;
    if (s == 'completed' || s == 'delivered') return 90;
    if (s == 'out_of_delivery' ||
        s == 'assigned' ||
        s == 'dispatched' ||
        s == 'out_for_delivery') {
      return 50;
    }
    if (s == 'kot' || s == 'placed' || s == 'pending') return 10;
    return 0;
  }

  /// True when an inbound hub/LAN status should win over a newer-but-less-advanced local row.
  static bool incomingStatusShouldWin({
    required String currentLocal,
    required String incomingMappedLocal,
  }) {
    return lifecycleRank(incomingMappedLocal) > lifecycleRank(currentLocal);
  }

  /// When applying Hub / LAN snapshot INTO Drift — keep local enums consistent.
  static String localFromHub({
    required String? orderType,
    required String hubStatus,
  }) {
    final r = hubStatus.trim().toLowerCase();
    if (normalizedOrderType(orderType) != 'delivery') {
      switch (r) {
        case 'reject':
          return 'cancelled';
        case 'delivered':
          return 'completed';
        default:
          return hubStatus;
      }
    }
    switch (r) {
      case 'reject':
      case 'rejected':
        return 'cancelled';
      case 'delivered':
        return 'completed';
      case 'out_of_delivery':
        return 'out_of_delivery';
      case 'pending':
        return 'pending';
      default:
        return hubStatus;
    }
  }
}
