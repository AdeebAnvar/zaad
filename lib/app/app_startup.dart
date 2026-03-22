import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/constants/enums.dart';
import '../data/local/drift_database.dart';

class AppStartup {
  final AppDatabase db;

  AppStartup(this.db);

  /// Bump this string when you make **breaking** local data changes.
  /// When it changes, the local Drift DB file will be deleted on next startup.
  static const String _dataSchemaVersion = '1';

  /// Clears incompatible local cache (DB file) on app update.
  ///
  /// Strategy:
  /// - Persist the last-used data schema version in a small text file.
  /// - Compare it with [_dataSchemaVersion].
  /// - If versions differ, delete the Drift SQLite file so a fresh DB
  ///   is created for the new build (all local cache reset).
  ///
  /// This runs once per version and is platform-agnostic (Android, Windows, etc.).
  Future<void> ensureCompatibleLocalData() async {
    final dir = await getApplicationDocumentsDirectory();
    final versionFile = File(p.join(dir.path, 'data_schema_version.txt'));

    String? lastVersion;
    if (await versionFile.exists()) {
      try {
        lastVersion = await versionFile.readAsString();
      } catch (_) {
        lastVersion = null;
      }
    }

    if (lastVersion == _dataSchemaVersion) {
      // Same schema version as last time – nothing to do.
      return;
    }

    // Version changed – clear Drift DB so we don't crash on incompatible schema.
    try {
      await db.close();
    } catch (_) {
      // Ignore close errors; we'll recreate DB file anyway.
    }

    try {
      final dbFile = File(p.join(dir.path, 'pos.sqlite'));
      if (await dbFile.exists()) {
        await dbFile.delete();
      }
    } catch (_) {
      // If deletion fails, we still proceed; Drift may attempt migrations.
    }

    try {
      await versionFile.writeAsString(_dataSchemaVersion);
    } catch (_) {
      // If we can't persist, fallback is just to recreate DB next run if needed.
    }
  }

  Future<UserType?> checkLoggedInUser() async {
    final session = await db.sessionDao.getActiveSession();

    if (session == null) return null;

    return session.role == "admin" ? UserType.admin : UserType.counter;
  }
}
