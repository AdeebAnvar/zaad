import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/enums.dart';
import 'package:pos/data/local/drift_database.dart';
import '../../domain/models/user_model.dart';
import '../../data/repository/user_repository.dart';
part 'login_screen_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final UserRepository repo;

  LoginCubit(this.repo) : super(LoginInitial());

  Future<void> login(String username, String password) async {
    emit(LoginLoading());

    if (username.isEmpty || password.isEmpty) {
      emit(LoginError("Username and password required"));
      return;
    }

    final user = await repo.findLocalUser(username, password);

    if (user == null) {
      emit(LoginError("User does not exist"));
      return;
    }

    final db = locator<AppDatabase>();

    await db.sessionDao.saveSession(
      user.id!,
      user.type == UserType.admin ? "admin" : "counter",
    );

    emit(LoginSuccess(user));

    // 🚀 Run sync AFTER UI transition
  }

  Future<void> connectToServer(String url) async {
    try {
      emit(LoginLoading());
      repo.setServerUrl(url);
      final users = await repo.fetchUsersFromServer(); // dummy

      await repo.saveUsersToLocal(users);
      emit(LoginServerConnected());
    } catch (e) {
      print(e);
      emit(LoginError("Invalid URL or server unreachable"));
    }
  }
}
