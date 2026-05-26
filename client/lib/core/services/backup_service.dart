import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:pos/core/services/backup_restore_policy.dart';
import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/core/utils/sqlite_file_backup.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Local SQLite safety copies under `Documents/ZaadPOS/backup`.
///
/// - [`_rollingBackupName`] is overwritten each successful backup (fast recovery).
/// - Timestamped copies only on [backupNow] `force: true` (day close, updates).
/// - Restore picks the backup with the **most orders**, not the newest file.
/// - Shrinking or corrupt snapshots are rejected.
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const String _rollingBackupName = 'latest.db';
  static const int _maxTimestampedBackups = 2;
  static const Duration _maxBackupAge = Duration(days: 7);
  static const Duration _minIntervalBetweenBackups = Duration(hours: 6);
  static const Duration _periodicCheckInterval = Duration(hours: 6);
  static const int _orderMutationBackupThreshold = 10;

  int? _lastBackedUpSize;
  DateTime? _lastBackedUpSourceModified;
  DateTime _lastBackupAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _pendingOrderMutations = 0;
  Future<void> _queue = Future<void>.value();
  Timer? _periodicTimer;

  Future<void> recordOrderMutation(AppDatabase db) async {
    _pendingOrderMutations += 1;
    final now = DateTime.now();
    final shouldBackup = _pendingOrderMutations >= _orderMutationBackupThreshold || now.difference(_lastBackupAt) >= _minIntervalBetweenBackups;
    if (!shouldBackup) return;
    await backupNow(db);
    _pendingOrderMutations = 0;
  }

  Future<Directory> _backupDir() => AppDirectories.backupDir();

  String _timestampedName(DateTime now) {
    String two(int v) => v.toString().padLeft(2, '0');
    return 'backup_${now.year}_${two(now.month)}_${two(now.day)}_${two(now.hour)}_${two(now.minute)}.db';
  }

  void startAutoBackup(AppDatabase db) {
    _periodicTimer?.cancel();
    // Purge scans every backup .db — defer so login UI is not frozen on cold start.
    Future<void>.delayed(const Duration(minutes: 3), () {
      unawaited(purgeExpiredBackups().catchError((Object e, StackTrace st) {
        _log('deferred purgeExpiredBackups: $e\n$st');
      }));
    });
    _periodicTimer = Timer.periodic(_periodicCheckInterval, (_) {
      backupNow(db);
    });
  }

  Future<void> backupNow(AppDatabase db, {bool force = false}) {
    _queue = _queue.then((_) => _doBackup(db, force: force));
    return _queue;
  }

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
      if (!SqliteFileBackup.quickCheckOk(dbFile)) {
        _log('Skipped backup: live database failed integrity check');
        return;
      }

      final sourceStat = await dbFile.stat();
      if (!force && _isUnchangedSinceLastBackup(sourceStat)) return;

      final backupDir = await _backupDir();
      final rolling = File(p.join(backupDir.path, _rollingBackupName));

      final rollingOk = await _safeCopyBackup(
        db: db,
        sourceDbFile: dbFile,
        targetFile: rolling,
      );
      if (!rollingOk) {
        _log('Skipped rolling backup: would shrink order history');
        return;
      }

      if (force) {
        final stamped = File(p.join(backupDir.path, _timestampedName(now)));
        await _safeCopyBackup(
          db: db,
          sourceDbFile: dbFile,
          targetFile: stamped,
        );
      }

      _lastBackedUpSize = sourceStat.size;
      _lastBackedUpSourceModified = sourceStat.modified;
      _lastBackupAt = now;
      _pendingOrderMutations = 0;
      await _pruneOldBackups();
    } catch (e, st) {
      _log('Backup failed: $e\n$st');
    }
  }

  Future<bool> _safeCopyBackup({
    required AppDatabase db,
    required File sourceDbFile,
    required File targetFile,
  }) async {
    final liveOrders = SqliteFileBackup.countOrders(sourceDbFile);
    if (liveOrders < 0) return false;

    var bestKnown = await _maxOrderCountInBackups(exclude: targetFile.path);
    if (await targetFile.exists()) {
      final existing = SqliteFileBackup.countOrders(targetFile);
      if (existing > bestKnown) bestKnown = existing;
    }

    if (BackupRestorePolicy.shouldRejectNewBackup(
      newOrderCount: liveOrders,
      bestKnownOrderCount: bestKnown,
    )) {
      return false;
    }

    await SqliteFileBackup.copyWithWalCheckpoint(
      db: db,
      sourceDbFile: sourceDbFile,
      targetFile: targetFile,
    );

    if (!SqliteFileBackup.quickCheckOk(targetFile)) {
      await _deleteIfExists(targetFile);
      _log('Discarded backup: integrity check failed (${targetFile.path})');
      return false;
    }

    final copiedOrders = SqliteFileBackup.countOrders(targetFile);
    if (BackupRestorePolicy.shouldRejectNewBackup(
      newOrderCount: copiedOrders,
      bestKnownOrderCount: bestKnown,
    )) {
      await _deleteIfExists(targetFile);
      _log('Discarded backup: order count dropped ($copiedOrders vs $bestKnown)');
      return false;
    }

    return true;
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
          if (await _backupFileIsFullySynced(file)) {
            await _deleteIfExists(file);
          }
        }
      }

      if (await rolling.exists()) {
        final rollingAge = (await rolling.stat()).modified;
        if (rollingAge.isBefore(cutoff)) {
          await _deleteIfExists(rolling);
        }
      }

      await purgeExpiredBackups();
    } catch (e, st) {
      _log('_pruneOldBackups: $e\n$st');
    }
  }

  Future<void> purgeExpiredBackups() async {
    try {
      final backupDir = await _backupDir();
      if (!await backupDir.exists()) return;

      final files = await _listBackupDbFiles(backupDir);
      if (files.length <= BackupRestorePolicy.minBackupsToRetain) return;

      final snapshots = await _inspectAll(files);
      if (snapshots.isEmpty) return;

      final bestOrders = snapshots.map((s) => s.orderCount).reduce((a, b) => a > b ? a : b);
      final bestPath = snapshots.firstWhere((s) => s.orderCount == bestOrders).path;

      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      final cutoff = DateTime.now().subtract(_maxBackupAge);

      var kept = 0;
      for (final file in files) {
        if (file.path == bestPath) continue;
        if (p.basename(file.path) == _rollingBackupName) continue;

        if (kept < BackupRestorePolicy.minBackupsToRetain) {
          kept++;
          continue;
        }

        final modified = file.statSync().modified;
        if (!modified.isBefore(cutoff)) continue;

        if (await _backupFileIsFullySynced(file)) {
          await _deleteIfExists(file);
        }
      }
    } catch (e, st) {
      _log('purgeExpiredBackups: $e\n$st');
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
      final outboxPending = _scalarInt(database, "SELECT COUNT(*) FROM sync_outbox WHERE status IS NULL OR status != 'ACKED'");
      if (outboxPending > 0) return false;
    }

    if (_tableExists(database, 'settle_sales_outbox')) {
      final settlePending = _scalarInt(database, 'SELECT COUNT(*) FROM settle_sales_outbox WHERE synced = 0');
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

  /// Fast path for cold start: only checks the newest backup files (not every `.db`).
  Future<bool> quickEnsureDatabaseBeforeOpen({int maxCandidates = 3}) async {
    try {
      final localDir = await AppDirectories.local();
      final dbFile = File(p.join(localDir.path, 'pos.sqlite'));
      if (await dbFile.exists() && SqliteFileBackup.quickCheckOk(dbFile)) {
        return true;
      }
      return restoreNewestBackupQuick(
        corruptLiveFile: await dbFile.exists() ? dbFile : null,
        maxCandidates: maxCandidates,
      );
    } catch (e, st) {
      _log('quickEnsureDatabaseBeforeOpen: $e\n$st');
      return false;
    }
  }

  Future<void> validateAndRecoverIfNeeded() async {
    await _pruneOldBackups();
    try {
      final localDir = await AppDirectories.local();
      final dbFile = File(p.join(localDir.path, 'pos.sqlite'));
      if (!await dbFile.exists()) {
        await restoreLatestBackupIfAvailable();
        return;
      }

      final integrityOk = SqliteFileBackup.quickCheckOk(dbFile);
      if (integrityOk) return;

      _log('Live database corrupt — attempting safe restore');
      await restoreLatestBackupIfAvailable(corruptLiveFile: dbFile);
    } catch (e, st) {
      _log('validateAndRecoverIfNeeded: $e\n$st');
      final localDir = await AppDirectories.local();
      final dbFile = File(p.join(localDir.path, 'pos.sqlite'));
      if (await dbFile.exists()) {
        await restoreLatestBackupIfAvailable(corruptLiveFile: dbFile);
      } else {
        await restoreLatestBackupIfAvailable();
      }
    }
    // Do not purge backups here — opening every backup DB on cold start blocked the
    // UI thread ("Not responding"). [startAutoBackup] schedules purge in background.
  }

  /// Startup-only: restore from the newest few backups (avoids scanning dozens of `.db` files).
  Future<bool> restoreNewestBackupQuick({
    File? corruptLiveFile,
    int maxCandidates = 3,
  }) async {
    try {
      final backupDir = await _backupDir();
      final files = await _listBackupDbFiles(backupDir);
      if (files.isEmpty) {
        _log('quick restore: no backup files');
        return false;
      }

      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      final localDir = await AppDirectories.local();
      final target = File(p.join(localDir.path, 'pos.sqlite'));

      for (final source in files.take(maxCandidates)) {
        if (!SqliteFileBackup.quickCheckOk(source)) continue;

        if (corruptLiveFile != null && await corruptLiveFile.exists()) {
          await _quarantineFile(corruptLiveFile, prefix: 'pos.sqlite.corrupt_');
        } else if (await target.exists()) {
          await _quarantineFile(target, prefix: 'pos.sqlite.before_restore_');
        }

        await SqliteFileBackup.deleteWalSidecars(target);
        if (await target.exists()) {
          await target.delete();
        }
        await source.copy(target.path);
        await SqliteFileBackup.deleteWalSidecars(target);

        if (SqliteFileBackup.quickCheckOk(target)) {
          _log('quick restore from ${p.basename(source.path)}');
          return true;
        }
        await _quarantineFile(target, prefix: 'pos.sqlite.bad_restore_');
      }
      return false;
    } catch (e, st) {
      _log('restoreNewestBackupQuick: $e\n$st');
      return false;
    }
  }

  Future<bool> restoreLatestBackupIfAvailable({File? corruptLiveFile}) async {
    try {
      final backupDir = await _backupDir();
      final files = await _listBackupDbFiles(backupDir);
      if (files.isEmpty) {
        _log('No backup files found — cannot restore');
        return false;
      }

      final snapshots = await _inspectAll(files);
      final liveOrders = corruptLiveFile != null && await corruptLiveFile.exists() ? SqliteFileBackup.countOrders(corruptLiveFile) : null;
      final liveCount = liveOrders != null && liveOrders >= 0 ? liveOrders : null;

      final chosen = BackupRestorePolicy.chooseRestoreCandidate(
        snapshots: snapshots,
        liveOrderCount: liveCount,
      );

      if (chosen == null) {
        _log(
          'Safe restore aborted: no backup passes order-count guards (live=${liveCount ?? 'n/a'})',
        );
        if (corruptLiveFile != null && await corruptLiveFile.exists()) {
          await _quarantineFile(corruptLiveFile, prefix: 'pos.sqlite.unrestored_');
        }
        return false;
      }

      final source = File(chosen.path);
      final localDir = await AppDirectories.local();
      final target = File(p.join(localDir.path, 'pos.sqlite'));

      if (corruptLiveFile != null && await corruptLiveFile.exists()) {
        await _quarantineFile(corruptLiveFile, prefix: 'pos.sqlite.corrupt_');
      } else if (await target.exists()) {
        await _quarantineFile(target, prefix: 'pos.sqlite.before_restore_');
      }

      await SqliteFileBackup.deleteWalSidecars(target);
      if (await target.exists()) {
        await target.delete();
      }
      await source.copy(target.path);
      await SqliteFileBackup.deleteWalSidecars(target);

      if (!SqliteFileBackup.quickCheckOk(target)) {
        _log('Restore failed integrity check — quarantining restored file');
        await _quarantineFile(target, prefix: 'pos.sqlite.bad_restore_');
        return false;
      }

      _log(
        'Restored ${chosen.orderCount} orders from ${p.basename(chosen.path)} '
        '(live had ${liveCount ?? 'n/a'})',
      );
      return true;
    } catch (e, st) {
      _log('restoreLatestBackupIfAvailable: $e\n$st');
      return false;
    }
  }

  Future<List<File>> _listBackupDbFiles(Directory backupDir) async {
    return backupDir.list().where((e) => e is File && p.extension(e.path).toLowerCase() == '.db').cast<File>().toList();
  }

  Future<List<BackupSnapshotInfo>> _inspectAll(List<File> files) async {
    final out = <BackupSnapshotInfo>[];
    for (final file in files) {
      final stat = file.statSync();
      out.add(
        BackupSnapshotInfo(
          path: file.path,
          orderCount: SqliteFileBackup.countOrders(file),
          fileBytes: stat.size,
          modifiedMs: stat.modified.millisecondsSinceEpoch,
          integrityOk: SqliteFileBackup.quickCheckOk(file),
        ),
      );
    }
    return out;
  }

  Future<int> _maxOrderCountInBackups({String? exclude}) async {
    final backupDir = await _backupDir();
    if (!await backupDir.exists()) return 0;
    final files = await _listBackupDbFiles(backupDir);
    var max = 0;
    for (final file in files) {
      if (exclude != null && file.path == exclude) continue;
      if (!SqliteFileBackup.quickCheckOk(file)) continue;
      final n = SqliteFileBackup.countOrders(file);
      if (n > max) max = n;
    }
    return max;
  }

  Future<void> _quarantineFile(File file, {required String prefix}) async {
    try {
      final dir = file.parent;
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final dest = File(p.join(dir.path, '$prefix$stamp.db'));
      if (await dest.exists()) await dest.delete();
      await file.rename(dest.path);
      await SqliteFileBackup.deleteWalSidecars(dest);
      _log('Quarantined ${file.path} -> ${dest.path}');
    } catch (e, st) {
      _log('Quarantine failed for ${file.path}: $e\n$st');
    }
  }

  Future<void> _deleteIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> _log(String message) async {
    debugPrint('[BackupService] $message');
    try {
      final backupDir = await _backupDir();
      final logFile = File(p.join(backupDir.path, 'recovery.log'));
      final line = '${DateTime.now().toIso8601String()} $message\n';
      await logFile.writeAsString(line, mode: FileMode.append, flush: true);
    } catch (_) {}
  }
}
