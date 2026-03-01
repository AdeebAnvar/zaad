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
      passWordController.text = "1234";
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
                  Image.asset(
                    'assets/images/png/appicon2.webp',
                    height: 100,
                    width: 100,
                  ),
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
          Image.asset(
            'assets/images/png/appicon2.webp',
            height: 100,
            width: 100,
          ),
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
}
