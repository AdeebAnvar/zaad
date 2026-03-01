import 'package:flutter/material.dart';
import 'package:pos/app/app_startup.dart';
import 'package:pos/core/constants/enums.dart';
import 'package:pos/data/local/drift_database.dart';
import 'app/app.dart';
import 'app/di.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize DI ONCE
  await ZaadDI.initialize();

  final db = locator<AppDatabase>();
  final startup = AppStartup(db);

  final UserType? userType = await startup.checkLoggedInUser();

  runApp(ZaadPOSApp(userType: userType));
}
