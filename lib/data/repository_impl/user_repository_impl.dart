import 'dart:convert';
import 'package:crypto/crypto.dart';

import '../../domain/models/user_model.dart';
import '../repository/user_repository.dart';
import '../local/drift_database.dart';

class UserRepositoryImpl implements UserRepository {
  final AppDatabase db;

  UserRepositoryImpl(this.db);

  @override
  Future<void> saveUsersToLocal(List<UserModel> users) async {
    await db.delete(db.users).go();

    for (final u in users) {
      await db.usersDao.insertUser(u);
    }
  }
  // ---------------- LOCAL LOGIN ----------------

  @override
  Future<UserModel?> findLocalUser(String username, String password) async {
    final md5Password = HashHelper.toMd5(password);
    print('sdfds $md5Password');
    final match = await db.usersDao.findUser(username, md5Password);

    if (match == null) return null;

    return match;
  }
}

class HashHelper {
  static String toMd5(String input) {
    final bytes = utf8.encode(input);
    final digest = md5.convert(bytes);
    return digest.toString();
  }
}
