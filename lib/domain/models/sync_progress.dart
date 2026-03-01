import 'package:pos/core/constants/enums.dart';

class SyncProgress {
  final SyncStage stage;
  final int current;
  final int total;
  final String message;

  SyncProgress({
    required this.stage,
    this.current = 0,
    this.total = 0,
    required this.message,
  });
}
