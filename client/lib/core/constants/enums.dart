enum UserType { admin, counter }

enum SyncPhase { idle, categories, items, success, failed }

enum SaleMode { takeAway, delivery, counter }

enum SyncStage { categories, items, completed, failed }

enum OrderType {
  counterSale('counter_sale'),
  takeAway('take_away'),
  delivery('delivery'),
  dineIn('dine_in');

  final String value;

  const OrderType(this.value);
}

/// [Navigator] args often pass API/DB strings; the counter route also accepts [OrderType].
OrderType parseOrderTypeFromRouteArg(dynamic raw) {
  if (raw == null) return OrderType.takeAway;
  if (raw is OrderType) return raw;
  if (raw is String) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return OrderType.takeAway;
    for (final type in OrderType.values) {
      if (type.value == s) return type;
    }
    switch (s) {
      case 'takeaway':
      case 'take-away':
        return OrderType.takeAway;
      case 'dinein':
      case 'dine-in':
        return OrderType.dineIn;
      case 'counter':
        return OrderType.counterSale;
    }
  }
  return OrderType.takeAway;
}

enum YesOrNo { yes, no }

class SyncStatus {
  final SyncPhase phase;
  final int current;
  final int total;
  final String message;

  const SyncStatus({
    required this.phase,
    this.current = 0,
    this.total = 0,
    required this.message,
  });
}
