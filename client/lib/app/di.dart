import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/core/config/pos_app_runtime_config.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/network/pos_server_settings.dart';
import 'package:pos/core/sync/lan_hub_reconnect_service.dart';
import 'package:pos/core/sync/local_hub_primary_inbound_coordinator.dart';
import 'package:pos/core/sync/local_hub_sync_coordinator.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/core/services/backup_service.dart';
import 'package:pos/core/update/updater_manager.dart';
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
import 'package:pos/features/day_closing/data/day_closing_live_sync.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';
import 'package:flutter/foundation.dart';
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

    late final SharedPreferences prefs;
    if (!locator.isRegistered<SharedPreferences>()) {
      prefs = await SharedPreferences.getInstance();
      locator.registerSingleton<SharedPreferences>(prefs);
    } else {
      prefs = locator<SharedPreferences>();
    }

    if (!locator.isRegistered<AppDatabase>()) {
      final db = AppDatabase();
      locator.registerSingleton<AppDatabase>(db);
      BackupService.instance.startAutoBackup(db);
    }
    if (!locator.isRegistered<UpdaterManager>()) {
      locator.registerSingleton<UpdaterManager>(UpdaterManager(database: locator<AppDatabase>()));
    }
    if (!locator.isRegistered<CurrentCounterSession>()) {
      locator.registerSingleton<CurrentCounterSession>(CurrentCounterSession());
    }

    if (!locator.isRegistered<PosAppRuntimeConfig>()) {
      locator.registerSingleton<PosAppRuntimeConfig>(PosAppRuntimeConfig(prefs));
    }
    if (!locator.isRegistered<PosServerSettings>()) {
      locator.registerSingleton<PosServerSettings>(PosServerSettings(prefs));
    }
    if (!locator.isRegistered<LocalHubSettings>()) {
      locator.registerSingleton<LocalHubSettings>(LocalHubSettings(prefs));
    }

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
        () => OrderRepositoryImpl(locator<AppDatabase>()),
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
    if (!locator.isRegistered<HubOrdersLiveSync>()) {
      locator.registerLazySingleton<HubOrdersLiveSync>(() => HubOrdersLiveSync());
    }
    if (!locator.isRegistered<DayClosingLiveSync>()) {
      locator.registerLazySingleton<DayClosingLiveSync>(() => DayClosingLiveSync());
    }
    if (!locator.isRegistered<LocalHubSyncCoordinator>()) {
      locator.registerLazySingleton<LocalHubSyncCoordinator>(
        () => LocalHubSyncCoordinator(
          db: locator<AppDatabase>(),
          settings: locator<LocalHubSettings>(),
          ordersLiveSync: locator<HubOrdersLiveSync>(),
          dayClosingLiveSync: locator<DayClosingLiveSync>(),
          pullData: locator<PullDataRepository>(),
          userRepo: locator<UserRepository>(),
          branchRepo: locator<BranchRepository>(),
          settingsRepo: locator<SettingsRepository>(),
        ),
      );
    }
    if (!locator.isRegistered<LocalHubPrimaryInboundCoordinator>()) {
      locator.registerLazySingleton<LocalHubPrimaryInboundCoordinator>(
        () => LocalHubPrimaryInboundCoordinator(
          db: locator<AppDatabase>(),
          settings: locator<LocalHubSettings>(),
          ordersLiveSync: locator<HubOrdersLiveSync>(),
          dayClosingLiveSync: locator<DayClosingLiveSync>(),
          pullData: locator<PullDataRepository>(),
          userRepo: locator<UserRepository>(),
          branchRepo: locator<BranchRepository>(),
          settingsRepo: locator<SettingsRepository>(),
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
        () => PrintService(
              locator<AppDatabase>(),
              locator<ItemRepository>(),
              locator<CartRepository>(),
            ),
      );
    }

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

    if (!runtime.isSetupCompleted && !runtime.needsFirstRunSetup()) {
      await runtime.markSetupCompleted();
      debugPrint('[POS] Setup flag migrated for existing install (tenant present)');
    }

    locator<PosAppRuntimeConfig>().logDiagnostics();
    debugPrint('[POS] BASE URL (tenant REST / cloud sync): ${locator<PosServerSettings>().tenantApiBaseUrl ?? '(unset)'}');

    final hubSettings = locator<LocalHubSettings>();
    if (hubSettings.blocksTenantCloudRest) {
      debugPrint(
        '[POS] LAN SUB terminal — tenant REST pull/push disabled. Hub WS: '
        '${hubSettings.hubWsUrl ?? '(unset; ${LocalHubSettings.wsUrlKey})'}',
      );
    }

    if (!hubSettings.blocksTenantCloudRest) {
      locator<OutboundPushCoordinator>().scheduleFlush();
    }
    unawaited(locator<LocalHubSyncCoordinator>().startIfEnabled());
    unawaited(locator<LocalHubPrimaryInboundCoordinator>().startIfEnabled());

    if (!locator.isRegistered<LanHubReconnectService>()) {
      locator.registerLazySingleton<LanHubReconnectService>(
        () => LanHubReconnectService(locator<LocalHubSettings>()),
      );
    }
    locator<LanHubReconnectService>().ensureStarted();
  }
}
