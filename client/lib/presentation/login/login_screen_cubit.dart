import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/enums.dart';
import 'package:pos/core/debug/agent_debug_log.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/core/auth/login_credentials_prefs.dart';
import 'package:pos/core/network/pos_server_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos/core/sync/hub_company_snapshot_publisher.dart';
import 'package:pos/core/sync/local_hub_sync_coordinator.dart';
import 'package:pos/core/util/error_diagnostics.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/local/tenant_switch_local_wipe.dart';
import 'package:pos/data/repository/branch_repository.dart';
import 'package:pos/data/repository/settings_repository.dart';
import 'package:pos/domain/models/api/auth/auth_repository.dart';
import 'package:pos/domain/models/company_data.dart';
import '../../domain/models/user_model.dart';
import '../../data/repository/user_repository.dart';
part 'login_screen_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final AuthRepository authRepo;
  final UserRepository userRepo;
  final BranchRepository branchRepo;
  final SettingsRepository settingsRepo;

  LoginCubit(this.authRepo, this.userRepo, this.branchRepo, this.settingsRepo) : super(LoginInitial());

  /// SUB terminals log in against local users pushed from MAIN via [COMPANY_SNAPSHOT].
  Future<void> _waitForSubHubCompanyAccounts({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final db = locator<AppDatabase>();
    if ((await db.usersDao.getAllUsers()).isNotEmpty) return;

    final hub = locator<LocalHubSettings>();
    final hubUrl = hub.hubWsUrl;
    if (hubUrl == null || hubUrl.trim().isEmpty) return;

    if (locator.isRegistered<LocalHubSyncCoordinator>()) {
      await locator<LocalHubSyncCoordinator>().startIfEnabled();
    }

    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      if ((await db.usersDao.getAllUsers()).isNotEmpty) return;
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
  }

  int _daysUntil(DateTime date) {
    final today = DateTime.now();
    final a = DateTime(today.year, today.month, today.day);
    final b = DateTime(date.year, date.month, date.day);
    return b.difference(a).inDays;
  }

  Future<void> login(
    String username,
    String password, {
    bool saveCredentials = false,
  }) async {
    emit(LoginLoading());

    if (username.isEmpty || password.isEmpty) {
      emit(LoginError("Username and password required"));
      return;
    }

    if (locator.isRegistered<LocalHubSettings>() && locator<LocalHubSettings>().isHubSub) {
      await _waitForSubHubCompanyAccounts();
    }

    final user = await userRepo.findLocalUser(username, password);

    if (user == null) {
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H4',
        location: 'login_screen_cubit.dart:login',
        message: 'local_login_user_not_found',
        data: <String, Object?>{
          'usernameLen': username.length,
          'isHubSub': locator.isRegistered<LocalHubSettings>() ? locator<LocalHubSettings>().isHubSub : null,
        },
      );
      // #endregion
      if (locator.isRegistered<LocalHubSettings>() && locator<LocalHubSettings>().isHubSub) {
        final localUsers = await locator<AppDatabase>().usersDao.getAllUsers();
        if (localUsers.isEmpty) {
          emit(
            LoginError(
              'No cashier accounts on this tablet yet.\n\n'
              'On the MAIN PC: tap Connect to server and link your company.\n'
              'On this device: LAN hub → turn on "I am sub device", enter the MAIN PC IP, Save, '
              'then wait a few seconds and try Login again.\n\n'
              'Do not use Connect to server on this tablet.',
            ),
          );
          return;
        }
      }
      emit(LoginError("User does not exist"));
      return;
    }

    final db = locator<AppDatabase>();
    if (user.branchId <= 0) {
      emit(LoginError(
        'This cashier account has no branch assigned on the server (branch_id=${user.branchId}). '
        'Fix the user\'s branch in the admin panel, then Connect to server again.',
      ));
      return;
    }

    final branch = await db.branchesDao.getBranchById(user.branchId);
    if (branch == null) {
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H4',
        location: 'login_screen_cubit.dart:login',
        message: 'local_login_branch_missing',
        data: <String, Object?>{
          'userId': user.id,
          'branchId': user.branchId,
        },
      );
      // #endregion
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

    final prefs = locator<SharedPreferences>();
    if (saveCredentials) {
      await LoginCredentialsPrefs.save(prefs, username, password);
    } else {
      await LoginCredentialsPrefs.clear(prefs);
    }

    // #region agent log
    agentDebugLog(
      hypothesisId: 'H4',
      location: 'login_screen_cubit.dart:login',
      message: 'local_login_success',
      data: <String, Object?>{
        'userId': user.id,
        'branchId': user.branchId,
        'isHubSub': locator.isRegistered<LocalHubSettings>() ? locator<LocalHubSettings>().isHubSub : null,
      },
    );
    // #endregion

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
    if (locator.isRegistered<LocalHubSettings>()) {
      if (locator<LocalHubSettings>().isHubSub) {
        emit(
          LoginServerConnectError(
            'This tablet is a LAN SUB cashier. It cannot use “Connect to server” — that runs only on MAIN. '
            'Link the company on the MAIN machine first, then open LAN hub settings on MAIN and verify the WebSocket URL. '
            'Users and settings are pushed automatically after MAIN connects.',
          ),
        );
        return;
      }
    }
    try {
      emit(LoginLoading());
      if (kDebugMode) {
        debugPrint('[connectToServer] started, appId="${code.trim()}"');
      }
      final trimmedCode = code.trim();
      if (trimmedCode.isNotEmpty && locator.isRegistered<PosServerSettings>()) {
        unawaited(locator<PosServerSettings>().setLastTenantConnectAppId(trimmedCode));
      }
      final priorBaseUrl = normalizedTenantBaseUrl(await authRepo.getSavedBaseUrl());
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
      final newBaseUrl = normalizedTenantBaseUrl(resolvedBaseUrl);
      if (newBaseUrl != null && priorBaseUrl != newBaseUrl) {
        await clearLocalDataForNewTenant(db);
        if (locator.isRegistered<CurrentCounterSession>()) {
          locator<CurrentCounterSession>().clear();
        }
      }

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

      unawaited(HubCompanySnapshotPublisher.broadcastAfterTenantLink(db));

      emit(LoginServerConnected());
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint('[connectToServer] failed: $e');
        debugPrint('$s');
      }
      final detail = userFacingConnectErrorMessage(e, s);
      agentLogConnectToServerFailure(
        hypothesisId: 'H1_stringify',
        primaryLine: describePrimarySupportLine(e),
        errorRuntimeType: e.runtimeType.toString(),
        includeStack: true,
      );
      emit(LoginServerConnectError(detail));
    }
  }
}
