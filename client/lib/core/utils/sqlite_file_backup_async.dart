import 'dart:io';

import 'package:pos/core/isolate/app_isolate_service.dart';
import 'package:pos/core/utils/sqlite_file_backup.dart';

/// Offloads synchronous sqlite3 file opens so backup/restore work does not block the UI isolate.
class SqliteFileBackupAsync {
  SqliteFileBackupAsync._();

  static Future<bool> quickCheckOk(File dbFile) {
    final path = dbFile.path;
    return AppIsolateService.instance.run(_quickCheckOkPath, path);
  }

  static Future<int> countOrders(File dbFile) {
    final path = dbFile.path;
    return AppIsolateService.instance.run(_countOrdersPath, path);
  }

  static bool _quickCheckOkPath(String path) => SqliteFileBackup.quickCheckOk(File(path));

  static int _countOrdersPath(String path) => SqliteFileBackup.countOrders(File(path));
}
