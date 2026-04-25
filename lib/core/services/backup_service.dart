import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const int _orderThreshold = 10;
  static const Duration _timeThreshold = Duration(minutes: 2);
  static const String _rootFolder = 'ZaadPOS';
  static const String _backupFolder = 'backup';

  int _pendingOrderMutations = 0;
  DateTime _lastBackupAt = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void> _queue = Future<void>.value();
  Timer? _periodicTimer;

  Future<Directory> _backupDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _rootFolder, _backupFolder));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

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
    } catch (_) {
      // Best-effort backup only.
    }
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
    }
  }

  Future<bool> restoreLatestBackupIfAvailable() async {
    try {
      final backupDir = await _backupDir();
      final files = await backupDir
          .list()
          .where((e) => e is File && p.extension(e.path).toLowerCase() == '.db')
          .cast<File>()
          .toList();
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

