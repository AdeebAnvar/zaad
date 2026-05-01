import '../../core/constants/enums.dart';

class UserModel {
  final int id;
  final int branchId;
  final String name;
  final String usertype;
  final String mobilePassword;
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
    final permsRaw = json["permissions"];
    final permissions = permsRaw is List
        ? List<String>.from(permsRaw.map((x) => x.toString()))
        : const <String>[];

    return UserModel(
      id: json["id"],
      branchId: json["branch_id"],
      name: json["name"],
      usertype: json["usertype"],
      mobilePassword: json["mobile_password"],
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
}
