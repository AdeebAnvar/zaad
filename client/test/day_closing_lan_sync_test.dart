import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/core/sync/pos_sync_wire.dart';
import 'package:pos/core/sync/sync_inbox_applier.dart';
import 'package:pos/features/day_closing/data/day_closing_live_sync.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/sales_integrity_fixtures.dart';
import 'helpers/sync_inbox_test_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DAY_CLOSING_SETTLED LAN mirror', () {
    late AppDatabase db;
    late SyncInboxApplier applier;
    late DayClosingLiveSync dayClosingLive;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LocalHubSettings.roleKey: 'hub_sub',
        LocalHubSettings.wsUrlKey: 'ws://192.168.1.7:3001/ws',
      });
      final prefs = await SharedPreferences.getInstance();
      final hub = LocalHubSettings(prefs);

      db = AppDatabase.memory();
      await seedBranch2Session(db);
      dayClosingLive = DayClosingLiveSync();

      applier = SyncInboxApplier(
        db,
        hub,
        HubOrdersLiveSync(),
        StubPullDataRepository(),
        userRepo: StubUserRepository(),
        branchRepo: StubBranchRepository(),
        settingsRepo: StubSettingsRepository(),
        dayClosingLiveSync: dayClosingLive,
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('applies newer branch checkpoint from peer', () async {
      final older = DateTime(2026, 5, 17, 10);
      final incoming = DateTime(2026, 5, 17, 18);
      await db.dayClosingCheckpointDao.upsertLastSettledAt(2, older);

      await applier.apply(
        'dc-1',
        PosSyncEnvelope(
          eventId: 'dc-1',
          type: PosSyncEventTypes.dayClosingSettled,
          payload: <String, dynamic>{
            'branchId': 2,
            'lastSettledAt': incoming.toIso8601String(),
            'updatedAt': 1000,
          },
          timestamp: 1,
          deviceId: 'MAIN-HUB',
        ),
        const {},
      );

      final after = await db.dayClosingCheckpointDao.lastSettledAtForBranch(2);
      expect(after, incoming);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(dayClosingLive.revision.value, greaterThan(0));
    });

    test('ignores older checkpoint from peer', () async {
      final newer = DateTime(2026, 5, 17, 20);
      final stale = DateTime(2026, 5, 17, 12);
      await db.dayClosingCheckpointDao.upsertLastSettledAt(2, newer);
      dayClosingLive.revision.value = 0;

      await applier.apply(
        'dc-2',
        PosSyncEnvelope(
          eventId: 'dc-2',
          type: PosSyncEventTypes.dayClosingSettled,
          payload: <String, dynamic>{
            'branchId': 2,
            'lastSettledAt': stale.toIso8601String(),
            'updatedAt': 2000,
          },
          timestamp: 1,
          deviceId: 'OTHER-TABLET',
        ),
        const {},
      );

      final after = await db.dayClosingCheckpointDao.lastSettledAtForBranch(2);
      expect(after, newer);
      expect(dayClosingLive.revision.value, 0);
    });
  });
}
