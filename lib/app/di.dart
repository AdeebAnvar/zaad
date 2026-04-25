import 'package:get_it/get_it.dart';
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
import 'package:pos/data/repository/pull_data_repository.dart';
import 'package:pos/data/repository_impl/pull_data_repository_impl.dart';
import 'package:pos/domain/models/api/sync/sync_api.dart';

import '../data/local/drift_database.dart';
import '../data/repository_impl/user_repository_impl.dart';

final locator = GetIt.instance;

class ZaadDI {
  static Future<void> initialize() async {
    await BackupService.instance.validateAndRecoverIfNeeded();

    // ---------- DATABASE ----------
    if (!locator.isRegistered<AppDatabase>()) {
      final db = AppDatabase();
      locator.registerSingleton<AppDatabase>(db);
      BackupService.instance.startAutoBackup(db);
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
  }
}
