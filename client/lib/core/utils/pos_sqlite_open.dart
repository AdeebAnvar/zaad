import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/core/utils/sqlite_file_backup.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Opens [AppDatabase] with retries, clearer errors, and safe WAL recovery when alone.
class PosSqliteOpen {
  PosSqliteOpen._();

  static const Duration _probeTimeout = Duration(seconds: 45);
  static const int _maxAttempts = 3;

  static Future<AppDatabase> openAppDatabase() async {
    final localDir = await AppDirectories.local();
    final dbFile = File(p.join(localDir.path, 'pos.sqlite'));
    Object? lastError;

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      final db = AppDatabase();
      try {
        await _probeDatabase(db).timeout(
          _probeTimeout,
          onTimeout: () => throw TimeoutException(
            'open timed out after ${_probeTimeout.inSeconds}s',
            _probeTimeout,
          ),
        );
        return db;
      } on TimeoutException catch (e) {
        lastError = e;
        await _safeClose(db);
        if (attempt < _maxAttempts) {
          await Future<void>.delayed(Duration(seconds: attempt * 2));
          continue;
        }
        throw StateError(_timeoutMessage(dbFile));
      } on SqliteException catch (e) {
        lastError = e;
        await _safeClose(db);
        final busy = _isBusyOrLocked(e);
        if (busy && attempt < _maxAttempts) {
          await Future<void>.delayed(Duration(seconds: attempt * 2));
          if (await _tryRecoverStaleWalSidecars(dbFile)) {
            continue;
          }
          continue;
        }
        if (busy) {
          throw StateError(await _busyMessage(dbFile, e));
        }
        throw StateError(
          'Could not open local database (${sqliteExceptionSummary(e)}). '
          'Path: ${dbFile.path}',
        );
      } on StateError {
        rethrow;
      } catch (e) {
        lastError = e;
        await _safeClose(db);
        if (attempt < _maxAttempts) {
          await Future<void>.delayed(Duration(seconds: attempt));
          continue;
        }
        throw StateError(
          'Could not open local database ($e).\n'
          'Path: ${dbFile.path}',
        );
      }
    }

    throw StateError(
      'Could not open local database ($lastError).\n'
      'Path: ${dbFile.path}',
    );
  }

  static Future<void> _probeDatabase(AppDatabase db) async {
    await db.customSelect('SELECT 1').get();
  }

  static Future<void> _safeClose(AppDatabase db) async {
    try {
      await db.close();
    } catch (_) {}
  }

  static bool _isBusyOrLocked(SqliteException e) {
    final m = e.message.toLowerCase();
    return m.contains('locked') ||
        m.contains('busy') ||
        e.extendedResultCode == 5 ||
        e.extendedResultCode == 6;
  }

  /// When a crashed instance left WAL sidecars, try checkpoint or remove them if exclusive access works.
  static Future<bool> _tryRecoverStaleWalSidecars(File dbFile) async {
    if (!await dbFile.exists()) return false;

    final wal = File('${dbFile.path}-wal');
    final shm = File('${dbFile.path}-shm');
    if (!await wal.exists() && !await shm.exists()) return false;

    if (!await _canTakeExclusiveLock(dbFile.path)) {
      if (kDebugMode) {
        debugPrint('[PosSqliteOpen] WAL recovery skipped — database still locked by another process');
      }
      return false;
    }

    try {
      await SqliteFileBackup.deleteWalSidecars(dbFile);
      if (kDebugMode) {
        debugPrint('[PosSqliteOpen] Removed stale WAL sidecars: ${dbFile.path}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PosSqliteOpen] WAL sidecar cleanup failed: $e');
      }
      return false;
    }
  }

  static Future<bool> _canTakeExclusiveLock(String dbPath) async {
    sqlite.Database? raw;
    try {
      raw = sqlite.sqlite3.open(dbPath);
      raw.execute('PRAGMA busy_timeout = 500;');
      raw.execute('BEGIN IMMEDIATE');
      raw.execute('ROLLBACK');
      return true;
    } catch (_) {
      return false;
    } finally {
      raw?.dispose();
    }
  }

  /// Windows: how many `pos.exe` processes are running (includes this instance).
  static Future<int> countPosExeProcesses() async {
    if (!Platform.isWindows) return 0;
    try {
      final result = await Process.run(
        'tasklist',
        ['/FI', 'IMAGENAME eq pos.exe', '/NH'],
        runInShell: true,
      );
      final out = (result.stdout as String? ?? '').toLowerCase();
      if (out.contains('no tasks') || out.trim().isEmpty) return 0;
      return 'pos.exe'.allMatches(out).length;
    } catch (_) {
      return -1;
    }
  }

  static String _timeoutMessage(File dbFile) {
    final parent = dbFile.parent.parent.path;
    final posCount = Platform.isWindows ? ' (checking Task Manager)' : '';
    return 'Zaad POS could not open its database in time$posCount.\n\n'
        'This often happens when:\n'
        '• Documents or ZaadPOS is on OneDrive (slow sync)\n'
        '• A hidden "pos" process is still running — end it in Task Manager\n'
        '• Antivirus is scanning pos.sqlite\n\n'
        'Try:\n'
        '1. End every "pos" task in Task Manager, wait 10 seconds\n'
        '2. Pause OneDrive sync, or move data to C:\\ZaadPOS\n'
        '3. Restart the PC\n\n'
        'Database folder:\n$parent';
  }

  static Future<String> _busyMessage(File dbFile, SqliteException e) async {
    final parent = dbFile.parent.parent.path;
    var extra = '';
    if (Platform.isWindows) {
      final count = await countPosExeProcesses();
      if (count <= 0) {
        extra = '\n\nNo "pos" process was found — the file may be locked by OneDrive, '
            'antivirus, or a stale lock. Restart the PC or pause OneDrive, then try again.';
      } else if (count == 1) {
        extra = '\n\nOnly this Zaad POS instance is running — if the error repeats, '
            'restart the PC to clear a stale database lock.';
      } else {
        extra = '\n\nFound $count "pos" processes — end all but one in Task Manager.';
      }
    }
    return 'Zaad POS could not open its local database (locked).\n\n'
        '${sqliteExceptionSummary(e)}$extra\n\n'
        'Database folder:\n$parent';
  }
}

String sqliteExceptionSummary(SqliteException error) =>
    'SQLite (${error.extendedResultCode}): ${error.message}';
