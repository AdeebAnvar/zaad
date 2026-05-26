import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/core/utils/sales_csv_backup.dart';

import '../core/constants/enums.dart';
import '../data/local/drift_database.dart';

/// Result of schema version file handling (for tests).
@immutable
class SchemaStartupOutcome {
  const SchemaStartupOutcome({
    required this.previousLabel,
    required this.currentLabel,
    required this.schemaChanged,
    required this.databaseFilesDeleted,
  });

  final String? previousLabel;
  final String currentLabel;
  final bool schemaChanged;
  final bool databaseFilesDeleted;
}

class AppStartup {
  final AppDatabase db;

  AppStartup(this.db);

  @visibleForTesting
  static String schemaVersionLabel(int schemaVersion) => 'db_v$schemaVersion';

  /// Updates [data_schema_version.txt] only. Drift [MigrationStrategy.onUpgrade] migrates data in place.
  /// Never deletes [pos.sqlite] on schema bumps.
  @visibleForTesting
  static Future<SchemaStartupOutcome> syncSchemaVersionMetadata({
    required Directory localDir,
    required int schemaVersion,
  }) async {
    final current = schemaVersionLabel(schemaVersion);
    final versionFile = File(p.join(localDir.path, 'data_schema_version.txt'));

    String? lastVersion;
    if (await versionFile.exists()) {
      try {
        lastVersion = (await versionFile.readAsString()).trim();
        if (lastVersion.isEmpty) lastVersion = null;
      } catch (_) {
        lastVersion = null;
      }
    }

    final schemaChanged = lastVersion != null && lastVersion != current;

    try {
      await versionFile.writeAsString(current);
    } catch (_) {}

    return SchemaStartupOutcome(
      previousLabel: lastVersion,
      currentLabel: current,
      schemaChanged: schemaChanged,
      databaseFilesDeleted: false,
    );
  }

  Future<void> ensureCompatibleLocalData({Directory? localDirOverride}) async {
    final dir = localDirOverride ?? await AppDirectories.local();
    await syncSchemaVersionMetadata(
      localDir: dir,
      schemaVersion: db.schemaVersion,
    );

    // Do not block cold start on XLSX export (large order history can delay the window).
    unawaited(
      SalesCsvBackup.refreshFromDatabase(db).catchError((Object _, StackTrace __) {}),
    );
  }

  Future<UserType?> checkLoggedInUser() async {
    final session = await db.sessionDao.getActiveSession();

    if (session == null) return null;

    return session.role == "admin" ? UserType.admin : UserType.counter;
  }
}
