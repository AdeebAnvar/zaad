import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pos/core/utils/backup_snapshot_file.dart';

void main() {
  test('compressInPlace round-trips readable sqlite bytes', () async {
    final dir = await Directory.systemTemp.createTemp('backup_snapshot_test_');
    try {
      final db = File(p.join(dir.path, 'backup_2026_05_30_12_00.db'));
      await db.writeAsBytes(List<int>.filled(4096, 7));

      final gz = await BackupSnapshotFile.compressInPlace(db);
      expect(await db.exists(), isFalse);
      expect(gz.path.endsWith('.db.gz'), isTrue);
      expect(BackupSnapshotFile.isSnapshot(gz.path), isTrue);

      final readable = await BackupSnapshotFile.materializeForSqlite(gz);
      try {
        expect(await readable.length(), 4096);
        expect(await readable.readAsBytes(), List<int>.filled(4096, 7));
      } finally {
        await BackupSnapshotFile.deleteMaterialization(readable, gz);
      }
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('isSnapshot ignores quarantine and log files', () {
    expect(BackupSnapshotFile.isSnapshot(r'C:\ZaadPOS\backup\backup_2026_01_01_00_00.db'), isTrue);
    expect(BackupSnapshotFile.isSnapshot(r'C:\ZaadPOS\backup\backup_2026_01_01_00_00.db.gz'), isTrue);
    expect(BackupSnapshotFile.isSnapshot(r'C:\ZaadPOS\local\pos.sqlite.corrupt_x.db'), isFalse);
    expect(BackupSnapshotFile.isSnapshot(r'C:\ZaadPOS\backup\recovery.log'), isFalse);
  });
}
