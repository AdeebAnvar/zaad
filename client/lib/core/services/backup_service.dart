import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Local SQLite safety copies under `Documents/ZaadPOS/backup`.
///
/// - [`_rollingBackupName`] is overwritten each time (fast recovery, 1 file).
/// - Timestamped copies only on [backupNow] `force: true` (day close, updates).
/// - Periodic timer only (no backup on every order).
/// - Skips copy when DB size/mtime unchanged since last successful backup.
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const String _rollingBackupName = 'latest.db';

  static const int _maxTimestampedBackups = 2;

  static const Duration _maxBackupAge = Duration(days: 7);

  static const Duration _minIntervalBetweenBackups = Duration(hours: 6);

  static const Duration _periodicCheckInterval = Duration(hours: 6);

  int? _lastBackedUpSize;
  DateTime? _lastBackedUpSourceModified;
  DateTime _lastBackupAt = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void> _queue = Future<void>.value();
  Timer? _periodicTimer;

  Future<Directory> _backupDir() => AppDirectories.backupDir();

  String _timestampedName(DateTime now) {
    String two(int v) => v.toString().padLeft(2, '0');
    return 'backup_${now.year}_${two(now.month)}_${two(now.day)}_${two(now.hour)}_${two(now.minute)}.db';
  }

  void startAutoBackup(AppDatabase db) {
    _periodicTimer?.cancel();
    unawaited(_pruneOldBackups());
    _periodicTimer = Timer.periodic(_periodicCheckInterval, (_) {
      backupNow(db);
    });
  }

  /// Queued backup. Use `force: true` for day close / pre-update (adds timestamped file).
  Future<void> backupNow(AppDatabase db, {bool force = false}) {
    _queue = _queue.then((_) => _doBackup(db, force: force));
    return _queue;
  }

  /// WAL checkpoint + optional `VACUUM` to reclaim free pages (run on day close).
  Future<void> maintainDatabase(AppDatabase db, {bool vacuum = false}) async {
    try {
      await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
      if (vacuum) {
        await db.customStatement('VACUUM;');
      } else {
        await db.customStatement('PRAGMA optimize;');
      }
    } catch (_) {}
  }

  Future<void> _doBackup(AppDatabase db, {required bool force}) async {
    try {
      final now = DateTime.now();
      if (!force && now.difference(_lastBackupAt) < _minIntervalBetweenBackups) return;

      final localDir = await AppDirectories.local();
      final dbFile = File(p.join(localDir.path, 'pos.sqlite'));
      if (!await dbFile.exists()) return;

      final sourceStat = await dbFile.stat();
      if (!force && _isUnchangedSinceLastBackup(sourceStat)) return;

      try {
        await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
      } catch (_) {}

      final backupDir = await _backupDir();
      final rolling = File(p.join(backupDir.path, _rollingBackupName));
      await dbFile.copy(rolling.path);

      if (force) {
        await dbFile.copy(p.join(backupDir.path, _timestampedName(now)));
      }

      _lastBackedUpSize = sourceStat.size;
      _lastBackedUpSourceModified = sourceStat.modified;
      _lastBackupAt = now;
      await _pruneOldBackups();
    } catch (_) {}
  }

  bool _isUnchangedSinceLastBackup(FileStat sourceStat) {
    if (_lastBackedUpSize == null || _lastBackedUpSourceModified == null) return false;
    if (sourceStat.size != _lastBackedUpSize) return false;
    return !sourceStat.modified.isAfter(_lastBackedUpSourceModified!);
  }

  Future<void> _pruneOldBackups() async {
    try {
      final backupDir = await _backupDir();
      if (!await backupDir.exists()) return;

      final rolling = File(p.join(backupDir.path, _rollingBackupName));
      final timestamped = <File>[];

      await for (final entity in backupDir.list()) {
        if (entity is! File) continue;
        if (p.extension(entity.path).toLowerCase() != '.db') continue;
        final name = p.basename(entity.path);
        if (name == _rollingBackupName) continue;
        if (name.startsWith('backup_')) timestamped.add(entity);
      }

      timestamped.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      final cutoff = DateTime.now().subtract(_maxBackupAge);
      for (var i = 0; i < timestamped.length; i++) {
        final file = timestamped[i];
        final modified = file.statSync().modified;
        if (i >= _maxTimestampedBackups || modified.isBefore(cutoff)) {
          try {
            await file.delete();
          } catch (_) {}
        }
      }

      if (await rolling.exists()) {
        final rollingAge = (await rolling.stat()).modified;
        if (rollingAge.isBefore(cutoff)) {
          try {
            await rolling.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<void> validateAndRecoverIfNeeded() async {
    await _pruneOldBackups();
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
    }
  }

  Future<bool> restoreLatestBackupIfAvailable() async {
    try {
      final backupDir = await _backupDir();
      final candidates = <File>[];

      final rolling = File(p.join(backupDir.path, _rollingBackupName));
      if (await rolling.exists()) candidates.add(rolling);

      await for (final entity in backupDir.list()) {
        if (entity is File &&
            p.extension(entity.path).toLowerCase() == '.db' &&
            p.basename(entity.path) != _rollingBackupName) {
          candidates.add(entity);
        }
      }
      if (candidates.isEmpty) return false;

      candidates.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      final latest = candidates.first;

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
