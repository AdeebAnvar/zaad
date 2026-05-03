import 'package:pos/core/network/pos_api_service.dart';
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

/// Result of copying master data from the LAN Node hub (cloud mirror) into Drift.
class HubCatalogHydrateResult {
  const HubCatalogHydrateResult({
    required this.ok,
    required this.message,
    this.resourcesTouched = 0,
  });

  final bool ok;
  final String message;
  final int resourcesTouched;
}

abstract class PullDataRepository {
  Stream<PullSyncProgress> get progressStream;
  Future<PullData> pullAndPersist();

  /// LOCAL POS: fill categories, items, customers, etc. from the hub SQLite mirror
  /// (`GET /sync/mirror/...`). Requires the main machine hub to have completed at least
  /// one cloud pull so [cloud_mirror_entities] is populated.
  Future<HubCatalogHydrateResult> hydrateCatalogFromLanHub(PosApiService hubApi);
}
