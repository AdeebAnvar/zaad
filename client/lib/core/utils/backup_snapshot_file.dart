import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Helpers for dated SQLite snapshots under [AppDirectories.backupDir].
class BackupSnapshotFile {
  BackupSnapshotFile._();

  static bool isSnapshot(String path) {
    final base = p.basename(path).toLowerCase();
    if (!base.startsWith('backup_')) return false;
    return base.endsWith('.db') || base.endsWith('.db.gz');
  }

  static bool isGzipSnapshot(String path) => path.toLowerCase().endsWith('.gz');

  /// Writes [dbFile] as gzip next to itself (`*.db.gz`) and removes the source.
  static Future<File> compressInPlace(File dbFile) async {
    final bytes = await dbFile.readAsBytes();
    final gzFile = File('${dbFile.path}.gz');
    await gzFile.writeAsBytes(gzip.encode(bytes), flush: true);
    await dbFile.delete();
    return gzFile;
  }

  /// Returns a readable `.db` path — materializes gzip snapshots into a temp file.
  static Future<File> materializeForSqlite(File snapshot) async {
    if (!isGzipSnapshot(snapshot.path)) return snapshot;
    final tempDir = await Directory.systemTemp.createTemp('pos_backup_read_');
    final out = File(p.join(tempDir.path, 'snapshot.db'));
    await out.writeAsBytes(gzip.decode(await snapshot.readAsBytes()), flush: true);
    return out;
  }

  /// Deletes a temp file created by [materializeForSqlite].
  static Future<void> deleteMaterialization(File materialized, File snapshot) async {
    if (materialized.path == snapshot.path) return;
    try {
      await materialized.parent.delete(recursive: true);
    } catch (_) {}
  }
}
