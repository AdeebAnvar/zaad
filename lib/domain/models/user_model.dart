import '../../core/constants/enums.dart';

class UserModel {
  final int id;
  final int branchId;
  final String name;
  final String usertype;
  final String mobilePassword;
  final List<String> permissions;
  final UserType type;

  UserModel({
    required this.id,
    required this.branchId,
    required this.name,
    required this.usertype,
    required this.mobilePassword,
    required this.permissions,
    required this.type,
  });

  UserModel copyWith({
    int? id,
    int? branchId,
    String? name,
    String? usertype,
    String? mobilePassword,
    List<String>? permissions,
    final UserType? type,
  }) =>
      UserModel(
        type: type ?? this.type,
        id: id ?? this.id,
        branchId: branchId ?? this.branchId,
        name: name ?? this.name,
        usertype: usertype ?? this.usertype,
        mobilePassword: mobilePassword ?? this.mobilePassword,
        permissions: permissions ?? this.permissions,
      );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json["id"],
        branchId: json["branch_id"],
        name: json["name"],
        usertype: json["usertype"],
        mobilePassword: json["mobile_password"],
        type: UserType.counter,
        permissions: List<String>.from(json["permissions"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "branch_id": branchId,
        "name": name,
        "usertype": usertype,
        "mobile_password": mobilePassword,
        "permissions": List<dynamic>.from(permissions.map((x) => x)),
      };
}
