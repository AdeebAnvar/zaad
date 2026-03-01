enum UserType { admin, counter }

enum SyncPhase { idle, categories, items, success, failed }

enum SaleMode { takeAway, delivery, counter }

enum SyncStage { categories, items, completed, failed }

class SyncStatus {
  final SyncPhase phase;
  final int current;
  final int total;
  final String message;

  const SyncStatus({
    required this.phase,
    this.current = 0,
    this.total = 0,
    required this.message,
  });
}
