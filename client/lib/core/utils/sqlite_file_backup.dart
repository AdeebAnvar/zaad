import 'dart:io';

import 'package:pos/data/local/drift_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// WAL-safe SQLite file copy for backups (checkpoint then copy main file).
class SqliteFileBackup {
  SqliteFileBackup._();

  /// Checkpoints WAL via [db], then copies [sourceDbFile] to [targetFile].
  static Future<void> copyWithWalCheckpoint({
    required AppDatabase db,
    required File sourceDbFile,
    required File targetFile,
  }) async {
    if (!await sourceDbFile.exists()) return;
    try {
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
    } catch (_) {
      /* best-effort before copy */
    }
    await sourceDbFile.copy(targetFile.path);
  }

  /// Order rows in [dbFile], or `-1` if unreadable.
  static int countOrders(File dbFile) {
    if (!dbFile.existsSync()) return -1;
    sqlite.Database? database;
    try {
      database = sqlite.sqlite3.open(dbFile.path, mode: sqlite.OpenMode.readOnly);
      if (!_tableExists(database, 'orders')) return 0;
      return _scalarInt(database, 'SELECT COUNT(*) FROM orders');
    } catch (_) {
      return -1;
    } finally {
      database?.dispose();
    }
  }

  static bool _tableExists(sqlite.Database database, String table) {
    final rows = database.select(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1",
      [table],
    );
    return rows.isNotEmpty;
  }

  static int _scalarInt(sqlite.Database database, String sql) {
    final rows = database.select(sql);
    if (rows.isEmpty) return 0;
    final value = rows.first.columnAt(0);
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Opens [dbFile] read-only and returns whether `PRAGMA quick_check` is ok.
  static bool quickCheckOk(File dbFile) {
    if (!dbFile.existsSync()) return false;
    sqlite.Database? database;
    try {
      database = sqlite.sqlite3.open(dbFile.path, mode: sqlite.OpenMode.readOnly);
      final result = database.select('PRAGMA quick_check;');
      final status = result.isNotEmpty ? result.first.columnAt(0)?.toString().toLowerCase() : 'ok';
      return status == 'ok';
    } catch (_) {
      return false;
    } finally {
      database?.dispose();
    }
  }

  /// Removes WAL sidecars next to [mainDbFile] (e.g. before restore).
  static Future<void> deleteWalSidecars(File mainDbFile) async {
    for (final suffix in const ['-wal', '-shm']) {
      final sidecar = File('${mainDbFile.path}$suffix');
      if (await sidecar.exists()) {
        try {
          await sidecar.delete();
        } catch (_) {}
      }
    }
  }
}
