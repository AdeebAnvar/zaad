import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/enums.dart';
import 'package:pos/core/utils/order_log_cart_fallback.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/presentation/sale/cart_cubit/cart_cubit.dart';
import 'package:pos/presentation/widgets/order_log_details_dialog.dart';

Order _previewOrderFromCart(CartCubit cubit) {
  final items = cubit.state.items;
  final totalAmount = items.fold<double>(0, (s, e) => s + e.total);
  final discountType = cubit.cartDiscountType;
  final discountInput = cubit.cartDiscountAmount;
  final manualDiscount = (discountType ?? '').toLowerCase() == 'percentage'
      ? (totalAmount * (discountInput / 100)).clamp(0.0, totalAmount).toDouble()
      : discountInput.clamp(0.0, totalAmount).toDouble();
  final finalAmount = (totalAmount - manualDiscount).clamp(0.0, double.infinity);

  final ref = cubit.currentKOTReference?.trim();
  return Order(
    id: 0,
    cartId: 0,
    invoiceNumber: ref != null && ref.isNotEmpty ? ref : '—',
    referenceNumber: ref,
    totalAmount: totalAmount,
    discountAmount: manualDiscount,
    discountType: discountType,
    finalAmount: finalAmount,
    cashAmount: 0,
    creditAmount: 0,
    cardAmount: 0,
    onlineAmount: 0,
    status: 'pending',
    orderType: cubit.orderType.value,
    deliveryPartner: cubit.deliveryPartner,
    createdAt: DateTime.now(),
    branchId: 0,
    hubSyncPending: false,
  );
}

String? _cartPreviewHeaderSubtitle(CartCubit cubit) {
  final ref = cubit.currentKOTReference?.trim();
  if (ref != null && ref.isNotEmpty) return 'Reference $ref';
  switch (cubit.orderType) {
    case OrderType.delivery:
      final p = cubit.deliveryPartner?.trim();
      return p != null && p.isNotEmpty ? 'Delivery · $p' : 'Delivery cart';
    case OrderType.dineIn:
      return 'Dine-in cart';
    case OrderType.counterSale:
      return 'Counter sale cart';
    case OrderType.takeAway:
      return 'Take-away cart';
  }
}

/// Live cart on the sale screen (eye icon beside Save / Pay).
Future<void> showCartPreviewDialog(BuildContext context) async {
  final cubit = context.read<CartCubit>();
  final items = List<CartItem>.from(cubit.state.items);
  if (items.isEmpty) return;

  final itemsWithDetails = await OrderLogCartFallback.buildItemsWithDetailsFromCartItems(
    cartItems: items,
    itemRepo: locator<ItemRepository>(),
  );
  if (!context.mounted || itemsWithDetails.isEmpty) return;

  await showOrderLogDetailsDialog(
    context,
    order: _previewOrderFromCart(cubit),
    itemsWithDetails: itemsWithDetails,
    headerSubtitle: _cartPreviewHeaderSubtitle(cubit),
    hideStatusChip: true,
  );
}

/// Saved orders (delivery log View, etc.) — same themed UI as take-away log.
Future<void> showSavedCartPreviewDialog(
  BuildContext context, {
  required Order order,
  required List<CartItem> items,
}) async {
  if (items.isEmpty) return;
  final itemsWithDetails = await OrderLogCartFallback.buildItemsWithDetailsFromCartItems(
    cartItems: items,
    itemRepo: locator<ItemRepository>(),
  );
  if (!context.mounted) return;
  await showOrderLogDetailsDialog(
    context,
    order: order,
    itemsWithDetails: itemsWithDetails,
  );
}
