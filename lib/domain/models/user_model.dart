import '../../core/constants/enums.dart';

class UserModel {
  final int? id;
  final int branchId;
  final int companyId;
  final String username;
  final String password;
  final String employeeId;
  final String companyName;
  final String branchName;
  final String companyLogo;
  final String companyLogoLocal;
  final UserType type;

  UserModel({
    this.id,
    required this.employeeId,
    required this.companyId,
    required this.companyName,
    required this.branchId,
    required this.branchName,
    required this.username,
    required this.password,
    required this.companyLogo,
    this.companyLogoLocal = '',
    required this.type,
  });
}
