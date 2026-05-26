import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pos/core/auth/login_credentials_prefs.dart';
import 'package:pos/core/utils/app_update_cache_clear.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/network/pos_server_settings.dart';
import 'package:pos/domain/models/api/auth/auth_repository.dart';
import 'package:pos/presentation/login/login_screen_cubit.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_dialog.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';
import 'package:pos/presentation/widgets/loader_overlay.dart';

import '../../app/di.dart';
import '../../app/navigation.dart';
import '../../app/routes.dart';
import '../../core/network/local_hub_settings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  static String route = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passWordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  late final LoginCubit cubit;
  bool _saveCredentials = false;
  String? _appVersionLabel;
  String? _dbSchemaLabel;

  @override
  void initState() {
    super.initState();
    cubit = locator<LoginCubit>();
    unawaited(_refreshSavedBaseUrl());
    unawaited(_loadVersionLabels());

    final prefs = locator<SharedPreferences>();
    if (LoginCredentialsPrefs.hasSaved(prefs)) {
      userNameController.text = LoginCredentialsPrefs.readUsername(prefs) ?? '';
      passWordController.text = LoginCredentialsPrefs.readPassword(prefs) ?? '';
      _saveCredentials = true;
    } else if (kDebugMode) {
      userNameController.text = "counter";
      passWordController.text = "12345";
    }
  }

  Future<void> _refreshSavedBaseUrl() async {
    await locator<AuthRepository>().getSavedBaseUrl();
  }

  Future<void> _loadVersionLabels() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final schemaVersion = locator.isRegistered<AppDatabase>() ? locator<AppDatabase>().schemaVersion : null;
      if (!mounted) return;
      setState(() {
        _appVersionLabel = AppUpdateCacheClear.packageVersionLabel(info);
        _dbSchemaLabel = schemaVersion != null ? 'db_v$schemaVersion' : null;
      });
    } catch (_) {}
  }

  Future<void> _showConnectedToServerSnack() async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    CustomSnackBar.showSuccess(
      context: context,
      message: 'Connected to server',
      duration: const Duration(milliseconds: 1800),
      floating: true,
      position: SnackBarPosition.bottom,
      compact: true,
    );
    unawaited(_refreshSavedBaseUrl());
  }

  @override
  void dispose() {
    userNameController.dispose();
    passWordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: BlocListener<LoginCubit, LoginState>(
        listener: _onStateChanged,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: LayoutBuilder(
            builder: (_, size) {
              return size.maxWidth < 600 ? _mobileView() : _desktopView();
            },
          ),
        ),
      ),
    );
  }

  // ================= STATES =================

  void _onStateChanged(BuildContext _, LoginState state) {
    if (state is LoginError) {
      LoaderOverlay.hide();

      CustomSnackBar.showError(
        message: state.msg,
      );
    }
    if (state is LoginServerConnectError) {
      LoaderOverlay.hide();
      _showServerConnectErrorDialog(state.message);
    }
    if (state is LoginLoading) {
      LoaderOverlay.show(context, message: 'Signing in…');
    }
    if (state is LoginServerConnected) {
      LoaderOverlay.hide();
      // Defer past loader removal + route settle (Windows: overlay/snackbar races with dialog close).
      unawaited(_showConnectedToServerSnack());
    }

    if (state is LoginSuccess) {
      LoaderOverlay.hide();
      if ((state.expiryWarning ?? '').isNotEmpty) {
        CustomSnackBar.showWarning(message: state.expiryWarning!);
      }

      void gotoPostLogin() {
        final hub = locator<LocalHubSettings>();
        if (hub.isHubSub) {
          CustomSnackBar.showSuccess(
            message: 'LAN cashier: company cloud sync is off. Sale data syncs through the MAIN hub only.',
          );
          AppNavigator.pushReplacementNamed(Routes.dashboard);
          return;
        }
        AppNavigator.pushReplacementNamed(
          Routes.autoSyncScreen,
          args: state.user,
        );
      }

      if (state.showExpiryPopup) {
        _showExpiryWarningDialog(state).then((_) => gotoPostLogin());
        return;
      }

      gotoPostLogin();
    }
  }

  // ================= DESKTOP =================

  Widget _desktopView() {
    return Row(
      children: [
        Expanded(
          child: Container(
            color: AppColors.scaffoldColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _loginLogo(),
                  const SizedBox(height: 24),
                  Text(
                    'Zaad Platforms',
                    style: AppStyles.getBoldTextStyle(fontSize: 20),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Login',
                  style: AppStyles.getMediumTextStyle(fontSize: 20),
                ),
                const SizedBox(height: 24),
                SizedBox(width: 600, child: _loginForm()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= MOBILE =================

  Widget _mobileView() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
          _loginLogo(),
          const SizedBox(height: 24),
          Text(
            'Zaad Platforms',
            style: AppStyles.getBoldTextStyle(fontSize: 20),
          ),
          const SizedBox(height: 24),
          Text(
            'Login',
            style: AppStyles.getMediumTextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          _loginForm(),
          if (_appVersionLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              'v$_appVersionLabel',
              style: AppStyles.getRegularTextStyle(
                fontSize: 12,
                color: AppColors.hintFontColor,
              ),
            ),
          ],
          if (_dbSchemaLabel != null) ...[
            const SizedBox(height: 2),
            Text(
              _dbSchemaLabel!,
              style: AppStyles.getRegularTextStyle(
                fontSize: 11,
                color: AppColors.hintFontColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================= FORM =================

  Widget _loginForm() {
    return Form(
      key: formKey,
      child: Column(
        children: [
          CustomTextField(
            controller: userNameController,
            labelText: 'Username',
            validator: (v) => v == null || v.isEmpty ? 'Enter username' : null,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: passWordController,
            obscureText: true,
            labelText: 'Password',
            validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            value: _saveCredentials,
            onChanged: (v) => setState(() => _saveCredentials = v ?? false),
            title: Text(
              'Save credentials',
              style: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.textColor),
            ),
          ),
          const SizedBox(height: 8),
          CustomButton(
            text: "Login",
            onPressed: _onLoginPressed,
          ),
          const SizedBox(height: 14),
          if (locator<LocalHubSettings>().isHubSub)
            Text(
              'LAN cashier — company link runs on MAIN only.',
              textAlign: TextAlign.center,
              style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.grey.shade700),
            )
          else
            Column(
              children: [
                GestureDetector(
                  onTap: _openServerDialog,
                  child: Text(
                    'Connect to server',
                    style: AppStyles.getRegularTextStyle(
                      fontSize: 14,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              await AppNavigator.pushNamed(Routes.lanHubSettings);
              if (mounted) unawaited(_refreshSavedBaseUrl());
            },
            child: Text(
              'LAN hub (MAIN / SUB)',
              style: AppStyles.getSemiBoldTextStyle(fontSize: 14, color: AppColors.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/png/appicon2.webp',
          height: 100,
          width: 100,
        ),
      ],
    );
  }

  // ================= ACTIONS =================

  void _onLoginPressed() {
    if (!formKey.currentState!.validate()) return;

    cubit.login(
      userNameController.text.trim(),
      passWordController.text.trim(),
      saveCredentials: _saveCredentials,
    );
  }

  void _openServerDialog() {
    CustomDialog.showResponsiveDialog(
      context,
      _ServerConnectDialogBody(loginCubit: cubit),
    );
  }

  void _showServerConnectErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final maxBodyHeight = MediaQuery.sizeOf(ctx).height * 0.5;
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Could not connect',
                  style: AppStyles.getSemiBoldTextStyle(fontSize: 16, color: AppColors.textColor),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxBodyHeight),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      message,
                      style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.textColor),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: CustomButton(
                    text: 'OK',
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showExpiryWarningDialog(LoginSuccess state) {
    final isCritical = (state.expiryDaysLeft ?? 99) <= 5;
    final accent = isCritical ? const Color(0xFFC62828) : const Color(0xFFF9A825);
    final bg = isCritical ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1);
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: accent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Subscription Warning',
                          style: AppStyles.getSemiBoldTextStyle(fontSize: 16, color: accent),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  state.expiryWarning ?? 'Subscription is near expiry.',
                  style: AppStyles.getRegularTextStyle(
                    fontSize: 13,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 40,
                  child: CustomButton(
                    text: 'OK',
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServerConnectDialogBody extends StatefulWidget {
  const _ServerConnectDialogBody({required this.loginCubit});

  final LoginCubit loginCubit;

  @override
  State<_ServerConnectDialogBody> createState() => _ServerConnectDialogBodyState();
}

class _ServerConnectDialogBodyState extends State<_ServerConnectDialogBody> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final saved = locator<PosServerSettings>().lastTenantConnectAppId;
    _controller = TextEditingController(
      text: saved ?? (kDebugMode ? 'R3M2KZ' : ''),
    );
  }

  void _persistServerCodeDraft() {
    final t = _controller.text.trim();
    if (t.isEmpty) return;
    unawaited(locator<PosServerSettings>().setLastTenantConnectAppId(t));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Server Connection",
          style: AppStyles.getSemiBoldTextStyle(fontSize: 18, color: AppColors.textColor),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _controller,
          labelText: "Server URL",
          prefixIcon: const Icon(Icons.link),
          onChanged: (_) => _persistServerCodeDraft(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: "Cancel",
                onPressed: AppNavigator.pop,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: "Connect",
                onPressed: () {
                  AppNavigator.pop();
                  widget.loginCubit.connectToServer(_controller.text.trim());
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
