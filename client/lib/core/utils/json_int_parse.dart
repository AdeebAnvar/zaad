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
