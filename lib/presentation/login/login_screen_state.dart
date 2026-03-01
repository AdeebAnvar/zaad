part of 'login_screen_cubit.dart';

abstract class LoginState {}

class LoginInitial extends LoginState {}

class LoginError extends LoginState {
  final String msg;
  LoginError(this.msg);
}

class LoginSuccess extends LoginState {
  final UserModel user;
  LoginSuccess(this.user);
}

class LoginServerConnected extends LoginState {}

class LoginLoading extends LoginState {}
