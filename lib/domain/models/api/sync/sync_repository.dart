import 'sync_api.dart';

class SyncRepository {
  final SyncApi api;

  SyncRepository(this.api);

  Future<void> pullAllData() async {
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final response = await api.pullData();

      final data = response.data;

      // Save each module locally
      // category, unit, item, etc.

      final totalPages = data['total_pages'];

      if (page >= totalPages) {
        hasMore = false;
      } else {
        page++;
      }
    }
  }
}
