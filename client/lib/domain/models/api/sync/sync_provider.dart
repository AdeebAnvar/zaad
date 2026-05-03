import 'package:flutter/material.dart';
import 'sync_repository.dart';

class SyncProvider extends ChangeNotifier {
  final SyncRepository repository;

  bool syncing = false;

  SyncProvider(this.repository);

  Future<void> sync(String baseUrl) async {
    try {
      syncing = true;
      notifyListeners();

      await repository.pullAllData();
    } finally {
      syncing = false;
      notifyListeners();
    }
  }
}
