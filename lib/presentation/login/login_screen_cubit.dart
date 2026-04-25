import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/enums.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/branch_repository.dart';
import 'package:pos/data/repository/settings_repository.dart';
import 'package:pos/domain/models/api/auth/auth_repository.dart';
import 'package:pos/domain/models/company_Data.dart';
import '../../domain/models/user_model.dart';
import '../../data/repository/user_repository.dart';
part 'login_screen_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository authRepo;
  final UserRepository userRepo;
  final BranchRepository branchRepo;
  final SettingsRepository settingsRepo;

  LoginCubit(this.authRepo, this.userRepo, this.branchRepo, this.settingsRepo) : super(LoginInitial());

  Future<void> login(String username, String password) async {
    emit(LoginLoading());

    if (username.isEmpty || password.isEmpty) {
      emit(LoginError("Username and password required"));
      return;
    }

    final user = await userRepo.findLocalUser(username, password);

    if (user == null) {
      emit(LoginError("User does not exist"));
      return;
    }

    final db = locator<AppDatabase>();

    await db.sessionDao.saveSession(
      user.id!,
      user.type == UserType.admin ? "admin" : "counter",
      user.branchId,
    );

    emit(LoginSuccess(user));

    // 🚀 Run sync AFTER UI transition
  }

  Future<void> connectToServer(String code) async {
    try {
      emit(LoginLoading());
      CompanyDataModel companyDataModel = await authRepo.connectToServer(code);
      userRepo.saveUsersToLocal(companyDataModel.data.user);
      branchRepo.saveBranchesToLocal(companyDataModel.data.branch);
      settingsRepo.saveSettingsToLocal(companyDataModel.data.settings);
      emit(LoginServerConnected());
    } catch (e) {
      print(e);
      emit(LoginError("Invalid URL or server unreachable"));
    }
  }
}
