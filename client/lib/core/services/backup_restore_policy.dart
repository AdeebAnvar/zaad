/// Pure logic for choosing a safe SQLite backup to restore (unit-testable).
class BackupSnapshotInfo {
  const BackupSnapshotInfo({
    required this.path,
    required this.orderCount,
    required this.fileBytes,
    required this.modifiedMs,
    required this.integrityOk,
  });

  final String path;
  final int orderCount;
  final int fileBytes;
  final int modifiedMs;
  final bool integrityOk;

  bool get isCandidate => integrityOk && fileBytes > 0;
}

class BackupRestorePolicy {
  BackupRestorePolicy._();

  /// Max allowed drop vs corrupt/live DB when restoring (5%).
  static const double maxDropVsLive = 0.05;

  /// Reject backups smaller than this fraction of the median backup size.
  static const double minSizeVsMedian = 0.72;

  /// Minimum completed backups to keep during purge (safety net).
  static const int minBackupsToRetain = 8;

  /// Reject a new backup if order count falls this much below best known snapshot.
  static const double maxDropVsBestBackup = 0.05;

  /// Pick the backup with the most orders among valid candidates, with guards.
  static BackupSnapshotInfo? chooseRestoreCandidate({
    required List<BackupSnapshotInfo> snapshots,
    int? liveOrderCount,
  }) {
    final candidates = snapshots.where((s) => s.isCandidate).toList();
    if (candidates.isEmpty) return null;

    final medianBytes = _median(candidates.map((c) => c.fileBytes).toList());
    final minBytes = medianBytes > 0 ? (medianBytes * minSizeVsMedian).round() : 1;

    final sized = candidates.where((c) => c.fileBytes >= minBytes).toList();
    final pool = sized.isNotEmpty ? sized : candidates;

    pool.sort((a, b) {
      final byOrders = b.orderCount.compareTo(a.orderCount);
      if (byOrders != 0) return byOrders;
      return b.modifiedMs.compareTo(a.modifiedMs);
    });

    final best = pool.first;

    if (liveOrderCount != null && liveOrderCount > 0) {
      final minAllowed = (liveOrderCount * (1 - maxDropVsLive)).floor();
      if (best.orderCount < minAllowed) {
        // Backup would wipe too many orders vs still-readable live file.
        return null;
      }
    }

    return best;
  }

  /// Whether a freshly written backup should be discarded.
  static bool shouldRejectNewBackup({
    required int newOrderCount,
    required int bestKnownOrderCount,
  }) {
    if (bestKnownOrderCount <= 0) return false;
    if (newOrderCount >= bestKnownOrderCount) return false;
    final minAllowed = (bestKnownOrderCount * (1 - maxDropVsBestBackup)).floor();
    return newOrderCount < minAllowed;
  }

  static int _median(List<int> values) {
    if (values.isEmpty) return 0;
    final sorted = List<int>.from(values)..sort();
    final mid = sorted.length ~/ 2;
    if (sorted.length.isOdd) return sorted[mid];
    return ((sorted[mid - 1] + sorted[mid]) / 2).round();
  }
}
