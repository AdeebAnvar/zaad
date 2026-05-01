import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/enums.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
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

  int _daysUntil(DateTime date) {
    final today = DateTime.now();
    final a = DateTime(today.year, today.month, today.day);
    final b = DateTime(date.year, date.month, date.day);
    return b.difference(a).inDays;
  }

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
    final branch = await db.branchesDao.getBranchById(user.branchId);
    if (branch == null) {
      emit(LoginError("Branch setup not found for this user"));
      return;
    }
    final daysLeft = _daysUntil(branch.expiryDate.toLocal());
    if (daysLeft < 0) {
      emit(LoginError("Subscription expired on ${RuntimeAppSettings.formatDate(branch.expiryDate.toLocal())}. Please renew to continue."));
      return;
    }

    await db.sessionDao.saveSession(
      user.id,
      user.type == UserType.admin ? "admin" : "counter",
      user.branchId,
    );

    final critical = daysLeft <= 5;
    final warning = daysLeft <= 10 ? (daysLeft == 0 ? 'Subscription expires today.' : 'Subscription expires in $daysLeft day${daysLeft == 1 ? '' : 's'}.') : null;
    emit(LoginSuccess(
      user,
      expiryDaysLeft: daysLeft,
      expiryWarning: warning,
      showExpiryPopup: critical,
    ));

    // 🚀 Run sync AFTER UI transition
  }

  Future<void> connectToServer(String code) async {
    try {
      emit(LoginLoading());
      if (kDebugMode) {
        debugPrint('[connectToServer] started, appId="${code.trim()}"');
      }
      CompanyDataModel companyDataModel = await authRepo.connectToServer(code);
      final resolvedBaseUrl = await authRepo.getSavedBaseUrl();
      final remoteUsers = companyDataModel.data.user;
      final remoteBranches = companyDataModel.data.branch;
      if (kDebugMode) {
        debugPrint('[connectToServer] resolved baseUrl=$resolvedBaseUrl');
        debugPrint('[connectToServer] API success=${companyDataModel.success}, message="${companyDataModel.message}"');
        debugPrint('[connectToServer] payload users=${remoteUsers.length}, branches=${remoteBranches.length}, settingsLoaded=true');
      }

      if (remoteUsers.isEmpty || remoteBranches.isEmpty) {
        emit(LoginError("Server data is incomplete (users/branches missing)."));
        return;
      }

      final db = locator<AppDatabase>();
      await db.transaction(() async {
        await userRepo.saveUsersToLocal(companyDataModel.data.user);
        await branchRepo.saveBranchesToLocal(companyDataModel.data.branch);
        await settingsRepo.saveSettingsToLocal(companyDataModel.data.settings);
      });
      final savedUsers = await db.usersDao.getAllUsers();
      final savedBranches = await db.branchesDao.getAllBranches();
      final savedSettings = await db.settingsDao.getSettings();
      if (kDebugMode) {
        debugPrint('[connectToServer] local save complete users=${savedUsers.length}, branches=${savedBranches.length}, hasSettings=${savedSettings != null}');
      }
      if (savedUsers.isEmpty || savedBranches.isEmpty || savedSettings == null) {
        emit(LoginError("Server connected, but local storage verification failed."));
        return;
      }

      emit(LoginServerConnected());
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('[connectToServer] failed: $e');
        debugPrint('$s');
      }
      emit(LoginError("Invalid URL/server unreachable or failed to save local data"));
    }
  }
}
