import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/services/backup_restore_policy.dart';

void main() {
  group('BackupRestorePolicy.chooseRestoreCandidate', () {
    BackupSnapshotInfo snap({
      required String path,
      required int orders,
      required int bytes,
      int modified = 0,
      bool ok = true,
    }) {
      return BackupSnapshotInfo(
        path: path,
        orderCount: orders,
        fileBytes: bytes,
        modifiedMs: modified,
        integrityOk: ok,
      );
    }

    test('picks backup with most orders, not newest', () {
      final chosen = BackupRestorePolicy.chooseRestoreCandidate(
        snapshots: [
          snap(path: 'new_empty.db', orders: 50, bytes: 100_000_000, modified: 200),
          snap(path: 'old_full.db', orders: 1100, bytes: 140_000_000, modified: 100),
        ],
      );
      expect(chosen?.path, 'old_full.db');
    });

    test('rejects restore when best backup drops too many vs live', () {
      final chosen = BackupRestorePolicy.chooseRestoreCandidate(
        snapshots: [
          snap(path: 'bad.db', orders: 500, bytes: 140_000_000),
        ],
        liveOrderCount: 1100,
      );
      expect(chosen, isNull);
    });

    test('rejects undersized backup vs median', () {
      final chosen = BackupRestorePolicy.chooseRestoreCandidate(
        snapshots: [
          snap(path: 'tiny.db', orders: 1100, bytes: 50_000_000),
          snap(path: 'good_a.db', orders: 1090, bytes: 140_000_000),
          snap(path: 'good_b.db', orders: 1085, bytes: 145_000_000),
        ],
      );
      expect(chosen?.path, isNot('tiny.db'));
    });
  });

  group('BackupRestorePolicy.shouldRejectNewBackup', () {
    test('rejects large drop', () {
      expect(
        BackupRestorePolicy.shouldRejectNewBackup(
          newOrderCount: 500,
          bestKnownOrderCount: 1100,
        ),
        isTrue,
      );
    });

    test('allows small drop', () {
      expect(
        BackupRestorePolicy.shouldRejectNewBackup(
          newOrderCount: 1080,
          bestKnownOrderCount: 1100,
        ),
        isFalse,
      );
    });
  });
}
