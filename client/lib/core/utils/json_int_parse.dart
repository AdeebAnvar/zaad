/// Handles int fields that may be encoded as int, num, or string in API JSON.
int? parseIntLoose(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) {
    final t = value.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t) ?? num.tryParse(t)?.round();
  }
  return null;
}

/// Resolves tenant user branch id from common API shapes.
int branchIdFromUserJson(Map<String, dynamic> json) {
  final direct = parseIntLoose(json['branch_id'] ?? json['branchId']);
  if (direct != null && direct > 0) return direct;

  final branch = json['branch'];
  if (branch is Map) {
    final map = Map<String, dynamic>.from(branch);
    final nested = parseIntLoose(map['id'] ?? map['branch_id'] ?? map['branchId']);
    if (nested != null && nested > 0) return nested;
  }

  return 0;
}

/// Branch for mirrored hub/cloud orders: snapshot first, then active session.
int resolveMirroredOrderBranchId({
  required Map<String, dynamic> snap,
  Map<String, dynamic>? flutterSnap,
  int? sessionBranchId,
}) {
  dynamic pick(String snake, [String? camel]) {
    var v = snap[snake];
    if (v == null && camel != null) v = snap[camel];
    if (v == null && flutterSnap != null) {
      v = flutterSnap[snake];
      if (v == null && camel != null) v = flutterSnap[camel];
    }
    return v;
  }

  final fromSnap = parseIntLoose(pick('branch_id', 'branchId'));
  if (fromSnap != null && fromSnap > 0) return fromSnap;

  if (sessionBranchId != null && sessionBranchId > 0) return sessionBranchId;

  return 0;
}

/// Canonical `orders.order_type` for hub mirrors (`take_away` | `delivery` | `dine_in`).
String resolveMirroredOrderType({
  required Map<String, dynamic> snap,
  Map<String, dynamic>? flutterSnap,
  String? cartOrderType,
}) {
  String? pick(String snake, [String? camel]) {
    dynamic v = snap[snake];
    if (v == null && camel != null) v = snap[camel];
    if (v == null && flutterSnap != null) {
      v = flutterSnap[snake];
      if (v == null && camel != null) v = flutterSnap[camel];
    }
    final s = v?.toString().trim().toLowerCase();
    return (s == null || s.isEmpty) ? null : s;
  }

  final raw = pick('order_type', 'orderType') ?? cartOrderType?.trim().toLowerCase();
  if (raw == null || raw.isEmpty) return 'take_away';
  if (raw == 'delivery') return 'delivery';
  if (raw == 'dine_in' || raw == 'dine-in' || raw == 'dinein') return 'dine_in';
  if (raw == 'take_away' || raw == 'takeaway' || raw == 'take-away') return 'take_away';
  return raw;
}
