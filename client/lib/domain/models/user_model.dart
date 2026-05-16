import 'dart:convert';

import '../../core/constants/enums.dart';
import '../../core/utils/json_int_parse.dart';

class UserModel {
  final int id;
  final int branchId;
  final String name;
  final String usertype;
  final String mobilePassword;

  /// Enabled permission keys from the tenant user API (`permissions` JSON array).
  ///
  /// The server sends **only granted** keys; omitted keys are treated as denied.
  /// Keys are matched case-insensitively in [CounterAccess] (e.g. `Recent_sales` and `recent_sales` are equivalent).
  final List<String> permissions;

  /// Derived role for session/UI (server sends [usertype] as text).
  UserType get type {
    final s = usertype.trim().toLowerCase();
    if (s == 'admin') return UserType.admin;
    return UserType.counter;
  }

  UserModel({
    required this.id,
    required this.branchId,
    required this.name,
    required this.usertype,
    required this.mobilePassword,
    required this.permissions,
  });

  UserModel copyWith({
    int? id,
    int? branchId,
    String? name,
    String? usertype,
    String? mobilePassword,
    List<String>? permissions,
  }) =>
      UserModel(
        id: id ?? this.id,
        branchId: branchId ?? this.branchId,
        name: name ?? this.name,
        usertype: usertype ?? this.usertype,
        mobilePassword: mobilePassword ?? this.mobilePassword,
        permissions: permissions ?? this.permissions,
      );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final List<String> permissions = _permissionsFromJson(json['permissions']);

    return UserModel(
      id: parseIntLoose(json['id']) ?? 0,
      branchId: branchIdFromUserJson(json),
      name: json["name"]?.toString() ?? '',
      usertype: json["usertype"]?.toString() ?? '',
      mobilePassword: json["mobile_password"]?.toString() ?? '',
      permissions: permissions,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "branch_id": branchId,
        "name": name,
        "usertype": usertype,
        "mobile_password": mobilePassword,
        "permissions": List<dynamic>.from(permissions.map((x) => x)),
      };

  static List<String> _permissionsFromJson(dynamic raw) {
    if (raw == null) return const <String>[];
    if (raw is List) {
      return List<String>.from(raw.map((x) => x.toString()));
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final dec = jsonDecode(raw);
        if (dec is List) {
          return List<String>.from(dec.map((x) => x.toString()));
        }
      } catch (_) {
        /* fall through */
      }
    }
    return const <String>[];
  }
}
