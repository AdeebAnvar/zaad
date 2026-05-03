import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/enums.dart';
import 'package:pos/core/config/pos_app_runtime_config.dart';
import 'package:pos/core/network/pos_api_service.dart';
import 'package:pos/core/network/pos_server_settings.dart';
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

    await _ensureLanHubIfUnset();
    await _syncTenantBaseUrlToLanHubFromPrefs();

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
        emit(LoginServerConnectError(
          "Server data is incomplete (users/branches missing).",
        ));
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
        emit(LoginServerConnectError(
          "Server connected, but local storage verification failed.",
        ));
        return;
      }

      await _ensureLanHubIfUnset();
      await _syncTenantBaseUrlToLanHubFromPrefs();

      emit(LoginServerConnected());
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('[connectToServer] failed: $e');
        debugPrint('$s');
      }
      final detail = '$e${kDebugMode ? '\n\n$s' : ''}';
      emit(LoginServerConnectError(detail.trim()));
    }
  }

  /// Copies SharedPreferences tenant `baseUrl` (after common-api connect) to Node `sync_meta` over LAN
  /// so the hub can run cloud mirror pulls without `api_base_url` in config.json.
  Future<void> _syncTenantBaseUrlToLanHubFromPrefs() async {
    if (!locator<PosAppRuntimeConfig>().isLocal) return;
    final hub = locator<PosServerSettings>();
    if ((hub.hubRoot ?? '').trim().isEmpty) return;
    final base = await authRepo.getSavedBaseUrl();
    if (base == null || base.trim().isEmpty) return;
    try {
      await locator<PosApiService>().pushTenantBaseUrlToHub(base);
      if (kDebugMode) {
        debugPrint('[login] tenant base URL pushed to LAN hub for Node mirror');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[login] push tenant base to hub failed (hub offline or auth): $e');
      }
    }
  }

  /// When [AppMode.local] and [PosServerSettings.hubRoot] is empty, set a default hub URL **only in [kDebugMode]**.
  ///
  /// Order: non-empty `--dart-define=POS_DEFAULT_HUB_AFTER_CONNECT`, else `http://127.0.0.1:3000`.
  /// Release/profile local installs must use Setup to set the LAN URL.
  Future<void> _ensureLanHubIfUnset() async {
    if (!locator<PosAppRuntimeConfig>().isLocal) return;
    if (!kDebugMode) return;

    final hub = locator<PosServerSettings>();
    if ((hub.hubRoot ?? '').trim().isNotEmpty) return;

    const fromEnv = String.fromEnvironment('POS_DEFAULT_HUB_AFTER_CONNECT');
    final envHub = fromEnv.trim();
    if (envHub.isNotEmpty) {
      await hub.setBaseUrl(envHub);
      debugPrint('[hub] pos_server_base_url set from POS_DEFAULT_HUB_AFTER_CONNECT');
      return;
    }

    await hub.setBaseUrl('http://127.0.0.1:3000');
    debugPrint(
      '[hub] pos_server_base_url empty — defaulted to http://127.0.0.1:3000 (kDebugMode only)',
    );
  }
}
