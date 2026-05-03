import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/core/config/pos_app_runtime_config.dart';
import 'package:pos/core/network/base_url_resolver.dart';
import 'package:pos/core/network/pos_api_service.dart';
import 'package:pos/core/network/pos_hub_auth.dart';
import 'package:pos/core/network/pos_hub_device_identity.dart';
import 'package:pos/core/network/pos_server_settings.dart';
import 'package:pos/core/network/hub_lan_catalog_live_sync.dart';
import 'package:pos/core/network/websocket_service.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/core/services/backup_service.dart';
import 'package:pos/data/repository/branch_repository.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/data/repository/settings_repository.dart';
import 'package:pos/data/repository/user_repository.dart';
import 'package:pos/data/repository/customer_repository.dart';
import 'package:pos/data/repository/delivery_partner_repository.dart';
import 'package:pos/data/repository/driver_repository.dart';
import 'package:pos/data/repository/kitchen_repository.dart';
import 'package:pos/data/repository_impl/cart_repository_impl.dart';
import 'package:pos/data/repository_impl/item_repository_impl.dart';
import 'package:pos/data/repository_impl/order_repository_impl.dart';
import 'package:pos/data/repository_impl/customer_repository_impl.dart';
import 'package:pos/data/repository_impl/delivery_partner_repository_impl.dart';
import 'package:pos/data/repository_impl/driver_repository_impl.dart';
import 'package:pos/data/repository_impl/kitchen_repository_impl.dart';
import 'package:pos/data/repository_impl/branches_repository_impl.dart';
import 'package:pos/data/repository_impl/settings_repository_impl.dart';
import 'package:pos/domain/models/api/auth/auth_api.dart';
import 'package:pos/domain/models/api/auth/auth_repository.dart';
import 'package:pos/presentation/login/login_screen_cubit.dart';
import 'package:pos/core/sync/outbound_push_coordinator.dart';
import 'package:pos/data/repository/pull_data_repository.dart';
import 'package:pos/data/repository/push_records_repository.dart';
import 'package:pos/data/repository_impl/pull_data_repository_impl.dart';
import 'package:pos/data/repository_impl/push_records_repository_impl.dart';
import 'package:pos/domain/models/api/sync/sync_api.dart';

import 'package:pos/core/network/hub_connection_status_service.dart';
import 'package:pos/core/sync/offline_hub_sync_worker.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';
import 'package:pos/features/orders/data/hub_orders_sync.dart';
import 'package:pos/features/orders/data/local_hub_pending_queue.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/drift_database.dart';
import '../data/repository_impl/user_repository_impl.dart';

final locator = GetIt.instance;

class ZaadDI {
  /// Consumed once by [main] → [ZaadPOSApp] initial route (setup vs login).
  static String? _pendingInitialRoute;

  static String? consumePendingInitialRoute() {
    final r = _pendingInitialRoute;
    _pendingInitialRoute = null;
    return r;
  }

