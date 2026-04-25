import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/core/utils/sales_csv_backup.dart';

import '../core/constants/enums.dart';
import '../data/local/drift_database.dart';

class AppStartup {
  final AppDatabase db;

  AppStartup(this.db);

  Future<void> ensureCompatibleLocalData() async {
    final currentDataSchemaVersion = 'db_v${db.schemaVersion}';
    final dir = await AppDirectories.local();
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
      // Same schema version as last time.
      try {
        await SalesCsvBackup.refreshFromDatabase(db);
      } catch (_) {
        // Best-effort backup only.
      }
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

    // Keep crash-safe XLSX backup in sync with local orders snapshot.
    try {
      await SalesCsvBackup.refreshFromDatabase(db);
    } catch (_) {
      // Best-effort backup only.
    }
  }

  Future<UserType?> checkLoggedInUser() async {
    final session = await db.sessionDao.getActiveSession();

    if (session == null) return null;

    return session.role == "admin" ? UserType.admin : UserType.counter;
  }
}
