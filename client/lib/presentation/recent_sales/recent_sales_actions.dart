import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/core/utils/delivery_counter_route_args.dart';
import 'package:pos/data/repository/delivery_partner_repository.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/core/utils/order_log_cart_fallback.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/presentation/recent_sales/recent_sales_cubit.dart';
import 'package:pos/presentation/widgets/app_snackbar.dart';
import 'package:pos/presentation/widgets/order_log_details_dialog.dart';

Future<void> showRecentSaleOrderDetails(BuildContext context, Order order) async {
  final cartRepo = locator<CartRepository>();
  final itemRepo = locator<ItemRepository>();

  final itemsWithDetails = await OrderLogCartFallback.buildItemsWithDetailsForOrderLog(
    order: order,
    db: locator<AppDatabase>(),
    cartRepo: cartRepo,
    itemRepo: itemRepo,
  );
  if (itemsWithDetails.isEmpty) {
    if (context.mounted) {
      showAppSnackBar(context, 'No items found for this order', isWarning: true);
    }
    return;
  }

  if (!context.mounted) return;
  showDialog<void>(
    context: context,
    builder: (ctx) => OrderLogDetailsDialog(
      order: order,
      itemsWithDetails: itemsWithDetails,
    ),
  );
}

Future<void> printRecentSaleBill(BuildContext context, Order order) async {
  final cartRepo = locator<CartRepository>();
  final printService = locator<PrintService>();
  final cartItems = await OrderLogCartFallback.resolve(
    order: order,
    db: locator<AppDatabase>(),
    cartRepo: cartRepo,
  );
  if (cartItems.isEmpty) {
    if (context.mounted) {
      showAppSnackBar(context, 'No items to print', isWarning: true);
    }
    return;
  }
  try {
    final printFailed = await printService.printFinalBill(
      order: order,
      cartItems: cartItems,
      settledBill: true,
    );
    if (context.mounted) {
      if (printFailed.isEmpty) {
        showAppSnackBar(context, 'Bill sent to printer');
      } else {
        showPrintFailedDialog(context, printFailed);
      }
    }
  } catch (e) {
    if (context.mounted) {
      showErrorDialog(context, e);
    }
  }
}

/// Opens counter for this order. [onReturn] runs when popped (e.g. refresh [RecentSalesCubit]).
Future<void> openRecentSaleForEdit(
  BuildContext context,
  Order order, {
  VoidCallback? onReturn,
  bool openPaymentOnLoad = false,
}) async {
  final args = <String, dynamic>{
    'orderId': order.id,
    'orderType': order.orderType ?? 'take_away',
    'referenceNumber': order.referenceNumber,
    'fromDineIn': order.orderType == 'dine_in',
    'openPaymentOnLoad': openPaymentOnLoad,
  };
  if (order.orderType == 'delivery') {
    final route = await resolveDeliveryCounterRouteArgsFromOrder(
      order: order,
      partnerRepo: locator<DeliveryPartnerRepository>(),
    );
    args['deliveryPartner'] = route.deliveryPartner;
    args['deliveryServiceId'] = route.deliveryServiceId;
  } else {
    args['deliveryPartner'] = order.deliveryPartner;
  }

  if (!context.mounted) return;
  await Navigator.pushNamed(
    context,
    '/counter',
    arguments: args,
  );
  if (context.mounted) {
    onReturn?.call();
  }
}