  static Future<void> initialize() async {
    await BackupService.instance.validateAndRecoverIfNeeded();

    // ---------- DATABASE ----------
    if (!locator.isRegistered<AppDatabase>()) {
      final db = AppDatabase();
      locator.registerSingleton<AppDatabase>(db);
      BackupService.instance.startAutoBackup(db);
    }
    if (!locator.isRegistered<CurrentCounterSession>()) {
      locator.registerSingleton<CurrentCounterSession>(CurrentCounterSession());
    }

    // ---------- LAN hub (optional; activates when SharedPreferences URL set) ----------
    late final SharedPreferences prefs;
    if (!locator.isRegistered<SharedPreferences>()) {
      prefs = await SharedPreferences.getInstance();
      locator.registerSingleton<SharedPreferences>(prefs);
    } else {
      prefs = locator<SharedPreferences>();
    }
    if (!locator.isRegistered<PosAppRuntimeConfig>()) {
      locator.registerSingleton<PosAppRuntimeConfig>(PosAppRuntimeConfig(prefs));
    }
    if (!locator.isRegistered<BaseUrlResolver>()) {
      locator.registerSingleton<BaseUrlResolver>(
        BaseUrlResolver(prefs, locator<PosAppRuntimeConfig>()),
      );
    }
    if (!locator.isRegistered<PosServerSettings>()) {
      locator.registerSingleton<PosServerSettings>(PosServerSettings(prefs));
    }
    if (!locator.isRegistered<PosHubDeviceIdentity>()) {
      locator.registerSingleton<PosHubDeviceIdentity>(PosHubDeviceIdentity(prefs));
    }
    if (!locator.isRegistered<HubOrdersSync>()) {
      locator.registerSingleton<HubOrdersSync>(
        HubOrdersSync(locator<AppDatabase>()),
      );
    }
    if (!locator.isRegistered<LocalHubPendingQueue>()) {
      locator.registerSingleton<LocalHubPendingQueue>(
        LocalHubPendingQueue(locator<AppDatabase>()),
      );
    }
    if (!locator.isRegistered<FlutterSecureStorage>()) {
      locator.registerSingleton<FlutterSecureStorage>(
        const FlutterSecureStorage(),
      );
    }
    if (!locator.isRegistered<PosHubAuth>()) {
      locator.registerSingleton<PosHubAuth>(
        PosHubAuth(locator<FlutterSecureStorage>()),
      );
    }
    if (!locator.isRegistered<PosApiService>()) {
      locator.registerSingleton<PosApiService>(
        PosApiService(
          settings: locator<PosServerSettings>(),
          auth: locator<PosHubAuth>(),
          runtime: locator<PosAppRuntimeConfig>(),
        ),
      );
    }
    // ---------- REPOSITORIES ----------
    if (!locator.isRegistered<UserRepository>()) {
      locator.registerLazySingleton<UserRepository>(
        () => UserRepositoryImpl(locator<AppDatabase>()),
      );
    }
    if (!locator.isRegistered<ItemRepository>()) {
      locator.registerLazySingleton<ItemRepository>(
        () => ItemRepositoryImpl(locator<AppDatabase>()),
      );
    }
    if (!locator.isRegistered<CartRepository>()) {
      locator.registerLazySingleton<CartRepository>(
        () => CartRepositoryImpl(locator<AppDatabase>()),
      );
    }
    if (!locator.isRegistered<OrderRepository>()) {
      locator.registerLazySingleton<OrderRepository>(
        () => OrderRepositoryImpl(
          locator<AppDatabase>(),
          hubSettings: locator<PosServerSettings>(),
          hubApi: locator<PosApiService>(),
          hubSync: locator<HubOrdersSync>(),
          hubDevice: locator<PosHubDeviceIdentity>(),
          runtime: locator<PosAppRuntimeConfig>(),
          hubPendingQueue: locator<LocalHubPendingQueue>(),
        ),
      );
    }
    if (!locator.isRegistered<CustomerRepository>()) {
      locator.registerLazySingleton<CustomerRepository>(
        () => CustomerRepositoryImpl(locator<AppDatabase>()),
      );
    }
    if (!locator.isRegistered<KitchenRepository>()) {
      locator.registerLazySingleton<KitchenRepository>(
        () => KitchenRepositoryImpl(locator<AppDatabase>()),
      );
    }
    if (!locator.isRegistered<DeliveryPartnerRepository>()) {
      locator.registerLazySingleton<DeliveryPartnerRepository>(
        () => DeliveryPartnerRepositoryImpl(locator<AppDatabase>()),
      );
    }
    if (!locator.isRegistered<DriverRepository>()) {
      locator.registerLazySingleton<DriverRepository>(
        () => DriverRepositoryImpl(locator<AppDatabase>()),
      );
    }
    if (!locator.isRegistered<BranchRepository>()) {
      locator.registerLazySingleton<BranchRepository>(
        () => BranchRepositoryImpl(locator<AppDatabase>()),
      );
    }
    if (!locator.isRegistered<SettingsRepository>()) {
      locator.registerLazySingleton<SettingsRepository>(
        () => SettingsRepositoryImpl(locator<AppDatabase>()),
      );
    }
    if (!locator.isRegistered<AuthApi>()) {
      locator.registerLazySingleton<AuthApi>(
        () => AuthApi(),
      );
    }
    if (!locator.isRegistered<SyncApi>()) {
      locator.registerLazySingleton<SyncApi>(
        () => SyncApi(),
      );
    }
    if (!locator.isRegistered<PullDataRepository>()) {
      locator.registerLazySingleton<PullDataRepository>(
        () => PullDataRepositoryImpl(
          locator<AppDatabase>(),
          locator<SyncApi>(),
        ),
      );
    }
    if (!locator.isRegistered<HubLanCatalogLiveSync>()) {
      locator.registerLazySingleton<HubLanCatalogLiveSync>(
        () => HubLanCatalogLiveSync(
          locator<PosAppRuntimeConfig>(),
          locator<PullDataRepository>(),
          locator<PosApiService>(),
        ),
      );
    }
    if (!locator.isRegistered<HubOrdersLiveSync>()) {
      locator.registerLazySingleton<HubOrdersLiveSync>(() => HubOrdersLiveSync());
    }
    if (!locator.isRegistered<HubWebSocketService>()) {
      locator.registerLazySingleton<HubWebSocketService>(
        () => HubWebSocketService(
          locator<PosServerSettings>(),
          locator<PosApiService>(),
          locator<HubOrdersSync>(),
          catalogLive: locator<HubLanCatalogLiveSync>(),
          ordersLive: locator<HubOrdersLiveSync>(),
        ),
      );
    }
    if (!locator.isRegistered<HubConnectionStatusService>()) {
      locator.registerLazySingleton<HubConnectionStatusService>(
        () => HubConnectionStatusService(
          runtime: locator<PosAppRuntimeConfig>(),
          settings: locator<PosServerSettings>(),
          ws: locator<HubWebSocketService>(),
          resolver: locator<BaseUrlResolver>(),
        ),
      );
    }
    if (!locator.isRegistered<PushRecordsRepository>()) {
      locator.registerLazySingleton<PushRecordsRepository>(
        () => PushRecordsRepositoryImpl(
          locator<AppDatabase>(),
          locator<SyncApi>(),
        ),
      );
    }
    if (!locator.isRegistered<OutboundPushCoordinator>()) {
      locator.registerLazySingleton<OutboundPushCoordinator>(
        () {
          final c = OutboundPushCoordinator(
            locator<PushRecordsRepository>(),
            locator<AppDatabase>(),
            locator<PosAppRuntimeConfig>(),
          );
          c.ensureListening();
          return c;
        },
      );
    }
    if (!locator.isRegistered<AuthRepository>()) {
      locator.registerLazySingleton<AuthRepository>(
        () => AuthRepository(locator<AuthApi>()),
      );
    }

    if (!locator.isRegistered<PrintService>()) {
      locator.registerLazySingleton<PrintService>(
        () => PrintService(locator<AppDatabase>(), locator<ItemRepository>()),
      );
    }

    // ---------- CUBITS ----------
    if (!locator.isRegistered<LoginCubit>()) {
      locator.registerFactory<LoginCubit>(
        () => LoginCubit(
          locator<AuthRepository>(),
          locator<UserRepository>(),
          locator<BranchRepository>(),
          locator<SettingsRepository>(),
        ),
      );
    }

    final runtime = locator<PosAppRuntimeConfig>();
    final hubSettings = locator<PosServerSettings>();
    final resolver = locator<BaseUrlResolver>();

    if (!runtime.isSetupCompleted && !runtime.needsFirstRunSetup()) {
      await runtime.markSetupCompleted();
      debugPrint('[POS] Setup flag migrated for existing install (tenant or hub present)');
    }

    if (runtime.isLocal) {
      try {
        final url = await resolver.resolveLocalBaseUrl();
        await hubSettings.setBaseUrl(url);
        debugPrint('[POS] Selected BASE URL (local): $url');
      } catch (e, st) {
        debugPrint('[POS] Local hub auto-connect failed (login still shown): $e\n$st');
      }
    }

    runtime.logDiagnostics();
    debugPrint('[POS] BASE URL (tenant REST / cloud sync): ${hubSettings.tenantApiBaseUrl ?? '(unset)'}');
    debugPrint('[POS] BASE URL (hub HTTP): ${hubSettings.hubRoot ?? '(none)'}');
    debugPrint('[POS] LAN WebSocket enabled: ${hubSettings.enablesLanWebSocket}');

    if (hubSettings.enablesLanWebSocket) {
      await locator<HubWebSocketService>().hydrateCacheIfConfigured();
      locator<HubWebSocketService>().startRealtimeIfConfigured();
    }

    if (!locator.isRegistered<OfflineHubSyncWorker>()) {
      locator.registerSingleton<OfflineHubSyncWorker>(
        OfflineHubSyncWorker(
          db: locator<AppDatabase>(),
          queue: locator<LocalHubPendingQueue>(),
          hubApi: locator<PosApiService>(),
          hubSync: locator<HubOrdersSync>(),
          connection: locator<HubConnectionStatusService>(),
          runtime: locator<PosAppRuntimeConfig>(),
          ws: locator<HubWebSocketService>(),
          settings: locator<PosServerSettings>(),
        ),
      );
      locator<OfflineHubSyncWorker>().start();
      locator<OfflineHubSyncWorker>().ensureConnectivityListener();
    }

    // Connectivity listener + flush pending unsynced logs when the app starts online.
    locator<OutboundPushCoordinator>().scheduleFlush();
  }
}
