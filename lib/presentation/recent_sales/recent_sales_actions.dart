import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/presentation/recent_sales/recent_sales_cubit.dart';
import 'package:pos/presentation/widgets/order_log_details_dialog.dart';

Future<void> showRecentSaleOrderDetails(BuildContext context, Order order) async {
  final cartRepo = locator<CartRepository>();
  final itemRepo = locator<ItemRepository>();

  final cartItems = await cartRepo.getCartItemsByCartId(order.cartId);
  if (cartItems == null || cartItems.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items found for this order')),
      );
    }
    return;
  }

  final List<Map<String, dynamic>> itemsWithDetails = [];
  for (final cartItem in cartItems) {
    final item = await itemRepo.fetchItemByIdFromLocal(cartItem.itemId);
    ItemVariant? variant;
    if (cartItem.itemVariantId != null) {
      variant = await itemRepo.fetchVariantById(cartItem.itemVariantId!);
    }
    ItemTopping? topping;
    if (cartItem.itemToppingId != null) {
      topping = await itemRepo.fetchToppingById(cartItem.itemToppingId!);
    }
    itemsWithDetails.add({
      'cartItem': cartItem,
      'item': item,
      'variant': variant,
      'topping': topping,
    });
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
  final cartItems = await cartRepo.getCartItemsByCartId(order.cartId);
  if (cartItems == null || cartItems.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items to print')),
      );
    }
    return;
  }
  try {
    final printFailed = await printService.printFinalBill(order: order, cartItems: cartItems);
    if (context.mounted) {
      if (printFailed.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill sent to printer')),
        );
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
void openRecentSaleForEdit(
  BuildContext context,
  Order order, {
  VoidCallback? onReturn,
}) {
  Navigator.pushNamed(
    context,
    '/counter',
    arguments: {
      'orderId': order.id,
      'orderType': order.orderType ?? 'take_away',
      'deliveryPartner': order.deliveryPartner,
      'referenceNumber': order.referenceNumber,
      'fromDineIn': order.orderType == 'dine_in',
    },
  ).then((_) {
    if (context.mounted) {
      onReturn?.call();
    }
  });
}
