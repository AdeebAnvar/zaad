import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/presentation/login/login_screen_cubit.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_dialogue.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';
import 'package:pos/presentation/widgets/loader_overlay.dart';

import '../../app/di.dart';
import '../../app/navigation.dart';
import '../../app/routes.dart';

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

  @override
  void initState() {
    super.initState();
    cubit = locator<LoginCubit>();

    if (kDebugMode) {
      userNameController.text = "counter";
      passWordController.text = "12345";
    }
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
      LoaderOverlay.show(context, message: 'Connecting...');
    }
    if (state is LoginServerConnected) {
      LoaderOverlay.hide();
    }

    if (state is LoginServerConnected) {
      LoaderOverlay.hide();
      CustomSnackBar.showSuccess(
        message: "Server connected successfully",
      );
    }

    if (state is LoginSuccess) {
      LoaderOverlay.hide();
      if ((state.expiryWarning ?? '').isNotEmpty) {
        CustomSnackBar.showWarning(message: state.expiryWarning!);
      }

      if (state.showExpiryPopup) {
        _showExpiryWarningDialog(state).then((_) {
          AppNavigator.pushReplacementNamed(
            "/auto_sync_screen",
            args: state.user,
          );
        });
        return;
      }

      AppNavigator.pushReplacementNamed(
        "/auto_sync_screen",
        args: state.user,
      );
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
                    'Zaad Platfforms',
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
          const SizedBox(height: 20),
          CustomButton(
            text: "Login",
            onPressed: _onLoginPressed,
          ),
          const SizedBox(height: 14),
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
    );
  }

  Widget _loginLogo() {
    return GestureDetector(
      onLongPress: () => AppNavigator.pushNamed(Routes.setup),
      child: Image.asset(
        'assets/images/png/appicon2.webp',
        height: 100,
        width: 100,
      ),
    );
  }

  // ================= ACTIONS =================

  void _onLoginPressed() {
    if (!formKey.currentState!.validate()) return;

    cubit.login(
      userNameController.text.trim(),
      passWordController.text.trim(),
    );
  }

  void _openServerDialog() {
    final controller = TextEditingController();
    if (kDebugMode) {
      controller.text = 'R3M2KZ';
    }
    CustomDialog.showResponsiveDialog(
      context,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Server Connection",
            style: AppStyles.getSemiBoldTextStyle(fontSize: 18, color: AppColors.textColor),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: controller,
            labelText: "Server URL",
            prefixIcon: const Icon(Icons.link),
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
                    cubit.connectToServer(controller.text.trim());
                  },
                ),
              ),
            ],
          ),
        ],
      ),
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
