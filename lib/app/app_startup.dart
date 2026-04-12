import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/constants/enums.dart';
import '../data/local/drift_database.dart';

class AppStartup {
  final AppDatabase db;

  AppStartup(this.db);

  /// Clears incompatible local cache (DB file) on app update.
  ///
  /// Strategy:
  /// - Persist the last-used data schema version in a small text file.
  /// - Compare it with current Drift schema version.
  /// - If versions differ, delete the Drift SQLite file so a fresh DB
  ///   is created for the new build (all local cache reset).
  ///
  /// This runs once per version and is platform-agnostic (Android, Windows, etc.).
  Future<void> ensureCompatibleLocalData() async {
    final currentDataSchemaVersion = 'db_v${db.schemaVersion}';
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

    if (lastVersion == currentDataSchemaVersion) {
      // Same schema version as last time – nothing to do.
      return;
    }

    // Version changed – clear Drift DB so we don't crash on incompatible schema.
    for (final fileName in const ['pos.sqlite', 'pos.sqlite-shm', 'pos.sqlite-wal']) {
      try {
        final dbFile = File(p.join(dir.path, fileName));
        if (await dbFile.exists()) {
          await dbFile.delete();
        }
      } catch (_) {
        // If deletion fails, we still proceed; Drift may attempt migrations.
      }
    }

    try {
      await versionFile.writeAsString(currentDataSchemaVersion);
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
