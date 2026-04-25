import 'package:flutter/material.dart';
import 'auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository repository;

  AuthProvider(this.repository);

  Future<void> connect(String code) async => await repository.connectToServer(code);
}
