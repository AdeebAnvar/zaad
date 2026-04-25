import 'package:flutter/material.dart';
import 'package:pos/app/app_startup.dart';
import 'package:pos/core/constants/enums.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/data/local/drift_database.dart';
import 'app/app.dart';
import 'app/di.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize DI ONCE
  await ZaadDI.initialize();

  final db = locator<AppDatabase>();
  final startup = AppStartup(db);

  // Auto-clear incompatible local cache (e.g. old DB) after app updates.
  await startup.ensureCompatibleLocalData();
  await RuntimeAppSettings.refreshFromLocalSettings();

  final UserType? userType = await startup.checkLoggedInUser();

  runApp(ZaadPOSApp(userType: userType));
}
