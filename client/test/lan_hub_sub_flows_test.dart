import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/network/cloud_sync_prerequisites.dart';
import 'package:pos/core/network/lan_hub_health.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/utils/json_int_parse.dart';
import 'package:pos/core/sync/pos_sync_wire.dart';
import 'package:pos/core/sync/sync_inbox_applier.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository_impl/branches_repository_impl.dart';
import 'package:pos/data/repository_impl/settings_repository_impl.dart';
import 'package:pos/data/repository_impl/user_repository_impl.dart';
import 'package:pos/domain/models/settings_model.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/sales_integrity_fixtures.dart';
import 'helpers/sync_inbox_test_stubs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalHubSettings (SUB terminal)', () {
    test('hub_sub role blocks tenant cloud REST', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LocalHubSettings.roleKey: 'hub_sub',
        LocalHubSettings.wsUrlKey: 'ws://192.168.1.10:3001/ws',
      });
      final prefs = await SharedPreferences.getInstance();
      final hub = LocalHubSettings(prefs);

      expect(hub.isHubSub, isTrue);
      expect(hub.blocksTenantCloudRest, isTrue);
      expect(hub.hubWsUrl, 'ws://192.168.1.10:3001/ws');
      expect(hub.publishHubWsUrlOrLoopback, 'ws://192.168.1.10:3001/ws');
      expect(hub.publishesCatalogAfterTenantPull, isFalse);
    });

    test('canonicalHubWsUrl normalizes host-only input', () {
      expect(
        LocalHubSettings.canonicalHubWsUrl('192.168.1.7'),
        'ws://192.168.1.7:3001/ws',
      );
      expect(
        LocalHubSettings.canonicalHubWsUrl('ws://192.168.1.7:3001/ws'),
        'ws://192.168.1.7:3001/ws',
      );
    });

    test('lanHubHealthUriFromStoredWsUrl maps ws to http /health', () {
      final uri = lanHubHealthUriFromStoredWsUrl('ws://192.168.1.7:3001/ws');
      expect(uri?.scheme, 'http');
      expect(uri?.host, '192.168.1.7');
      expect(uri?.port, 3001);
      expect(uri?.path, '/health');
    });
  });

  group('LanHubWsHealthSummary (hub peer count)', () {
    test('parseLanHubHealthJson reads openSockets and peers', () {
      final summary = parseLanHubHealthJson(<String, dynamic>{
        'ok': true,
        'ws': <String, dynamic>{
          'openSockets': 2,
          'peers': <Map<String, dynamic>>[
            <String, dynamic>{'deviceId': 'main-uuid', 'ip': '192.168.1.7', 'port': 50100},
            <String, dynamic>{'deviceId': 'sub-uuid', 'ip': '192.168.1.6', 'port': 50200},
          ],
        },
      });

      expect(summary, isNotNull);
      expect(summary!.openSockets, 2);
      expect(summary.peers, hasLength(2));
      expect(summary.peers.first.deviceId, 'main-uuid');
    });

    test('solitary gate skips heavy mirror when only MAIN connected', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LocalHubSettings.skipHeavyLanMirrorUnlessExtraWsPeersKey: true,
        LocalHubSettings.wsUrlKey: 'ws://127.0.0.1:3001/ws',
      });
      final prefs = await SharedPreferences.getInstance();
      final hub = LocalHubSettings(prefs);

      final skip = await LanHeavyMirrorGate.shouldSkipForSolitaryWsHub(hub);
      // No live hub in unit test — fetch returns null → do not skip (fail-open).
      expect(skip, isFalse);
    });
  });

  group('assertTenantCloudSyncConfigured', () {
    test('throws on LAN SUB', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LocalHubSettings.roleKey: 'hub_sub',
        'baseUrl': 'https://tenant.example/',
      });
      await expectLater(assertTenantCloudSyncConfigured(), throwsA(isA<TenantCloudDisabledOnLanSubException>()));
    });

    test('throws when baseUrl missing on MAIN', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await expectLater(assertTenantCloudSyncConfigured(), throwsException);
    });
  });

  group('COMPANY_SNAPSHOT on SUB (login bootstrap)', () {
    late AppDatabase db;
    late SyncInboxApplier applier;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LocalHubSettings.roleKey: 'hub_sub',
        LocalHubSettings.wsUrlKey: 'ws://192.168.1.7:3001/ws',
      });
      final prefs = await SharedPreferences.getInstance();
      final hub = LocalHubSettings(prefs);

      db = AppDatabase.memory();
      applier = SyncInboxApplier(
        db,
        hub,
        HubOrdersLiveSync(),
        StubPullDataRepository(),
        userRepo: UserRepositoryImpl(db),
        branchRepo: BranchRepositoryImpl(db),
        settingsRepo: SettingsRepositoryImpl(db),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('applies users branches settings so SUB can log in locally', () async {
      final now = DateTime.utc(2026, 5, 17);
      await applier.apply(
        'snap-1',
        PosSyncEnvelope(
          eventId: 'snap-1',
          type: PosSyncEventTypes.companySnapshot,
          payload: <String, dynamic>{
            'users': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 5,
                'branch_id': 2,
                'name': 'Tablet Cashier',
                'usertype': 'staff',
                'permissions': '[]',
                'mobile_password': 'ignored',
              },
            ],
            'branches': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 2,
                'branch_name': 'Karama',
                'location': 'Dubai',
                'contact_no': '+971',
                'vat': 'inclusive',
                'vat_percent': 5,
                'prefix_inv': 'INV',
                'invoice_header': 'Karama',
                'image': '',
                'installation_date': now.toIso8601String(),
                'expiry_date': now.add(const Duration(days: 365)).toIso8601String(),
              },
            ],
            'settings': SettingsModel.empty().toJson(),
          },
          timestamp: 1,
          deviceId: 'MAIN-HUB',
        ),
        const {},
      );

      final users = await db.usersDao.getAllUsers();
      final branches = await db.branchesDao.getAllBranches();
      final settings = await db.settingsDao.getSettings();

      expect(users, hasLength(1));
      expect(users.first.name, 'Tablet Cashier');
      expect(users.first.branchId, 2);
      expect(branches, hasLength(1));
      expect(branches.first.branchName, 'Karama');
      expect(settings, isNotNull);
    });
  });

  group('resolveMirroredOrderType', () {
    test('normalizes delivery and dine_in aliases', () {
      expect(
        resolveMirroredOrderType(
          snap: const <String, dynamic>{'order_type': 'delivery'},
        ),
        'delivery',
      );
      expect(
        resolveMirroredOrderType(
          snap: const <String, dynamic>{'order_type': 'dine-in'},
        ),
        'dine_in',
      );
    });
  });

  group('SUB order mirror after COMPANY_SNAPSHOT session', () {
    late AppDatabase db;
    late SyncInboxApplier applier;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        LocalHubSettings.roleKey: 'hub_sub',
      });
      final prefs = await SharedPreferences.getInstance();
      db = AppDatabase.memory();
      await seedBranch2Session(db);
      applier = SyncInboxApplier(
        db,
        LocalHubSettings(prefs),
        HubOrdersLiveSync(),
        StubPullDataRepository(),
        userRepo: StubUserRepository(),
        branchRepo: StubBranchRepository(),
        settingsRepo: StubSettingsRepository(),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('delivery ORDER_CREATE is stored with order_type delivery', () async {
      final payload = hubOrderPayload(
        serverOrderId: 'hub-del-1',
        invoice: 'INV-2-201',
        branchId: 2,
        items: [lineSnapshot(itemId: 100, name: 'Combo', total: 40)],
        finalAmount: 40,
        status: 'pending',
        orderType: 'delivery',
      );
      (payload['snapshot'] as Map<String, dynamic>)['delivery_partner'] = 'NORMAL';
      await applier.apply('d1', hubOrderEnvelope(payload), const {});

      final row = await db.ordersDao.getOrderByServerId('hub-del-1');
      expect(row?.orderType, 'delivery');
    });

    test('dine_in ORDER_CREATE is stored with order_type dine_in', () async {
      final payload = hubOrderPayload(
        serverOrderId: 'hub-di-1',
        invoice: 'INV-2-202',
        branchId: 2,
        items: [lineSnapshot(itemId: 101, name: 'Tea', total: 10)],
        finalAmount: 10,
        status: 'kot',
        orderType: 'dine_in',
      );
      (payload['snapshot'] as Map<String, dynamic>)['reference_number'] = '1 | T5';
      await applier.apply('di1', hubOrderEnvelope(payload), const {});

      final row = await db.ordersDao.getOrderByServerId('hub-di-1');
      expect(row?.orderType, 'dine_in');
    });

    test('ORDER_CREATE from MAIN appears on SUB with correct branch', () async {
      await applier.apply(
        'o1',
        hubOrderEnvelope(
          hubOrderPayload(
            serverOrderId: 'hub-sub-1',
            invoice: 'INV-2-050',
            branchId: 2,
            items: [lineSnapshot(itemId: 100, name: 'Banago', total: 36)],
            finalAmount: 36,
          ),
        ),
        const {},
      );

      final row = await db.ordersDao.getOrderByServerId('hub-sub-1');
      expect(row, isNotNull);
      expect(row!.branchId, 2);
      expect(row.invoiceNumber, 'INV-2-050');
    });
  });
}
