import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const int _orderThreshold = 10;
  static const Duration _timeThreshold = Duration(minutes: 2);
  static const Duration _retention = Duration(days: 3);

  int _pendingOrderMutations = 0;
  DateTime _lastBackupAt = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void> _queue = Future<void>.value();
  Timer? _periodicTimer;

  Future<Directory> _backupDir() => AppDirectories.backupDir();

  String _fileName(DateTime now) {
    String two(int v) => v.toString().padLeft(2, '0');
    return 'backup_${now.year}_${two(now.month)}_${two(now.day)}_${two(now.hour)}_${two(now.minute)}.db';
  }

  Future<void> recordOrderMutation(AppDatabase db) async {
    _pendingOrderMutations += 1;
    final now = DateTime.now();
    final shouldBackup = _pendingOrderMutations >= _orderThreshold || now.difference(_lastBackupAt) >= _timeThreshold;
    if (!shouldBackup) return;
    await backupNow(db);
  }

  void startAutoBackup(AppDatabase db) {
    _periodicTimer?.cancel();
    unawaited(purgeExpiredBackups());
    _periodicTimer = Timer.periodic(_timeThreshold, (_) {
      backupNow(db);
    });
  }

  Future<void> backupNow(AppDatabase db) {
    _queue = _queue.then((_) => _doBackup(db));
    return _queue;
  }

  Future<void> _doBackup(AppDatabase db) async {
    try {
      final localDir = await AppDirectories.local();
      final dbFile = File(p.join(localDir.path, 'pos.sqlite'));
      if (!await dbFile.exists()) return;

      final backupDir = await _backupDir();
      final target = File(p.join(backupDir.path, _fileName(DateTime.now())));
      await dbFile.copy(target.path);
      _pendingOrderMutations = 0;
      _lastBackupAt = DateTime.now();
      await purgeExpiredBackups();
    } catch (_) {
      // Best-effort backup only.
    }
  }

  /// Removes SQLite backup copies older than [_retention] when that snapshot has no pending sync.
  Future<void> purgeExpiredBackups() async {
    try {
      final backupDir = await _backupDir();
      if (!await backupDir.exists()) return;

      final files = await backupDir
          .list()
          .where((e) => e is File && p.extension(e.path).toLowerCase() == '.db')
          .cast<File>()
          .toList();
      if (files.length <= 1) return;

      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      final latestPath = files.first.path;
      final cutoff = DateTime.now().subtract(_retention);

      for (final file in files) {
        if (file.path == latestPath) continue;

        final modified = file.statSync().modified;
        if (!modified.isBefore(cutoff)) continue;

        if (await _backupFileIsFullySynced(file)) {
          await file.delete();
        }
      }
    } catch (_) {
      // Best-effort cleanup only.
    }
  }

  Future<bool> _backupFileIsFullySynced(File backupFile) async {
    sqlite.Database? database;
    try {
      database = sqlite.sqlite3.open(backupFile.path);
      return _sqliteSnapshotIsFullySynced(database);
    } catch (_) {
      return false;
    } finally {
      database?.dispose();
    }
  }

  static bool _sqliteSnapshotIsFullySynced(sqlite.Database database) {
    if (_tableExists(database, 'order_logs')) {
      final unsyncedLogs = _scalarInt(database, 'SELECT COUNT(*) FROM order_logs WHERE synced = 0');
      if (unsyncedLogs > 0) return false;
    }

    if (_tableExists(database, 'orders') && _columnExists(database, 'orders', 'hub_sync_pending')) {
      final hubPending = _scalarInt(database, 'SELECT COUNT(*) FROM orders WHERE hub_sync_pending = 1');
      if (hubPending > 0) return false;
    }

    if (_tableExists(database, 'sync_outbox')) {
      final outboxPending =
          _scalarInt(database, "SELECT COUNT(*) FROM sync_outbox WHERE status IS NULL OR status != 'ACKED'");
      if (outboxPending > 0) return false;
    }

    if (_tableExists(database, 'settle_sales_outbox')) {
      final settlePending =
          _scalarInt(database, 'SELECT COUNT(*) FROM settle_sales_outbox WHERE synced = 0');
      if (settlePending > 0) return false;
    }

    if (_tableExists(database, 'customers') && _columnExists(database, 'customers', 'synced')) {
      final customersPending = _scalarInt(database, 'SELECT COUNT(*) FROM customers WHERE synced = 0');
      if (customersPending > 0) return false;
    }

    return true;
  }

  static bool _tableExists(sqlite.Database database, String table) {
    final rows = database.select(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1",
      [table],
    );
    return rows.isNotEmpty;
  }

  static bool _columnExists(sqlite.Database database, String table, String column) {
    final rows = database.select('PRAGMA table_info($table)');
    for (final row in rows) {
      if (row.columnAt(1)?.toString() == column) return true;
    }
    return false;
  }

  static int _scalarInt(sqlite.Database database, String sql) {
    final rows = database.select(sql);
    if (rows.isEmpty) return 0;
    final value = rows.first.columnAt(0);
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> validateAndRecoverIfNeeded() async {
    try {
      final localDir = await AppDirectories.local();
      final dbFile = File(p.join(localDir.path, 'pos.sqlite'));
      if (!await dbFile.exists()) return;
      final database = sqlite.sqlite3.open(dbFile.path);
      try {
        final result = database.select('PRAGMA quick_check;');
        final status = result.isNotEmpty ? result.first.columnAt(0)?.toString().toLowerCase() : 'ok';
        if (status != 'ok') {
          await restoreLatestBackupIfAvailable();
        }
      } finally {
        database.dispose();
      }
    } catch (_) {
      await restoreLatestBackupIfAvailable();
    } finally {
      await purgeExpiredBackups();
    }
  }

  Future<bool> restoreLatestBackupIfAvailable() async {
    try {
      final backupDir = await _backupDir();
      final files = await backupDir.list().where((e) => e is File && p.extension(e.path).toLowerCase() == '.db').cast<File>().toList();
      if (files.isEmpty) return false;
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      final latest = files.first;

      final localDir = await AppDirectories.local();
      final target = File(p.join(localDir.path, 'pos.sqlite'));
      if (await target.exists()) {
        await target.delete();
      }
      await latest.copy(target.path);
      return true;
    } catch (_) {
      return false;
    }
  }
}
