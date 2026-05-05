import 'package:pos/core/constants/enums.dart';
import 'package:pos/data/local/drift_database.dart';

/// Tenant item `order_type` may be comma/dot/pipe-separated API keys (`take_away`, `dine_in`, …).
Set<String> parseItemOrderChannelsFromApi(dynamic raw) {
  if (raw == null) return {};
  final s = raw.toString().trim().toLowerCase();
  if (s.isEmpty) return {};

  final parts = s.split(RegExp(r'[\s,.|;/]+')).map((x) => x.trim()).where((x) => x.isNotEmpty);
  final allowed = OrderType.values.map((e) => e.value).toSet();
  final out = <String>{};
  for (final p in parts) {
    final norm = _normalizeOrderChannelToken(p);
    if (allowed.contains(norm)) out.add(norm);
  }
  return out;
}

String _normalizeOrderChannelToken(String p) {
  switch (p) {
    case 'takeaway':
    case 'take-away':
      return OrderType.takeAway.value;
    case 'dinein':
    case 'dine-in':
      return OrderType.dineIn.value;
    case 'counter':
    case 'counter-sale':
      return OrderType.counterSale.value;
  }
  return p.replaceAll('-', '_');
}

/// When [parseItemOrderChannelsFromApi] yields nothing, fall back to a single-token match.
OrderType parseSingleOrderTypeFromTenantField(String? value) {
  final s = value?.trim();
  if (s == null || s.isEmpty) return OrderType.counterSale;
  final ch = parseItemOrderChannelsFromApi(s);
  if (ch.isNotEmpty) return derivePrimaryOrderType(ch);
  final low = s.toLowerCase();
  for (final type in OrderType.values) {
    if (type.value == low) return type;
  }
  switch (low) {
    case 'takeaway':
    case 'take-away':
      return OrderType.takeAway;
    case 'dinein':
    case 'dine-in':
      return OrderType.dineIn;
    case 'counter':
      return OrderType.counterSale;
  }
  return OrderType.counterSale;
}

OrderType derivePrimaryOrderType(Set<String> channels) {
  if (channels.isEmpty) return OrderType.counterSale;
  const preferred = [
    OrderType.takeAway,
    OrderType.dineIn,
    OrderType.delivery,
    OrderType.counterSale,
  ];
  for (final p in preferred) {
    if (channels.contains(p.value)) return p;
  }
  return OrderType.values.firstWhere(
    (e) => channels.contains(e.value),
    orElse: () => OrderType.counterSale,
  );
}

/// Persisted canonical form for [Items.allowedOrderChannels] / mirror rows (stable `.` join).
String? canonicalChannelsStorageFromApi(dynamic raw) {
  final set = parseItemOrderChannelsFromApi(raw);
  if (set.isEmpty) return null;
  final list = set.toList()..sort();
  return list.join('.');
}

/// [Item.allowedOrderChannels] null or empty ⇒ no restriction (historic rows).
extension ItemSaleChannelX on Item {
  bool supportsCurrentSale(OrderType sale) {
    final raw = allowedOrderChannels?.trim();
    if (raw == null || raw.isEmpty) return true;
    final parsed = parseItemOrderChannelsFromApi(raw);
    if (parsed.isEmpty) return true;
    return parsed.contains(sale.value);
  }
}
