import '../../domain/models/user_model.dart';

abstract class UserRepository {
  void setServerUrl(String url);
  String getServerUrl();

  Future<List<UserModel>> fetchUsersFromServer(); // dummy for now
  Future<void> saveUsersToLocal(List<UserModel> users);

  Future<UserModel?> findLocalUser(String username, String password);
}
