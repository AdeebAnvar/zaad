import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:pos/app/app_startup.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/core/update/updater_manager.dart';
import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/core/utils/app_update_cache_clear.dart';
import 'package:pos/core/utils/sales_csv_backup.dart';
import 'package:pos/data/local/drift_database.dart';

/// Runs heavy cold-start work **after** the login (or dashboard) UI has painted.
///
/// Keeps [coldStartBootstrap] limited to folder + DB open so Windows does not show
/// "Not responding" while XLSX export, backup scans, or hub sync run.
class PostLoginDeferredStartup {
  PostLoginDeferredStartup._();

  static bool _scheduled = false;

  /// Schedules phased background work once per process.
  static void scheduleAfterFirstFrame({required bool landedOnLogin}) {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runPhased(landedOnLogin: landedOnLogin));
    });
  }

  static Future<void> _yieldUi() async {
    await Future<void>.delayed(Duration.zero);
    await SchedulerBinding.instance.endOfFrame;
  }

  static Future<void> _runPhased({required bool landedOnLogin}) async {
    await _yieldUi();
    // Let login animations / first frame complete before any disk-heavy work.
    await Future<void>.delayed(
      landedOnLogin ? const Duration(milliseconds: 800) : const Duration(milliseconds: 300),
    );

    if (!locator.isRegistered<AppDatabase>()) return;
    final db = locator<AppDatabase>();

    try {
      await _yieldUi();
      if (Platform.isAndroid) {
        await AppDirectories.migrateLegacyLayoutIfNeeded();
        await _yieldUi();
        await AppDirectories.migrateAndroidInternalToPublicDocumentsIfNeeded();
        await AppDirectories.recoverAndroidDbFromPublicIfNeeded();
        await _yieldUi();
      }

      await AppUpdateCacheClear.runOnColdStartIfNeeded();
      await RuntimeAppSettings.refreshFromLocalSettings();
      await _yieldUi();

      final startup = AppStartup(db);
      await startup.ensureCompatibleLocalData();
      await _yieldUi();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[PostLoginDeferred] settings/schema phase failed: $e\n$st');
      }
    }

    // Backup verify, SQL repairs, periodic backup, hub/sync — still off the first second.
    await Future<void>.delayed(
      landedOnLogin ? const Duration(seconds: 2) : const Duration(milliseconds: 500),
    );
    try {
      await ZaadDI.runDeferredBackgroundServices();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[PostLoginDeferred] background services failed: $e\n$st');
      }
    }

    // XLSX export is the worst UI freeze offender on large order history.
    await Future<void>.delayed(
      landedOnLogin ? const Duration(seconds: 45) : const Duration(seconds: 20),
    );
    unawaited(
      SalesCsvBackup.refreshFromDatabase(db).catchError((Object e, StackTrace st) {
        if (kDebugMode) {
          debugPrint('[PostLoginDeferred] sales XLSX backup failed: $e\n$st');
        }
      }),
    );

    if (Platform.isWindows) {
      await Future<void>.delayed(
        landedOnLogin ? const Duration(seconds: 60) : const Duration(seconds: 30),
      );
      UpdaterManager.scheduleColdStartCheckOnce();
    }
  }
}
