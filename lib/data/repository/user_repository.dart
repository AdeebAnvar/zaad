import '../../domain/models/user_model.dart';

abstract class UserRepository {
  Future<void> saveUsersToLocal(List<UserModel> users);

  Future<UserModel?> findLocalUser(String username, String password);
}
