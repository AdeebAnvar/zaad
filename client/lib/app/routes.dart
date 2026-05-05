import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/enums.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/data/repository_impl/item_repository_impl.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/core/sync/auto_sync_screen.dart';
import 'package:pos/presentation/dashboard/dashboard_screen.dart';
import 'package:pos/presentation/login/login_screen.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';
import 'package:pos/presentation/orders/orders_cubit.dart';
import 'package:pos/presentation/orders/orders_screen.dart';
import 'package:pos/presentation/sale/cart_cubit/cart_cubit.dart';
import 'package:pos/presentation/sale/item_cubit.dart/items_cubit.dart';
import 'package:pos/presentation/sale/sale_screen.dart';
import 'package:pos/presentation/recent_sales/recent_sales_ui.dart';
import 'package:pos/presentation/crm/crm_screen.dart';
import 'package:pos/presentation/crm/crm_customer_details_screen.dart';
import 'package:pos/presentation/take_away_log/take_away_log_cubit.dart';
import 'package:pos/presentation/take_away_log/take_away_log_ui.dart';
import 'package:pos/presentation/delivery/delivery_sale_screen.dart';
import 'package:pos/presentation/driver_log/driver_log_screen.dart';
import 'package:pos/presentation/delivery_log/delivery_log_cubit.dart';
import 'package:pos/presentation/delivery_log/delivery_log_ui.dart';
import 'package:pos/data/repository/delivery_partner_repository.dart';
import 'package:pos/data/repository/driver_repository.dart';
import 'package:pos/presentation/dine_in/dine_in_screen.dart';
import 'package:pos/presentation/dine_in_log/dine_in_log_ui.dart';
import 'package:pos/presentation/settings/lan_hub_settings_screen.dart';
import 'package:pos/presentation/settings/settings_screen.dart';
import 'package:pos/presentation/settings/printer_settings_screen.dart';
import 'package:pos/presentation/credit_sales/credit_sales_screen.dart';
import 'package:pos/presentation/day_closing/day_closing_screen.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Routes {
  static const login = "/login";
  static const dashboard = "/dashboard";
  static const autoSyncScreen = "/auto_sync_screen";
  static const orders = "/orders";
  static const counter = "/counter";
  static const takeAwayLog = "/take_away_log";
  static const deliverySale = "/delivery_sale";
  static const deliveryLog = "/delivery_log";
  static const driverLog = "/driver_log";
  static const dineIn = "/dine_in";
  static const dineInLog = "/dine_in_log";
  static const recentSales = "/recent_sales";
  static const crm = "/crm";
  static const crmCustomerDetails = "/crm/customer_details";
  static const settings = "/settings";
  static const printerSettings = "/printer_settings";
  static const creditSales = "/credit_sales";
  static const dayClosing = "/day_closing";
  static const lanHubSettings = "/lan_hub_settings";

  static Map<String, WidgetBuilder> map = {
    login: (_) => const LoginScreen(),
    dashboard: (_) => const DashboardScreen(),
    autoSyncScreen: (_) => const AutoSyncScreen(),
    orders: (_) => BlocProvider(
          create: (_) => OrdersCubit(
            locator<OrderRepository>(),
            hubOrdersLive: locator<HubOrdersLiveSync>(),
          )..loadOrders(),
          child: const OrdersScreen(),
        ),
    recentSales: (_) => RecentSalesScreen(),
    crm: (_) => const CrmScreen(),
    crmCustomerDetails: (_) => const CrmCustomerDetailsScreen(),
    settings: (_) => const SettingsScreen(),
    printerSettings: (_) => const PrinterSettingsScreen(),
    creditSales: (_) => const CreditSalesScreen(),
    dayClosing: (_) => const DayClosingScreen(),
    lanHubSettings: (_) => const LanHubSettingsScreen(),
    counter: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final orderId = args?['orderId'] as int?;
      final orderType = parseOrderTypeFromRouteArg(args?['orderType']);
      final deliveryPartner = args?['deliveryPartner'] as String?;
      final deliveryServiceId = args?['deliveryServiceId'] as String?;
      final referenceNumber = args?['referenceNumber'] as String?;
      final fromDineIn = args?['fromDineIn'] as bool? ?? false;
      final openPaymentOnLoad = args?['openPaymentOnLoad'] as bool? ?? false;

      return BlocProvider<CartCubit>(
        create: (context) {
          final db = locator<AppDatabase>();
          final cubit = CartCubit(
            locator<CartRepository>(),
            locator<ItemRepository>(),
            locator<OrderRepository>(),
            db.sessionDao,
            locator<PrintService>(),
            orderType: orderType,
            deliveryPartner: deliveryPartner,
            initialReferenceNumber: referenceNumber,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (orderId != null) {
              cubit.loadCartFromOrder(orderId);
            } else {
              cubit.loadActiveCart();
            }
          });
          return cubit;
        },
        child: BlocProvider<ItemsCubit>(
          create: (context) => ItemsCubit(
            ItemRepositoryImpl(locator<AppDatabase>()),
            locator<DeliveryPartnerRepository>(),
            deliveryPartner: deliveryPartner,
            deliveryServiceId: deliveryServiceId,
            saleOrderType: orderType,
          ),
          child: SaleScreen(
            orderType: orderType,
            deliveryPartner: deliveryPartner,
            fromDineIn: fromDineIn,
            openPaymentOnLoad: openPaymentOnLoad,
          ),
        ),
      );
    },
    takeAwayLog: (_) => BlocProvider(
          create: (context) => TakeAwayLogCubit(
            locator<OrderRepository>(),
            hubOrdersLive: locator<HubOrdersLiveSync>(),
          ),
          child: const TakeAwayLogScreen(),
        ),
    deliverySale: (_) => RuntimeAppSettings.deliverySaleEnabled ? const DeliverySaleScreen() : const DashboardScreen(),
    deliveryLog: (_) => BlocProvider(
          create: (_) => DeliveryLogCubit(
            locator<OrderRepository>(),
            locator<DeliveryPartnerRepository>(),
            locator<DriverRepository>(),
            hubOrdersLive: locator<HubOrdersLiveSync>(),
          ),
          child: const DeliveryLogScreen(),
        ),
    driverLog: (_) => const DriverLogScreen(),
    dineIn: (_) => const DineInScreen(),
    dineInLog: (_) => const DineInLogScreen(),
  };
}
