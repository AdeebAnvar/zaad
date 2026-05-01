part of 'login_screen_cubit.dart';

abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginError extends LoginState {
  final String msg;
  LoginError(this.msg);
}

class LoginSuccess extends LoginState {
  final UserModel user;
  final int? expiryDaysLeft;
  final String? expiryWarning;
  final bool showExpiryPopup;
  LoginSuccess(
    this.user, {
    this.expiryDaysLeft,
    this.expiryWarning,
    this.showExpiryPopup = false,
  });
}

class LoginServerConnected extends LoginState {}

class LoginLoading extends LoginState {}
