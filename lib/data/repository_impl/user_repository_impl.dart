import 'package:pos/core/constants/enums.dart';
import 'package:pos/core/utils/image_utils.dart';

import '../../domain/models/user_model.dart';
import '../repository/user_repository.dart';
import '../local/drift_database.dart';

class UserRepositoryImpl implements UserRepository {
  final AppDatabase db;
  String serverUrl = "";

  UserRepositoryImpl(this.db);

  @override
  void setServerUrl(String url) {
    serverUrl = url;
  }

  // ---------------- SERVER (DUMMY) ----------------

  @override
  Future<List<UserModel>> fetchUsersFromServer() async {
    if (!serverUrl.startsWith("adibzz")) {
      throw Exception("Invalid Server URL");
    }

    await Future.delayed(const Duration(seconds: 1));

    return [
      UserModel(
        id: 1,
        username: "admin",
        password: "1234",
        type: UserType.admin,
        branchId: 1,
        branchName: 'Zaad',
        companyId: 1,
        companyName: 'Zaad platforms',
        employeeId: 'Emp_09390',
        companyLogo: 'https://restaurantdev.zaad1.com/assets/img/appicon.webp',
      ),
      UserModel(
        id: 2,
        username: "counter",
        password: "1234",
        type: UserType.counter,
        branchId: 2,
        branchName: 'Ghuri',
        companyId: 2,
        companyName: 'Food Time',
        companyLogo: 'https://i.pinimg.com/736x/8e/6e/ac/8e6eac9d0de68014f96c8359b6cfd2dd.jpg',
        employeeId: 'Emp_99897',
      ),
    ];
  }

  // ---------------- SAVE TO LOCAL ----------------

  @override
  Future<void> saveUsersToLocal(List<UserModel> users) async {
    await db.delete(db.users).go();

    for (final u in users) {
      var localPath = await ImageUtils.downloadImage(u.companyLogo, '${u.id}_${u.username}');
      print('jnetjk ${u.companyName} ${u.companyLogo} ${u.companyLogoLocal}');
      await db.usersDao.insertUser(
        UsersCompanion.insert(
          // id: Value(u.id ?? 0),
          username: u.username,
          password: u.password,
          branchId: u.branchId,
          branchName: u.branchName,
          companyId: u.companyId,
          companyName: u.companyName,
          employeeId: u.employeeId,
          companyLogo: u.companyLogo,
          companyLogoLocal: localPath ?? "",
          role: _mapTypeToRole(u.type),
        ),
      );
    }
  }

  // ---------------- LOCAL LOGIN ----------------

  @override
  Future<UserModel?> findLocalUser(String username, String password) async {
    final u = await db.usersDao.getAllUsers();
    for (var y in u) {
      print('knkjn ${y.id}');
      print('knkjn ${y.username}');
      print('knkjn ${y.password}');
    }
    final match = await db.usersDao.findUser(username, password);

    if (match == null) return null;

    return UserModel(
      id: match.id,
      username: match.username,
      password: match.password,
      branchId: match.branchId,
      branchName: match.branchName,
      companyId: match.companyId,
      companyLogo: match.companyLogo,
      companyName: match.companyName,
      employeeId: match.employeeId,
      companyLogoLocal: match.companyLogoLocal,
      type: _mapRoleToType(match.role),
    );
  }

  // ---------------- MAPPERS ----------------

  String _mapTypeToRole(UserType type) {
    return type == UserType.admin ? "admin" : "counter";
  }

  UserType _mapRoleToType(String role) {
    return role == "admin" ? UserType.admin : UserType.counter;
  }
}
