import 'package:get_it/get_it.dart';
import 'package:pos/core/sync/hub_day_closing_lan_publisher.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/features/day_closing/data/day_closing_live_sync.dart';

/// Persists branch day-close watermark, notifies open UI, and fans out on the LAN hub.
Future<void> recordBranchDayClosingSettled({
  required AppDatabase db,
  required int branchId,
  required DateTime settledAt,
}) async {
  await db.dayClosingCheckpointDao.upsertLastSettledAt(branchId, settledAt);
  HubDayClosingLanPublisher.scheduleBranchSettled(
    branchId: branchId,
    settledAt: settledAt,
  );
  if (GetIt.instance.isRegistered<DayClosingLiveSync>()) {
    GetIt.instance<DayClosingLiveSync>().notifyDayClosingChanged();
  }
}
