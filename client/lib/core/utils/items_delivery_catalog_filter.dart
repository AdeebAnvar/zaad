/// Delivery sale item-panel filter (partner / `delivery_service` on catalog rows).
bool itemMatchesDeliveryService({
  required String? itemDeliveryService,
  required String filterToken,
  required Set<String> thirdPartyPartnerServiceIds,
}) {
  final raw = itemDeliveryService?.trim() ?? '';
  if (raw.isEmpty) return true;

  final t = filterToken.trim();
  if (raw == t || raw.toLowerCase() == t.toLowerCase()) return true;

  final ri = int.tryParse(raw);
  final ti = int.tryParse(t);
  if (ri != null && ti != null && ri == ti) return true;

  if (t.toUpperCase() == 'NORMAL') {
    if (raw.toUpperCase() == 'NORMAL') return true;
    // SUB APK: partner table not synced yet — hide any numeric service tag until ids arrive.
    if (thirdPartyPartnerServiceIds.isEmpty && ri != null) return false;
    if (ri != null && thirdPartyPartnerServiceIds.contains(raw)) return false;
    return true;
  }

  return false;
}
