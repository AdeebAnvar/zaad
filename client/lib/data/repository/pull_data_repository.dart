import 'package:pos/domain/models/category_model.dart';
import 'package:pos/domain/models/item_model.dart';
import 'package:pos/domain/models/pull_data_model.dart';

class PullSyncProgress {
  final String message;
  final int current;
  final int total;

  const PullSyncProgress({
    required this.message,
    required this.current,
    required this.total,
  });
}

abstract class PullDataRepository {
  Stream<PullSyncProgress> get progressStream;

  /// When [deferLanHubMirrorUntilAfterCloudSync] is true, skips LAN WebSocket catalog + company snapshot
  /// broadcast during pull so cloud push can run first — call [runDeferredLanHubMirrorBestEffort] afterward.
  Future<PullData> pullAndPersist({bool deferLanHubMirrorUntilAfterCloudSync = false});

  /// Mirrors catalog + COMPANY_SNAPSHOT to the Node hub after tenant pull/push (no-op if nothing pending).
  Future<void> runDeferredLanHubMirrorBestEffort();

  /// True after [pullAndPersist(deferLanHubMirrorUntilAfterCloudSync: true)] completes until
  /// [runDeferredLanHubMirrorBestEffort] begins (used to avoid duplicate LAN traffic during push).
  bool get pendingDeferredLanHubMirror;

  /// SUB / LAN: apply MAIN-broadcast ITEM_UPSERT (+ optional decoded local image).
  Future<void> upsertLanHubItemSnapshot(ItemCreatedUpdated item, {String? localImagePath});

  /// SUB / LAN: apply MAIN-broadcast CATEGORY_UPSERT.
  Future<void> upsertLanHubCategory(CategoryCreatedUpdated category);

  /// SUB / LAN: apply one mirrored [pull_records] JSON body from MAIN (no tenant HTTP).
  Future<void> applyMirroredPullPage(dynamic responseBody);
}
