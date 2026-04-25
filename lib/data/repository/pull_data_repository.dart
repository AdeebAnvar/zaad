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
  Future<PullData> pullAndPersist();
}
