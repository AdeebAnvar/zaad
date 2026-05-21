import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:pos/app/app_startup.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/core/constants/enums.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/core/utils/app_update_cache_clear.dart';
import 'package:pos/data/local/drift_database.dart';
import 'app/app.dart';
import 'app/di.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  HttpOverrides.global = MyHttpOverrides();

  WidgetsFlutterBinding.ensureInitialized();

  // Cap decoded catalog bitmap RAM (full sale snapshots stay in SQLite, not image cache).
  PaintingBinding.instance.imageCache
    ..maximumSize = 200
    ..maximumSizeBytes = 50 << 20;

  await AppDirectories.migrateLegacyLayoutIfNeeded();
  await AppDirectories.migrateAndroidInternalToPublicDocumentsIfNeeded();
  await AppDirectories.recoverAndroidDbFromPublicIfNeeded();

  // ✅ Initialize DI ONCE
  await ZaadDI.initialize();

  final db = locator<AppDatabase>();
  // Require sign-in on every cold start (process died). Background resume does not re-run [main].
  await db.sessionDao.clearSession();
  locator<CurrentCounterSession>().clear();

  final startup = AppStartup(db);

  // Auto-clear incompatible local DB after schema bumps; ephemeral caches after app version bumps.
  await startup.ensureCompatibleLocalData();
  await AppUpdateCacheClear.runOnColdStartIfNeeded();
  await RuntimeAppSettings.refreshFromLocalSettings();

  final UserType? userType = await startup.checkLoggedInUser();

  final setupRoute = userType == null ? ZaadDI.consumePendingInitialRoute() : null;

  runApp(ZaadPOSApp(userType: userType, initialRouteOverride: setupRoute));
}
