import 'package:get_it/get_it.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/data/repository/user_repository.dart';
import 'package:pos/data/repository/customer_repository.dart';
import 'package:pos/data/repository_impl/cart_repository_impl.dart';
import 'package:pos/data/repository_impl/item_repository_impl.dart';
import 'package:pos/data/repository_impl/order_repository_impl.dart';
import 'package:pos/data/repository_impl/customer_repository_impl.dart';
import 'package:pos/presentation/login/login_screen_cubit.dart';

import '../data/local/drift_database.dart';
import '../data/repository_impl/user_repository_impl.dart';

final locator = GetIt.instance;

class ZaadDI {
  static Future<void> initialize() async {
    // ---------- DATABASE ----------
    if (!locator.isRegistered<AppDatabase>()) {
      locator.registerSingleton<AppDatabase>(AppDatabase());
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

    // ---------- CUBITS ----------
    if (!locator.isRegistered<LoginCubit>()) {
      locator.registerFactory<LoginCubit>(
        () => LoginCubit(locator<UserRepository>()),
      );
    }
  }
}
