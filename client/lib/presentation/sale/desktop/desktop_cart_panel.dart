import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/debug/agent_debug_log.dart';
import 'package:pos/core/print/cash_drawer_on_payment.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/enums.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/core/utils/dine_in_sale_navigation.dart';
import 'package:pos/core/utils/kot_reference_recents.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/models/pos_customer.dart';
import 'package:pos/core/utils/order_log_cart_fallback.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/customer_repository.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/domain/models/customer_model.dart';
import 'package:pos/domain/models/offer_model.dart';
import 'package:pos/presentation/sale/cart_cubit/cart_cubit.dart';
import 'package:pos/presentation/sale/desktop/cart_preview_dialog.dart';
import 'package:pos/presentation/sale/desktop/desktop_cart_item_tile.dart';
import 'package:pos/presentation/widgets/auto_complete_textfield.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';

/// Rebuild the cart [SliverList] only when lines are added/removed/reordered — not on qty/total edits.
bool _cartListStructureChanged(CartState prev, CartState curr) {
  if (prev.items.length != curr.items.length) return true;
  for (var i = 0; i < prev.items.length; i++) {
    if (prev.items[i].id != curr.items[i].id) return true;
  }
  return false;
}

final Set<String> _autoPaymentShownKeys = <String>{};

typedef PaymentDialogOnSave = Future<void> Function(
  Map<String, dynamic> customerDetails,
  Map<String, dynamic> discount,
  Map<String, double> payments, {
  required bool printInvoice,
  required bool printKot,
});

/// One cart line for offer applicability (item / category / line total).
class PaymentOfferLine {
  final int itemId;
  final int categoryId;
  final double lineTotal;

  const PaymentOfferLine({
    required this.itemId,
    required this.categoryId,
    required this.lineTotal,
  });
}

Future<List<PaymentOfferLine>> buildPaymentOfferLines(
  List<CartItem> cartLines,
  ItemRepository itemRepo,
) async {
  final out = <PaymentOfferLine>[];
  for (final line in cartLines) {
    final item = await itemRepo.fetchItemByIdFromLocal(line.itemId);
    out.add(PaymentOfferLine(
      itemId: line.itemId,
      categoryId: item?.categoryId ?? 0,
      lineTotal: line.total,
    ));
  }
  return out;
}

List<int> _offerJsonIntList(dynamic raw) {
  if (raw == null) return const [];
  if (raw is num) return [raw.toInt()];
  final single = int.tryParse(raw.toString().trim());
  if (raw is! List && single != null) return [single];
  if (raw is! List) return const [];
  final out = <int>[];
  for (final e in raw) {
    if (e is num) {
      out.add(e.toInt());
    } else {
      final parsed = int.tryParse(e.toString().trim());
      if (parsed != null) out.add(parsed);
    }
  }
  return out;
}

/// API may send `active` as 1, "1", true, etc.
bool _offerPayloadIsActive(dynamic raw) {
  if (raw == null) return false;
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  final s = raw.toString().trim().toLowerCase();
  return s == '1' || s == 'true' || s == 'yes' || s == 'active';
}

/// Local / API payload may use `active` or `is_active`.
bool _offerPayloadMapIsActive(Map<String, dynamic> payload) {
  return _offerPayloadIsActive(payload['active']) || _offerPayloadIsActive(payload['is_active']);
}

Map<String, dynamic> _offerPayloadMap(dynamic decoded) {
  if (decoded is! Map) return {};
  return decoded.map((k, v) => MapEntry(k.toString(), v));
}

/// Unwrap JSON stored as a string (double-encoded) or return map.
Map<String, dynamic>? _offerDecodePayloadJson(String payloadRaw) {
  var trimmed = payloadRaw.trim();
  if (trimmed.isEmpty) return null;
  try {
    dynamic decoded = jsonDecode(trimmed);
    // Some pipelines store JSON as an escaped string inside JSON.
    for (var i = 0; i < 3 && decoded is String; i++) {
      final s = decoded.trim();
      if (s.isEmpty) return null;
      decoded = jsonDecode(s);
    }
    if (decoded is! Map) return null;
    return _offerPayloadMap(decoded);
  } catch (_) {
    return null;
  }
}

List<String> _offerJsonDayList(dynamic raw) {
  if (raw == null) return const [];
  if (raw is! List) return const [];
  return raw.map((e) => e.toString().toLowerCase().trim()).where((s) => s.isNotEmpty).toList();
}

/// Subtotal of cart lines this offer can apply to (before the offer discount).
double _offerApplicableSubtotal(
  Map<String, dynamic> payload,
  List<PaymentOfferLine> lines,
  double orderTotal,
) {
  final hasApplicabilityPayload = payload.containsKey('is_all_items') ||
      payload.containsKey('item_id') ||
      payload.containsKey('category_id') ||
      payload.containsKey('item_ids') ||
      payload.containsKey('category_ids');
  if (!hasApplicabilityPayload) {
    return orderTotal;
  }
  final isAllRaw = payload['is_all_items'] ?? payload['isAllItems'];
  final int isAll;
  if (isAllRaw is bool) {
    isAll = isAllRaw ? 1 : 0;
  } else {
    isAll = (isAllRaw is num ? isAllRaw.toInt() : null) ?? int.tryParse(isAllRaw?.toString() ?? '') ?? 0;
  }
  final itemIds = _offerJsonIntList(payload['item_id'] ?? payload['item_ids']);
  final categoryIds = _offerJsonIntList(payload['category_id'] ?? payload['category_ids']);
  if (isAll == 1) return orderTotal;
  if (lines.isEmpty) return 0;
  var sum = 0.0;
  for (final line in lines) {
    final inItems = itemIds.isNotEmpty && itemIds.contains(line.itemId);
    final inCats = categoryIds.isNotEmpty && categoryIds.contains(line.categoryId);
    if (itemIds.isNotEmpty && categoryIds.isNotEmpty) {
      if (inItems || inCats) sum += line.lineTotal;
    } else if (itemIds.isNotEmpty) {
      if (inItems) sum += line.lineTotal;
    } else if (categoryIds.isNotEmpty) {
      if (inCats) sum += line.lineTotal;
    } else {
      return 0;
    }
  }
  return sum;
}

enum _OfferValueType { percentage, amount }

class _AppliedOffer {
  final int offerId;
  final String uuid;
  final String name;
  final String toDateText;
  final double value;
  final _OfferValueType type;
  final double discountAmount;
  final bool isAutoDay;

  const _AppliedOffer({
    required this.offerId,
    required this.uuid,
    required this.name,
    required this.toDateText,
    required this.value,
    required this.type,
    required this.discountAmount,
    this.isAutoDay = false,
  });
}

Future<void> showCartStylePaymentDialogForOrder(
  BuildContext context, {
  required Order order,
  VoidCallback? onPaymentRecorded,
}) async {
  Map<String, dynamic>? appliedOffer;
  try {
    final raw = order.hubMetadata;
    if (raw != null && raw.trim().isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map && decoded['applied_offer'] is Map) {
        appliedOffer = Map<String, dynamic>.from(decoded['applied_offer'] as Map<dynamic, dynamic>);
      }
    }
  } catch (_) {}

  final prefill = <String, dynamic>{
    'name': order.customerName,
    'phone': order.customerPhone,
    'email': order.customerEmail,
    'gender': order.customerGender,
    'onlineOrderNumber': order.referenceNumber,
    'discountAmount': order.discountAmount,
    'discountType': order.discountType,
    if (appliedOffer != null) 'appliedOffer': appliedOffer,
  };

  final db = locator<AppDatabase>();
  final itemRepo = locator<ItemRepository>();
  final cartRepo = locator<CartRepository>();
  final cartLines = await OrderLogCartFallback.resolve(
    order: order,
    db: db,
    cartRepo: cartRepo,
  );
  final offerLines = cartLines.isEmpty ? <PaymentOfferLine>[] : await buildPaymentOfferLines(cartLines, itemRepo);

  await showDialog<bool>(
    context: context,
    builder: (dialogContext) => PaymentDialog(
      totalAmount: order.totalAmount,
      offerLines: offerLines,
      closeSheetOnClose: false,
      parentContext: context,
      isDelivery: order.orderType == 'delivery',
      deliveryPartner: order.deliveryPartner,
      prefill: prefill,
      onSave: (customerDetails, discount, payments, {required printInvoice, required printKot}) async {
        final repo = locator<OrderRepository>();
        final freshOrder = await repo.getOrderById(order.id);
        if (freshOrder == null) return;

        final discountAmount = (discount['value'] as num?)?.toDouble() ?? 0.0;
        final discountType = (discount['type'] as String?) ?? 'amount';
        final manualDiscountAmount = discountType == 'percentage'
            ? (freshOrder.totalAmount * (discountAmount / 100)).clamp(0.0, freshOrder.totalAmount).toDouble()
            : discountAmount.clamp(0.0, freshOrder.totalAmount).toDouble();
        final rawOffer = discount['offer'];
        final offer = rawOffer is Map ? Map<String, dynamic>.from(rawOffer) : null;
        final offerDiscountAmount = (offer?['discountAmount'] as num?)?.toDouble() ?? (double.tryParse(offer?['discountAmount']?.toString() ?? '') ?? 0.0);
        final totalDiscount = (manualDiscountAmount + offerDiscountAmount).clamp(0.0, freshOrder.totalAmount).toDouble();
        final finalAmount = (freshOrder.totalAmount - totalDiscount).clamp(0.0, double.infinity);
        final onlineOrderNumber = customerDetails['onlineOrderNumber'] as String?;
        final updatedRef = freshOrder.orderType == 'delivery' && onlineOrderNumber != null && onlineOrderNumber.isNotEmpty ? onlineOrderNumber : freshOrder.referenceNumber;
        String? hubMetadataWithOffer = freshOrder.hubMetadata;
        if (offer != null) {
          final cleanedOffer = <String, dynamic>{
            'name': offer['name']?.toString() ?? '',
            'uuid': offer['uuid']?.toString() ?? '',
            'type': offer['type']?.toString() ?? '',
            'value': (offer['value'] as num?)?.toDouble() ?? (double.tryParse(offer['value']?.toString() ?? '') ?? 0.0),
            'discountAmount': offerDiscountAmount,
            'toDate': offer['toDate']?.toString() ?? '',
            if (offer['autoDayDiscount'] != null)
              'autoDayDiscount': (offer['autoDayDiscount'] as num?)?.toDouble() ?? (double.tryParse(offer['autoDayDiscount']?.toString() ?? '') ?? 0.0),
            if (offer['autoDayOfferNames'] is List) 'autoDayOfferNames': offer['autoDayOfferNames'],
          };
          try {
            final existing = (hubMetadataWithOffer != null && hubMetadataWithOffer.trim().isNotEmpty) ? jsonDecode(hubMetadataWithOffer) : <String, dynamic>{};
            final map = existing is Map ? Map<String, dynamic>.from(existing) : <String, dynamic>{};
            map['applied_offer'] = cleanedOffer;
            hubMetadataWithOffer = jsonEncode(map);
          } catch (_) {
            hubMetadataWithOffer = jsonEncode({'applied_offer': cleanedOffer});
          }
        }

        final deliveryStatus = freshOrder.orderType == 'delivery' ? freshOrder.status : 'completed';

        final updatedOrder = freshOrder.copyWith(
          referenceNumber: Value(updatedRef),
          discountAmount: totalDiscount,
          discountType: Value(totalDiscount > 0 ? 'amount' : discountType),
          finalAmount: finalAmount,
          customerName: Value(customerDetails['name'] as String?),
          customerEmail: Value(customerDetails['email'] as String?),
          customerPhone: Value(customerDetails['phone'] as String?),
          customerGender: Value(customerDetails['gender'] as String?),
          cashAmount: payments['cash'] ?? 0.0,
          creditAmount: payments['credit'] ?? 0.0,
          cardAmount: payments['card'] ?? 0.0,
          onlineAmount: (payments['online'] ?? 0.0) + (payments['other'] ?? 0.0),
          status: deliveryStatus,
          hubMetadata: Value(hubMetadataWithOffer),
        );

        await repo.updateOrder(updatedOrder);
        // #region agent log
        agentDebugLog(
          hypothesisId: 'H1',
          location: 'desktop_cart_panel.dart:pay',
          message: 'counter_pay_saved',
          data: <String, Object?>{
            'orderId': updatedOrder.id,
            'orderType': updatedOrder.orderType,
            'status': updatedOrder.status,
            'invoice': updatedOrder.invoiceNumber,
            'paid': updatedOrder.cashAmount + updatedOrder.cardAmount + updatedOrder.creditAmount + updatedOrder.onlineAmount,
          },
        );
        // #endregion

        final db = locator<AppDatabase>();
        final printSvc = locator<PrintService>();
        final cartItems = await OrderLogCartFallback.resolve(
          order: updatedOrder,
          db: db,
          cartRepo: cartRepo,
        );
        final ref = updatedOrder.referenceNumber?.trim().isNotEmpty == true ? updatedOrder.referenceNumber! : updatedOrder.invoiceNumber;
        final printFailed = <String>[];
        // Cash drawer: any cash tender — independent of Invoice/KOT print toggles.
        printFailed.addAll(
          await openCashDrawerForCashPayment(
            resolveCashTenderForDrawer(payments, orderCashAmount: updatedOrder.cashAmount),
          ),
        );
        if (printKot && cartItems.isNotEmpty) {
          printFailed.addAll(
            await printSvc.printKOTPerKitchen(
              cartItems: cartItems,
              order: updatedOrder,
              referenceNumber: ref,
              invoiceNumber: updatedOrder.invoiceNumber,
              branchId: updatedOrder.branchId,
              orderedAt: updatedOrder.createdAt,
            ),
          );
        }
        if (printInvoice) {
          printFailed.addAll(
            await printSvc.printFinalBill(
              order: updatedOrder,
              cartItems: cartItems,
              asTaxInvoice: printInvoice,
            ),
          );
        }
        if (printFailed.isNotEmpty && dialogContext.mounted) {
          showPrintFailedDialog(dialogContext, printFailed);
        }

        if (dialogContext.mounted) Navigator.of(dialogContext).pop(true);
        onPaymentRecorded?.call();
      },
    ),
  );
}

class CartPanel extends StatelessWidget {
  const CartPanel({
    super.key,
    this.scrollController,
    this.closeOnComplete = false,

    /// When true ([CartPanel] is shown inside [showModalBottomSheet]), successful KOT / Pay closes the sheet via [onCloseCart].
    /// [closeOnComplete] still controls dine‑in behaviours (e.g. payment dialog **Close** also dismisses sheet).
    this.isModalBottomSheet = false,
    this.onCloseCart,
    this.openPaymentOnLoad = false,
  });

  /// Optional scroll controller for use in DraggableScrollableSheet (mobile).
  final ScrollController? scrollController;
  final bool closeOnComplete;

  /// True when hosted in a modal bottom sheet (mobile cart FAB).
  final bool isModalBottomSheet;
  final void Function(bool closed)? onCloseCart;
  final bool openPaymentOnLoad;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ───────────── CART LIST (structure only; line data via BlocSelector in each tile) ─────────────
        BlocBuilder<CartCubit, CartState>(
          buildWhen: _cartListStructureChanged,
          builder: (context, state) {
            return Container(
              padding: const EdgeInsets.fromLTRB(AppPadding.screenHorizontal, 12, AppPadding.screenHorizontal, 90),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: state.items.isEmpty
                  ? Center(
                      child: Text(
                        "Cart is empty",
                        style: AppStyles.getRegularTextStyle(fontSize: 16),
                      ),
                    )
                  : CustomScrollView(
                      controller: scrollController,
                      key: const ValueKey('cart_scroll_view'),
                      slivers: [
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final id = state.items[index].id;
                              return CartItemTile(
                                key: ValueKey<int>(id),
                                cartItemId: id,
                              );
                            },
                            childCount: state.items.length,
                          ),
                        ),
                        const SliverToBoxAdapter(
                          child: SizedBox(height: 90),
                        ),
                      ],
                    ),
            );
          },
        ),

        // ───────────── BOTTOM SUMMARY BAR ─────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BlocBuilder<CartCubit, CartState>(
            builder: (context, state) {
              final itemCount = state.items.length;

              final totalAmount = state.items.fold<double>(0, (s, e) => s + e.total);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: AppPadding.screenHorizontal, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cartCubit = context.read<CartCubit>();
                      if (openPaymentOnLoad && state.items.isNotEmpty) {
                        final key = '${cartCubit.orderType}:${state.items.first.cartId}:${cartCubit.isOpenedForEdit}:${cartCubit.isEditingPaidOrder}';
                        if (!_autoPaymentShownKeys.contains(key)) {
                          _autoPaymentShownKeys.add(key);
                          WidgetsBinding.instance.addPostFrameCallback((_) async {
                            if (!context.mounted) return;
                            final totalAmount = state.items.fold<double>(0, (s, e) => s + e.total);
                            await _showPaymentDialog(
                              context,
                              totalAmount,
                              isEditing: cartCubit.isOpenedForEdit || cartCubit.isEditingPaidOrder,
                              isDelivery: cartCubit.orderType == OrderType.delivery,
                              deliveryPartner: cartCubit.deliveryPartner,
                            );
                            if (!isModalBottomSheet) {
                              onCloseCart?.call(true);
                            }
                          });
                        }
                      }
                      final isNarrow = constraints.maxWidth < 420;
                      // final preferHorizontalButtons = MediaQuery.sizeOf(context).width < 1400;

                      //  MediaQuery.sizeOf(context).width <= 1400
                      //     ?
                      Widget totalWidget = Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(
                          "$itemCount item${itemCount == 1 ? '' : 's'}",
                          style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        Text(
                          RuntimeAppSettings.money(totalAmount),
                          style: AppStyles.getBoldTextStyle(fontSize: 18),
                        ),
                      ]);
                      // : Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       Text(
                      //         "$itemCount item${itemCount == 1 ? '' : 's'}",
                      //         style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.black54),
                      //       ),
                      //       Text(
                      //         "Total payable",
                      //         style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.grey.shade700),
                      //       ),
                      //       Text(
                      //         RuntimeAppSettings.money(totalAmount),
                      //         style: AppStyles.getBoldTextStyle(fontSize: 18),
                      //       ),
                      //     ],
                      //   );

                      Widget buttonsWidget = BlocBuilder<CartCubit, CartState>(
                        builder: (context, cartState) {
                          final cartCubit = context.read<CartCubit>();
                          final isEditingPaidOrder = cartCubit.isEditingPaidOrder;
                          final isOpenedForEdit = cartCubit.isOpenedForEdit;
                          final isDelivery = cartCubit.orderType == OrderType.delivery;
                          final shouldSaveAsEdit = isOpenedForEdit || isEditingPaidOrder;

                          // Delivery: only Save button (no KOT, no Pay) — Save opens payment dialog
                          if (isDelivery || isEditingPaidOrder) {
                            final saveButton = CustomButton(
                              width: 80,
                              onPressed: state.items.isEmpty
                                  ? () {}
                                  : () async {
                                      await _showPaymentDialog(
                                        context,
                                        totalAmount,
                                        isEditing: shouldSaveAsEdit,
                                        isDelivery: isDelivery,
                                        deliveryPartner: cartCubit.deliveryPartner,
                                      );
                                      if (!isModalBottomSheet) {
                                        onCloseCart?.call(true);
                                      }
                                    },
                              text: "Save",
                            );
                            final eye = IconButton(
                              tooltip: 'View cart',
                              icon: Icon(
                                Icons.visibility_outlined,
                                color: state.items.isNotEmpty ? AppColors.primaryColor : Colors.grey,
                              ),
                              onPressed: state.items.isNotEmpty ? () => showCartPreviewDialog(context) : null,
                            );
                            // if (!isNarrow) {
                            //   return Column(
                            //     crossAxisAlignment: CrossAxisAlignment.stretch,
                            //     children: [
                            //       Align(alignment: Alignment.centerRight, child: eye),
                            //       const SizedBox(height: 4),
                            //       saveButton,
                            //     ],
                            //   );
                            // }
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                eye,
                                const SizedBox(width: 4),
                                saveButton,
                              ],
                            );
                          }

                          // if (isNarrow) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                tooltip: 'View cart',
                                icon: Icon(
                                  Icons.visibility_outlined,
                                  color: state.items.isNotEmpty ? AppColors.primaryColor : Colors.grey,
                                ),
                                onPressed: state.items.isNotEmpty ? () => showCartPreviewDialog(context) : null,
                              ),
                              const SizedBox(width: 4),
                              _KitchenOrderIconButton(
                                width: 110,
                                onPressed: state.items.isEmpty
                                    ? null
                                    : () async {
                                        final hasRef = cartCubit.currentKOTReference != null && cartCubit.currentKOTReference!.trim().isNotEmpty;
                                        final skipKotReferenceDialog = hasRef && isOpenedForEdit;
                                        if (skipKotReferenceDialog) {
                                          try {
                                            final printFailed = await cartCubit.saveKOTWithExistingReference();
                                            if (context.mounted) {
                                              CustomSnackBar.showKotSaved(context: context);
                                              if (printFailed.isNotEmpty) {
                                                showPrintFailedDialog(context, printFailed);
                                              }
                                              if (isModalBottomSheet) {
                                                onCloseCart?.call(true);
                                              } else if (closeOnComplete) {
                                                Navigator.maybePop(context);
                                              }
                                              schedulePopSaleScreenToDineIn(context);
                                            }
                                          } catch (e) {
                                            if (context.mounted) showErrorDialog(context, e);
                                          }
                                        } else {
                                          showKOTDialog(context);
                                        }
                                      },
                              ),
                              const SizedBox(width: 12),
                              CustomButton(
                                width: 80,
                                onPressed: state.items.isEmpty
                                    ? () {}
                                    : () async {
                                        await _showPaymentDialog(context, totalAmount, isEditing: isOpenedForEdit);
                                        if (!isModalBottomSheet) {
                                          onCloseCart?.call(true);
                                        }
                                      },
                                text: "Pay",
                              ),
                            ],
                          );
                          // }

                          // Narrow screens: stack buttons to avoid overflow.
                          // return Column(
                          //   crossAxisAlignment: CrossAxisAlignment.stretch,
                          //   children: [
                          //     Align(
                          //       alignment: Alignment.centerRight,
                          //       child: IconButton(
                          //         tooltip: 'View cart',
                          //         icon: Icon(
                          //           Icons.visibility_outlined,
                          //           color: state.items.isNotEmpty ? AppColors.primaryColor : Colors.grey,
                          //         ),
                          //         onPressed: state.items.isNotEmpty ? () => showCartPreviewDialog(context) : null,
                          //       ),
                          //     ),
                          //     const SizedBox(height: 4),
                          //     _KitchenOrderIconButton(
                          //       width: constraints.maxWidth,
                          //       onPressed: state.items.isEmpty
                          //           ? null
                          //           : () async {
                          //               final hasRef = cartCubit.currentKOTReference != null && cartCubit.currentKOTReference!.trim().isNotEmpty;
                          //               final skipKotReferenceDialog = hasRef && (isOpenedForEdit || cartCubit.orderType == 'dine_in');
                          //               if (skipKotReferenceDialog) {
                          //                 try {
                          //                   final printFailed = await cartCubit.saveKOTWithExistingReference();
                          //                   if (context.mounted) {
                          //                     CustomSnackBar.showKotSaved(context: context);
                          //                     if (printFailed.isNotEmpty) {
                          //                       showPrintFailedDialog(context, printFailed);
                          //                     }
                          //                     if (closeOnComplete) {
                          //                       Navigator.maybePop(context);
                          //                     }
                          //                     schedulePopSaleScreenToDineIn(context);
                          //                   }
                          //                 } catch (e) {
                          //                   if (context.mounted) showErrorDialog(context, e);
                          //                 }
                          //               } else {
                          //                 showKOTDialog(context);
                          //               }
                          //             },
                          //     ),
                          //     const SizedBox(height: 10),
                          //     CustomButton(
                          //       width: 80,
                          //       onPressed: state.items.isEmpty
                          //           ? () {}
                          //           : () async {
                          //               await _showPaymentDialog(context, totalAmount, isEditing: isOpenedForEdit);
                          //               onCloseCart?.call(true);
                          //             },
                          //       text: "Pay",
                          //     ),
                          //   ],
                          // );
                        },
                      );

                      if (!isNarrow) {
                        return Row(
                          children: [
                            totalWidget,
                            const Spacer(),
                            buttonsWidget,
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(child: totalWidget),
                            ],
                          ),
                          const SizedBox(height: 10),
                          buttonsWidget,
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void showKOTDialog(BuildContext context) {
    final parentContext = context;
    final cartCubit = context.read<CartCubit>();
    final currentReference = cartCubit.currentKOTReference;
    final referenceController = TextEditingController(text: currentReference ?? '');

    final suggestionsRef = <String>[
      if (locator.isRegistered<SharedPreferences>()) ...KotReferenceRecents.loadSync(locator<SharedPreferences>()),
    ];

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = MediaQuery.of(context).size.width;

              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: width > 600 ? 420 : width * 0.95,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: StatefulBuilder(
                    builder: (context, setDialogState) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// Header
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  currentReference == null ? 'Add reference' : 'Edit reference',
                                  style: AppStyles.getBoldTextStyle(fontSize: 20),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          /// Input (saved refs only; use "Save to dropdown" to add the current text)
                          _KotReferenceAutocompleteField(
                            controller: referenceController,
                            suggestions: List<String>.from(suggestionsRef),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                final t = referenceController.text.trim();
                                if (t.isEmpty) {
                                  CustomSnackBar.showWarning(
                                    context: context,
                                    message: 'Enter a reference first, then save it to the list.',
                                  );
                                  return;
                                }
                                KotReferenceRecents.savePinnedReference(t);
                                if (locator.isRegistered<SharedPreferences>()) {
                                  suggestionsRef
                                    ..clear()
                                    ..addAll(KotReferenceRecents.loadSync(locator<SharedPreferences>()));
                                }
                                setDialogState(() {});
                                CustomSnackBar.showSuccess(
                                  context: context,
                                  message: 'Saved to reference list',
                                  duration: const Duration(milliseconds: 1600),
                                );
                              },
                              icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                              label: Text('Save to dropdown', style: AppStyles.getMediumTextStyle(fontSize: 13)),
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// Actions
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                                child: const Text('Cancel'),
                              ),
                              const Spacer(),
                              CustomButton(
                                width: 80,
                                text: 'Save',
                                onPressed: () async {
                                  final value = referenceController.text.trim();
                                  try {
                                    final printFailed = await cartCubit.saveKOT(value);
                                    if (!context.mounted) return;
                                    Navigator.of(context, rootNavigator: true).pop();
                                    if (parentContext.mounted) {
                                      CustomSnackBar.showKotSaved(context: parentContext);
                                      if (printFailed.isNotEmpty) {
                                        showPrintFailedDialog(parentContext, printFailed);
                                      }
                                    }
                                    if (isModalBottomSheet) {
                                      onCloseCart?.call(true);
                                    } else if (closeOnComplete && parentContext.mounted) {
                                      Navigator.of(parentContext).pop();
                                    }
                                    schedulePopSaleScreenToDineIn(parentContext);
                                  } catch (e) {
                                    if (context.mounted) {
                                      showErrorDialog(context, e);
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    ).whenComplete(referenceController.dispose);
  }

  Future<bool> _showPaymentDialog(
    BuildContext context,
    double totalAmount, {
    bool isEditing = false,
    bool isDelivery = false,
    String? deliveryPartner,
  }) async {
    // Capture while [context] is stable; avoid context.read after async gaps in [onSave].
    final cartCubit = context.read<CartCubit>();
    final prefill = await cartCubit.getPaymentPrefillForEdit();
    final cartLines = cartCubit.state.items;
    final offerLines = cartLines.isEmpty ? <PaymentOfferLine>[] : await buildPaymentOfferLines(cartLines, locator<ItemRepository>());
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => PaymentDialog(
        totalAmount: totalAmount,
        offerLines: offerLines,
        closeSheetOnClose: closeOnComplete,
        parentContext: context,
        isDelivery: isDelivery,
        deliveryPartner: deliveryPartner,
        prefill: prefill,
        onSave: (customerDetails, discount, payments, {required printInvoice, required printKot}) async {
          try {
            List<String> printFailed;
            if (isEditing) {
              printFailed = await cartCubit.updateOrderWithPayment(
                customerDetails: customerDetails,
                discount: discount,
                payments: payments,
                onlineOrderNumber: customerDetails['onlineOrderNumber'] as String?,
                printInvoice: printInvoice,
                printKot: printKot,
              );
            } else {
              printFailed = await cartCubit.placeOrderWithPayment(
                customerDetails: customerDetails,
                discount: discount,
                payments: payments,
                onlineOrderNumber: customerDetails['onlineOrderNumber'] as String?,
                printInvoice: printInvoice,
                printKot: printKot,
              );
            }

            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop(true); // ✅ return true
            }

            // Show printer warning before popping the cart sheet, so [context] stays valid.
            if (printFailed.isNotEmpty && context.mounted) {
              showPrintFailedDialog(context, printFailed);
            }

            if (isModalBottomSheet) {
              onCloseCart?.call(true);
            } else if (context.mounted && closeOnComplete) {
              Navigator.of(context).pop(); // close embedded / legacy sheet
            }
            if (context.mounted) {
              schedulePopSaleScreenToDineIn(context);
            }
          } catch (e) {
            if (dialogContext.mounted) {
              showErrorDialog(dialogContext, e);
            }
          }
        },
      ),
    );

    return result ?? false;
  }
}

// Payment Dialog Widget

class PaymentDialog extends StatefulWidget {
  final double totalAmount;
  final List<PaymentOfferLine> offerLines;
  final bool closeSheetOnClose;
  final BuildContext parentContext;
  final bool isDelivery;
  final String? deliveryPartner;
  final Map<String, dynamic>? prefill;
  final PaymentDialogOnSave onSave;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
    this.offerLines = const [],
    required this.closeSheetOnClose,
    required this.parentContext,
    this.isDelivery = false,
    this.deliveryPartner,
    this.prefill,
    required this.onSave,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _formKey = GlobalKey<FormState>();

  /// Third-party apps (NOON, etc.). Own fleet uses delivery partner name `NORMAL`.
  bool get _isPartnerDelivery =>
      widget.isDelivery && widget.deliveryPartner != null && widget.deliveryPartner!.trim().isNotEmpty && widget.deliveryPartner!.trim().toUpperCase() != 'NORMAL';

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _genderController = TextEditingController();

  final _cashController = TextEditingController();
  final _creditController = TextEditingController();
  final _cardController = TextEditingController();
  final _onlineController = TextEditingController();
  final _otherController = TextEditingController();
  final _onlineOrderNumberController = TextEditingController();

  final _cashFocusNode = FocusNode();
  final _cardFocusNode = FocusNode();
  final _creditFocusNode = FocusNode();
  final _onlineFocusNode = FocusNode();
  final _otherFocusNode = FocusNode();

  final TextEditingController _discountByAmountController = TextEditingController();
  final TextEditingController _discountByPercentController = TextEditingController();

  /// Manual discount: either fixed amount **or** % (two fields; only one applies). Stacked with offer discount.
  String _manualDiscountMode = 'amount';
  double _manualRawValue = 0;

  List<_AppliedOffer> _dropdownOffers = [];
  List<_AppliedOffer> _autoDayOffers = [];
  int? _selectedOfferIndex;
  bool _loadingOffers = true;
  double _finalAmount = 0;

  final CustomerRepository _customerRepo = locator<CustomerRepository>();
  List<PosCustomer> _allCustomers = [];
  bool _loadingCustomers = true;
  bool _isSubmitting = false;
  bool _showOtherPaymentField = false;
  bool _printInvoice = true;

  /// Off by default: KOT is usually sent earlier via the KOT button; enable when settling should re-print kitchen.
  bool _printKot = false;

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefill;

    final safeSubtotal = _nonNegativeOrderSubtotal(widget.totalAmount);
    _finalAmount = safeSubtotal;

    if (prefill != null) {
      _nameController.text = (prefill['name'] as String?)?.trim() ?? '';
      _phoneController.text = (prefill['phone'] as String?)?.trim() ?? '';
      _emailController.text = (prefill['email'] as String?)?.trim() ?? '';
      _genderController.text = (prefill['gender'] as String?)?.trim() ?? '';
      _onlineOrderNumberController.text = (prefill['onlineOrderNumber'] as String?)?.trim() ?? '';
    }

    _updateFinalAmount();
    unawaited(_loadOfferChoices());

    // Prefill payment amounts only when prefill includes cash/card/credit/online (e.g. counter edit). Log pay omits those keys.
    if (prefill != null) {
      final cashP = (prefill['cash'] as num?)?.toDouble() ?? 0.0;
      final creditP = (prefill['credit'] as num?)?.toDouble() ?? 0.0;
      final cardP = (prefill['card'] as num?)?.toDouble() ?? 0.0;
      final onlineP = (prefill['online'] as num?)?.toDouble() ?? 0.0;
      final hasSavedPayments = cashP + creditP + cardP + onlineP > 0.005;
      if (hasSavedPayments) {
        if (cashP > 0) _cashController.text = cashP.toStringAsFixed(2);
        if (creditP > 0) _creditController.text = creditP.toStringAsFixed(2);
        if (cardP > 0) _cardController.text = cardP.toStringAsFixed(2);
        if (onlineP > 0) _onlineController.text = onlineP.toStringAsFixed(2);
      }
    }

    _loadCustomers();
    _cashFocusNode.addListener(_onPaymentFocusCash);
    _cardFocusNode.addListener(_onPaymentFocusCard);
    _creditFocusNode.addListener(_onPaymentFocusCredit);
    _onlineFocusNode.addListener(_onPaymentFocusOnline);
    _otherFocusNode.addListener(_onPaymentFocusOther);
  }

  Future<void> _loadOfferChoices() async {
    setState(() => _loadingOffers = true);
    try {
      final db = locator<AppDatabase>();
      final session = await db.sessionDao.getActiveSession();
      final branchId = session?.branchId ?? 1;
      final rows = await db.pullDataDao.getOffersForBranch(branchId);
      final today = DateUtils.dateOnly(DateTime.now());
      final lines = widget.offerLines;

      final dropdown = <_AppliedOffer>[];
      final autoDay = <_AppliedOffer>[];
      for (final row in rows) {
        final payloadRaw = row.otherName;
        if (payloadRaw == null || payloadRaw.trim().isEmpty) continue;
        final payload = _offerDecodePayloadJson(payloadRaw);
        if (payload == null || payload.isEmpty) continue;

        if (!_offerPayloadMapIsActive(payload)) continue;

        final fromDate = DateTime.tryParse(payload['from_date']?.toString() ?? '');
        final toDate = DateTime.tryParse(payload['to_date']?.toString() ?? '');
        if (fromDate != null && toDate != null) {
          final fromOnly = DateUtils.dateOnly(fromDate);
          final toOnly = DateUtils.dateOnly(toDate);
          if (today.isBefore(fromOnly) || today.isAfter(toOnly)) continue;
        }

        final rawType = payload['type']?.toString().trim().toLowerCase() ?? '';
        final type = (rawType == 'percentage' || rawType == 'percent' || rawType == '%')
            ? _OfferValueType.percentage
            : (rawType == 'amount' || rawType == 'fixed' || rawType == 'flat' || rawType == 'fixed_amount' || rawType == 'value')
                ? _OfferValueType.amount
                : null;
        if (type == null) continue;

        final value = double.tryParse(payload['value']?.toString() ?? '') ?? 0.0;
        if (value <= 0) continue;

        final applicable = _offerApplicableSubtotal(payload, lines, widget.totalAmount);
        if (applicable <= 0) continue;

        final discount = type == _OfferValueType.percentage ? (applicable * (value / 100)).clamp(0.0, applicable).toDouble() : value.clamp(0.0, applicable).toDouble();
        if (discount <= 0) continue;

        final days = _offerJsonDayList(payload['day'] ?? payload['days']);
        if (!OfferSchedule.isActiveAt(
          DateTime.now(),
          days: days,
          startTime: payload['start_time']?.toString(),
          offerHours: OfferSchedule.coerceOfferHours(payload['offer_hour']),
        )) {
          continue;
        }

        final offerUuid = (payload['uuid']?.toString().trim().isNotEmpty == true) ? payload['uuid'].toString().trim() : row.uuid;

        final offerNameFromPayload = payload['offer_name']?.toString().trim() ?? '';
        final displayName = offerNameFromPayload.isNotEmpty ? offerNameFromPayload : (row.categoryName.trim().isEmpty ? 'Offer' : row.categoryName.trim());

        final built = _AppliedOffer(
          offerId: row.id,
          uuid: offerUuid,
          name: displayName,
          toDateText: payload['to_date']?.toString() ?? '',
          value: value,
          type: type,
          discountAmount: discount,
          isAutoDay: days.isNotEmpty,
        );

        if (days.isNotEmpty) {
          autoDay.add(built);
        } else {
          dropdown.add(built);
        }
      }

      if (!mounted) return;
      setState(() {
        _dropdownOffers = dropdown;
        _autoDayOffers = autoDay;
        _applyPrefillDiscountAfterOffersLoaded();
        _loadingOffers = false;
        _recalculateFinalAmount();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dropdownOffers = [];
        _autoDayOffers = [];
        _selectedOfferIndex = null;
        _applyPrefillDiscountAfterOffersLoaded();
        _loadingOffers = false;
        _recalculateFinalAmount();
      });
    }
  }

  /// Maps cart/order prefill to manual + optional matched offer once offers are loaded.
  void _applyPrefillDiscountAfterOffersLoaded() {
    final prefill = widget.prefill;
    if (prefill == null) {
      _selectedOfferIndex = null;
      return;
    }

    final savedDisc = (prefill['discountAmount'] as num?)?.toDouble() ?? 0.0;
    final appliedRaw = prefill['appliedOffer'];
    int? matchedIdx;
    if (appliedRaw is Map && _dropdownOffers.isNotEmpty) {
      final wantUuid = (appliedRaw['uuid'] ?? '').toString().trim().toLowerCase();
      if (wantUuid.isNotEmpty) {
        for (var i = 0; i < _dropdownOffers.length; i++) {
          if (_dropdownOffers[i].uuid.trim().toLowerCase() == wantUuid) {
            matchedIdx = i;
            break;
          }
        }
      }
      if (matchedIdx == null) {
        final want = (appliedRaw['name'] ?? '').toString().trim().toLowerCase();
        if (want.isNotEmpty) {
          for (var i = 0; i < _dropdownOffers.length; i++) {
            if (_dropdownOffers[i].name.trim().toLowerCase() == want) {
              matchedIdx = i;
              break;
            }
          }
        }
      }
    }

    _selectedOfferIndex = matchedIdx;
    final autoDisc = _autoDayOffers.fold<double>(0, (a, o) => a + o.discountAmount);
    final manualOfferDisc = matchedIdx != null ? _dropdownOffers[matchedIdx].discountAmount : 0.0;
    final offerDisc = autoDisc + manualOfferDisc;
    var residual = savedDisc - offerDisc;
    if (residual < 0.009) residual = 0;

    if (matchedIdx == null && savedDisc > 0) {
      final savedDiscType = prefill['discountType'] as String?;
      if (savedDiscType == 'percentage') {
        _manualDiscountMode = 'percentage';
        final subtotal = widget.totalAmount;
        final pct = (savedDisc >= 0 && savedDisc <= 100) ? savedDisc : (subtotal > 0 ? (savedDisc / subtotal * 100) : 0.0);
        _manualRawValue = pct;
      } else {
        _manualDiscountMode = 'amount';
        _manualRawValue = savedDisc;
      }
    } else {
      _manualDiscountMode = 'amount';
      _manualRawValue = residual;
    }
    _syncManualDiscountControllerFromState();
  }

  void _syncManualDiscountControllerFromState() {
    var amountText = '';
    var percentText = '';
    if (_manualRawValue > 0) {
      if (_manualDiscountMode == 'percentage') {
        percentText = _manualRawValue % 1 == 0 ? _manualRawValue.round().toString() : _manualRawValue.toStringAsFixed(2);
      } else {
        amountText = _manualRawValue.toStringAsFixed(2);
      }
    }
    if (_discountByAmountController.text != amountText) {
      _discountByAmountController.value = TextEditingValue(
        text: amountText,
        selection: TextSelection.collapsed(offset: amountText.length),
      );
    }
    if (_discountByPercentController.text != percentText) {
      _discountByPercentController.value = TextEditingValue(
        text: percentText,
        selection: TextSelection.collapsed(offset: percentText.length),
      );
    }
  }

  void _onDiscountByAmountChanged(String text) {
    final p = double.tryParse(text.trim()) ?? 0.0;
    setState(() {
      if (p > 0.0001) {
        _discountByPercentController.clear();
        _manualDiscountMode = 'amount';
        _manualRawValue = p;
      } else {
        final pct = double.tryParse(_discountByPercentController.text.trim()) ?? 0.0;
        if (pct > 0.0001) {
          _manualDiscountMode = 'percentage';
          _manualRawValue = pct;
        } else {
          _manualRawValue = 0;
        }
      }
      _recalculateFinalAmount();
    });
  }

  void _onDiscountByPercentChanged(String text) {
    final p = double.tryParse(text.trim()) ?? 0.0;
    setState(() {
      if (p > 0.0001) {
        _discountByAmountController.clear();
        _manualDiscountMode = 'percentage';
        _manualRawValue = p;
      } else {
        final amt = double.tryParse(_discountByAmountController.text.trim()) ?? 0.0;
        if (amt > 0.0001) {
          _manualDiscountMode = 'amount';
          _manualRawValue = amt;
        } else {
          _manualRawValue = 0;
        }
      }
      _recalculateFinalAmount();
    });
  }

  /// When a payment field gets focus, set its value to remaining amount.
  void _onPaymentFocusCash() {
    if (!_cashFocusNode.hasFocus) return;
    _setPaymentToRemainder(_cashController, [_cardController, _creditController, _onlineController]);
  }

  void _onPaymentFocusCard() {
    if (!_cardFocusNode.hasFocus) return;
    _setPaymentToRemainder(_cardController, [_cashController, _creditController, _onlineController]);
  }

  void _onPaymentFocusCredit() {
    if (!_creditFocusNode.hasFocus) return;
    _setPaymentToRemainder(_creditController, [_cashController, _cardController, _onlineController]);
  }

  void _onPaymentFocusOnline() {
    if (!_onlineFocusNode.hasFocus) return;
    _setPaymentToRemainder(_onlineController, [_cashController, _cardController, _creditController, _otherController]);
  }

  void _onPaymentFocusOther() {
    if (!_otherFocusNode.hasFocus) return;
    _setPaymentToRemainder(
      _otherController,
      widget.isDelivery ? [_cashController, _cardController, _creditController, _onlineController] : [_cashController, _cardController, _creditController],
    );
  }

  void _setPaymentToRemainder(TextEditingController target, List<TextEditingController> others) {
    double sum = 0;
    for (final c in others) {
      sum += double.tryParse(c.text.trim()) ?? 0;
    }
    final remainder = (_finalAmount - sum).clamp(0.0, double.infinity);
    target.text = remainder.toStringAsFixed(2);
    setState(() {});
  }

  Future<void> _loadCustomers() async {
    setState(() => _loadingCustomers = true);
    try {
      final customers = await _customerRepo.getAllLocalCustomers();
      setState(() {
        _allCustomers = customers;
        _loadingCustomers = false;
      });
    } catch (e) {
      setState(() => _loadingCustomers = false);
    }
  }

  void _prefillCustomer(PosCustomer customer) {
    setState(() {
      _nameController.text = customer.name;
      _phoneController.text = customer.phone ?? '';
      _emailController.text = customer.email ?? '';
      _genderController.text = customer.gender ?? '';
    });
  }

  /// Save customer only if at least one customer field has data.
  Future<void> _saveNewCustomerIfNeeded() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final gender = _genderController.text.trim();

    if (name.isEmpty && phone.isEmpty && email.isEmpty) return;

    bool customerExists = false;
    if (phone.isNotEmpty) {
      final existingByPhone = await _customerRepo.getCustomersByPhone(phone);
      customerExists = existingByPhone.isNotEmpty;
    }
    if (!customerExists && email.isNotEmpty) {
      final existingByEmail = await _customerRepo.getCustomersByEmail(email);
      customerExists = existingByEmail.isNotEmpty;
    }

    if (!customerExists) {
      final now = DateTime.now();
      final newCustomer = PosCustomer.fromRow(
        isSynced: false,
        row: CustomerCreatedUpdated(
          id: 0,
          uuid: '',
          branchId: 0,
          customerName: name.isEmpty ? (phone.isNotEmpty ? phone : 'Customer') : name,
          customerNumber: phone,
          customerEmail: email,
          customerAddress: '',
          customerGender: gender,
          cardNo: '',
          createdAt: now,
          updatedAt: now,
          deletedAt: null,
        ),
      );
      await _customerRepo.saveCustomer(newCustomer);
      await _loadCustomers();
    }
  }

  void _updateFinalAmount() {
    setState(_recalculateFinalAmount);
  }

  /// [double.clamp] requires `min <= max`; a negative or non-finite order subtotal would throw.
  static double _nonNegativeOrderSubtotal(double totalAmount) {
    if (totalAmount.isNaN || !totalAmount.isFinite) return 0.0;
    return totalAmount < 0 ? 0.0 : totalAmount;
  }

  double _manualDiscountAmountComputed() {
    final cap = _nonNegativeOrderSubtotal(widget.totalAmount);
    if (_manualDiscountMode == 'percentage') {
      return (cap * (_manualRawValue / 100)).clamp(0.0, cap).toDouble();
    }
    return _manualRawValue.clamp(0.0, cap).toDouble();
  }

  void _recalculateFinalAmount() {
    final base = _nonNegativeOrderSubtotal(widget.totalAmount);
    final manualDisc = _manualDiscountAmountComputed();
    final autoDisc = _autoDayOffers.fold<double>(0, (a, o) => a + o.discountAmount);
    final dropdownDisc =
        _selectedOfferIndex != null && _selectedOfferIndex! >= 0 && _selectedOfferIndex! < _dropdownOffers.length ? _dropdownOffers[_selectedOfferIndex!].discountAmount : 0.0;
    _finalAmount = (base - manualDisc - autoDisc - dropdownDisc).clamp(0.0, double.infinity);
  }

  bool _validatePayments() {
    final cash = double.tryParse(_cashController.text) ?? 0;
    final credit = double.tryParse(_creditController.text) ?? 0;
    final card = double.tryParse(_cardController.text) ?? 0;
    final online = double.tryParse(_onlineController.text) ?? 0;
    final other = double.tryParse(_otherController.text) ?? 0;
    return ((cash + credit + card + online + other) - _finalAmount).abs() < 0.01;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          width: width > 1200
              ? 820
              : width > 900
                  ? 760
                  : width > 700
                      ? width * 0.9
                      : width * 0.92,
          constraints: BoxConstraints(maxHeight: height * 0.88),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(blurRadius: 40, color: Colors.black26),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(),
                const Divider(height: 1),
                _content(),
                _footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /* ───────── HEADER (like image: dark blue bar, TOTAL, AED, amount) ───────── */

  String get _currencyLabel => RuntimeAppSettings.currency;

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'TOTAL',
            style: AppStyles.getBoldTextStyle(fontSize: 14, color: Colors.white).copyWith(
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _currencyLabel,
                style: AppStyles.getRegularTextStyle(fontSize: 15, color: Colors.white),
              ),
              const SizedBox(width: 6),
              Text(
                widget.totalAmount.toStringAsFixed(2),
                style: AppStyles.getBoldTextStyle(fontSize: 28, color: Colors.white),
              ),
            ],
          ),
          if (!_loadingOffers && _autoDayOffers.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_offer_outlined, size: 15, color: Colors.white.withValues(alpha: 0.92)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _autoDayOffers.length == 1 ? 'Day offer: ${_autoDayOffers.first.name}' : 'Day offers active (${_autoDayOffers.length})',
                    style: AppStyles.getSemiBoldTextStyle(fontSize: 12, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /* ───────── CONTENT (fixed height — no scroll) ───────── */

  Widget _content() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, size: 18, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              Text('Customer Details', style: AppStyles.getSemiBoldTextStyle(fontSize: 14)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _customerFields(),
          ),
          const SizedBox(height: 4),
          _discountSectionTitle(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _discountFields(),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.payment, size: 18, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              Text('Payment Methods', style: AppStyles.getSemiBoldTextStyle(fontSize: 14)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _paymentFields(),
                if (!_validatePayments() &&
                    (_cashController.text.isNotEmpty || _creditController.text.isNotEmpty || _cardController.text.isNotEmpty || _onlineController.text.isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Payment total must match payable amount',
                      style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.red.shade700),
                    ),
                  ),
                if (widget.isDelivery && _isPartnerDelivery)
                  SizedBox(
                    width: 260,
                    child: CustomTextField(
                      controller: _onlineOrderNumberController,
                      labelText: 'Online Order Number (optional)',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerFields() {
    if (_loadingCustomers) {
      return const Center(child: CircularProgressIndicator());
    }

    final phoneSuggestions = _allCustomers.where((c) => c.phone != null && c.phone!.isNotEmpty).map((c) => c.phone!).toSet().toList();
    final nameSuggestions = _allCustomers.map((c) => c.name).toSet().toList();
    final emailSuggestions = _allCustomers.where((c) => c.email != null && c.email!.isNotEmpty).map((c) => c.email!).toSet().toList();
    final genderOptions = ['Male', 'Female', 'Other'];
    final customersByName = _allCustomers.where((c) => c.name.toLowerCase().contains(_nameController.text.toLowerCase())).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row: Contact Number, Name, Email (like image)
        Row(
          children: [
            Expanded(
              child: AutoCompleteTextField<String>(
                items: phoneSuggestions,
                displayStringFunction: (item) => item,
                defaultText: '',
                labelText: 'Contact Number',
                controller: _phoneController,
                filterType: FilterType.contains,
                onSelected: (selectedPhone) {
                  final customer = _allCustomers.firstWhere(
                    (c) => c.phone == selectedPhone,
                    orElse: () => PosCustomer.placeholder(phone: selectedPhone),
                  );
                  if (customer.id > 0) _prefillCustomer(customer);
                },
              ),
            ),
            Expanded(
              child: AutoCompleteTextField<String>(
                items: nameSuggestions,
                displayStringFunction: (item) => item,
                defaultText: '',
                labelText: 'Name',
                controller: _nameController,
                filterType: FilterType.contains,
                onSelected: (selectedName) {
                  final customer = _allCustomers.firstWhere(
                    (c) => c.name == selectedName,
                    orElse: () => PosCustomer.placeholder(name: selectedName),
                  );
                  if (customer.id > 0) _prefillCustomer(customer);
                },
                onChanged: (value) {
                  final matching = customersByName.where((c) => c.name.toLowerCase() == value.toLowerCase()).toList();
                  if (matching.isNotEmpty) _prefillCustomer(matching.first);
                },
              ),
            ),
            Expanded(
              child: AutoCompleteTextField<String>(
                items: emailSuggestions,
                displayStringFunction: (item) => item,
                defaultText: '',
                labelText: 'Email',
                controller: _emailController,
                filterType: FilterType.contains,
                onSelected: (selectedEmail) {
                  final customer = _allCustomers.firstWhere(
                    (c) => c.email == selectedEmail,
                    orElse: () => PosCustomer.placeholder(email: selectedEmail),
                  );
                  if (customer.id > 0) _prefillCustomer(customer);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Choose Gender dropdown (like image)
        DropdownButtonFormField<String>(
          value: genderOptions.contains(_genderController.text) ? _genderController.text : null,
          decoration: InputDecoration(
            labelStyle: TextStyle(
              color: AppColors.hintFontColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            filled: false,
            hintText: 'Choose Gender',
            fillColor: Colors.white,
            hintStyle: TextStyle(
              color: AppColors.hintFontColor,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            isDense: true,
            isCollapsed: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 11,
            ),
            errorStyle: const TextStyle(
              fontSize: 10,
              height: 1,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.5),
              ),
            ),
          ),
          items: genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
          onChanged: (v) {
            setState(() => _genderController.text = v ?? '');
          },
        ),
      ],
    );
  }

  Widget _discountFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discount by Amount',
                    style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.textColor),
                  ),
                  const SizedBox(height: 4),
                  CustomTextField(
                    controller: _discountByAmountController,
                    labelText: '',
                    keyBoardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                    onChanged: _onDiscountByAmountChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discount by %',
                    style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.textColor),
                  ),
                  const SizedBox(height: 4),
                  CustomTextField(
                    controller: _discountByPercentController,
                    labelText: '',
                    keyBoardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                    onChanged: _onDiscountByPercentChanged,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Amount Payable',
                    style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.textColor),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$_currencyLabel ${_finalAmount.toStringAsFixed(2)}',
                      style: AppStyles.getBoldTextStyle(fontSize: 18, color: AppColors.primaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!_loadingOffers && _dropdownOffers.isNotEmpty) ...[
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              if (!maxW.isFinite || maxW <= 0) {
                return SizedBox(
                  width: 320,
                  child: _offerDropdownColumn(context),
                );
              }
              // Same width as "Discount by Amount" + gap + "Discount by %" above (2 of 3 columns).
              final colW = (maxW - 24) / 3;
              final offerWidth = (colW * 2 + 12).clamp(200.0, maxW);
              return SizedBox(
                width: offerWidth,
                child: _offerDropdownColumn(context),
              );
            },
          ),
        ],
        if (!_loadingOffers && _autoDayOffers.isNotEmpty) ...[
          if (_dropdownOffers.isNotEmpty) const SizedBox(height: 8) else const SizedBox(height: 8),
          Text(
            'Today\'s offer(s): ${_autoDayOffers.map((e) => '${e.name} (-$_currencyLabel ${e.discountAmount.toStringAsFixed(2)})').join('; ')}',
            style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.textColor),
          ),
        ],
      ],
    );
  }

  /// Same outer height as [CustomTextField] / amount-payable strip in this dialog (≈50).
  static const double _discountFieldVisualHeight = 50;

  Widget _offerDropdownColumn(BuildContext context) {
    final borderColor = Theme.of(context).dividerColor.withValues(alpha: 0.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Offer',
          style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.textColor),
        ),
        const SizedBox(height: 4),
        Container(
          height: _discountFieldVisualHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          alignment: Alignment.centerLeft,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: _selectedOfferIndex != null && _selectedOfferIndex! >= 0 && _selectedOfferIndex! < _dropdownOffers.length ? _selectedOfferIndex : null,
              isDense: true,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, size: 22, color: AppColors.textColor.withValues(alpha: 0.75)),
              style: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.textColor).copyWith(height: 1.15),
              hint: Text(
                'Select offer',
                style: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.hintFontColor).copyWith(height: 1.15),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('No offer'),
                ),
                for (var i = 0; i < _dropdownOffers.length; i++)
                  DropdownMenuItem<int?>(
                    value: i,
                    child: Text(
                      _offerDropdownLabel(_dropdownOffers[i]),
                      style: AppStyles.getRegularTextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) {
                setState(() {
                  _selectedOfferIndex = v;
                  _recalculateFinalAmount();
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  String _offerDropdownLabel(_AppliedOffer o) {
    final valuePart = o.type == _OfferValueType.percentage ? '${_formatOfferValue(o.value)}%' : '$_currencyLabel ${_formatOfferValue(o.value)}';
    return '${o.name} ($valuePart) — ${o.discountAmount.toStringAsFixed(2)} off';
  }

  String _formatOfferValue(double value) {
    final text = value.toStringAsFixed(2);
    return text.endsWith('.00') ? text.substring(0, text.length - 3) : text;
  }

  Widget _discountSectionTitle() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.discount_outlined, size: 18, color: AppColors.primaryColor),
        const SizedBox(width: 8),
        Text('Discount', style: AppStyles.getSemiBoldTextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _paymentFields() {
    final fields = <Widget>[
      Expanded(child: _paymentField('CASH', _cashController, _cashFocusNode)),
      const SizedBox(width: 12),
      Expanded(child: _paymentField('CARD', _cardController, _cardFocusNode)),
      const SizedBox(width: 12),
      Expanded(child: _paymentField('CREDIT', _creditController, _creditFocusNode)),
      if (widget.isDelivery && _isPartnerDelivery) ...[
        const SizedBox(width: 12),
        Expanded(child: _paymentField('ONLINE', _onlineController, _onlineFocusNode)),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: fields),
        const SizedBox(height: 6),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _showOtherPaymentField = !_showOtherPaymentField;
                  if (!_showOtherPaymentField) {
                    _otherController.clear();
                  }
                });
              },
              icon: Icon(_showOtherPaymentField ? Icons.remove : Icons.add, size: 16),
              label: Text(_showOtherPaymentField ? 'Hide Other' : 'Other'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryColor,
                side: const BorderSide(color: AppColors.primaryColor),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              ),
            ),
          ],
        ),
        if (_showOtherPaymentField) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: 180,
            child: _paymentField('OTHER', _otherController, _otherFocusNode),
          ),
        ],
      ],
    );
  }

  Widget _paymentField(String label, TextEditingController controller, FocusNode focusNode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.textColor),
        ),
        const SizedBox(height: 4),
        CustomTextField(
          controller: controller,
          focusNode: focusNode,
          labelText: '',
          keyBoardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  /* ───────── FOOTER (CLOSE + SUBMIT like image) ───────── */

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            color: Colors.black12,
            offset: Offset(0, -4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // CLOSE - light grey bg, dark blue border and text
              TextButton(
                onPressed: () async {
                  Navigator.of(context, rootNavigator: true).pop();
                  if (widget.closeSheetOnClose && widget.parentContext.mounted) {
                    await Navigator.maybePop(widget.parentContext);
                  }
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                  side: const BorderSide(color: AppColors.primaryColor, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'CLOSE',
                  style: AppStyles.getSemiBoldTextStyle(fontSize: 13, color: AppColors.primaryColor),
                ),
              ),
              const SizedBox(width: 10),
              // SUBMIT - only when amount payable is 0 (payments match). Show SnackBar on error.
              CustomButton(
                width: 110,
                text: _isSubmitting ? 'PROCESSING...' : 'SUBMIT',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        final isNormalDelivery = widget.deliveryPartner?.trim().toUpperCase() == 'NORMAL';
                        if (isNormalDelivery && _phoneController.text.trim().isEmpty) {
                          if (mounted) {
                            CustomSnackBar.showError(
                              message: 'Customer number (Contact Number) is required for Normal delivery',
                            );
                          }
                          return;
                        }
                        final creditAmt = double.tryParse(_creditController.text) ?? 0;
                        if (creditAmt > 0.005) {
                          final nameOk = _nameController.text.trim().isNotEmpty;
                          final phoneOk = _phoneController.text.trim().isNotEmpty;
                          if (!nameOk || !phoneOk) {
                            if (mounted) {
                              CustomSnackBar.showError(
                                message: 'Customer name and phone are required for credit sales.',
                              );
                            }
                            return;
                          }
                        }
                        if (!_validatePayments()) {
                          final cash = double.tryParse(_cashController.text) ?? 0;
                          final card = double.tryParse(_cardController.text) ?? 0;
                          final credit = double.tryParse(_creditController.text) ?? 0;
                          final online = double.tryParse(_onlineController.text) ?? 0;
                          final other = double.tryParse(_otherController.text) ?? 0;
                          final total = cash + card + credit + online + other;
                          final remaining = _finalAmount - total;
                          if (remaining > 0.01) {
                            if (mounted) {
                              CustomSnackBar.showError(
                                message: 'Amount payable must be 0. Add ${remaining.toStringAsFixed(2)} more.',
                              );
                            }
                          } else if (total > _finalAmount + 0.01) {
                            if (mounted) {
                              CustomSnackBar.showError(
                                message: 'Payment total (${total.toStringAsFixed(2)}) exceeds amount payable (${_finalAmount.toStringAsFixed(2)}).',
                              );
                            }
                          } else {
                            if (mounted) {
                              CustomSnackBar.showError(
                                message: 'Payment total must match amount payable.',
                              );
                            }
                          }
                          return;
                        }
                        setState(() => _isSubmitting = true);
                        try {
                          await _saveNewCustomerIfNeeded();
                          final sel = _selectedOfferIndex;
                          final applied = sel != null && sel >= 0 && sel < _dropdownOffers.length ? _dropdownOffers[sel] : null;
                          final autoDisc = _autoDayOffers.fold<double>(0, (a, o) => a + o.discountAmount);
                          final manualAmt = applied?.discountAmount ?? 0.0;
                          final totalOfferDisc = manualAmt + autoDisc;
                          final autoNamesJoined = _autoDayOffers.map((e) => e.name.trim()).where((s) => s.isNotEmpty).join(', ');
                          String offerDisplayName;
                          if (applied != null && autoDisc > 0.009) {
                            offerDisplayName = autoNamesJoined.isNotEmpty ? '${applied.name} + $autoNamesJoined' : applied.name;
                          } else if (applied != null) {
                            offerDisplayName = applied.name;
                          } else if (_autoDayOffers.length == 1) {
                            offerDisplayName = _autoDayOffers.first.name;
                          } else if (_autoDayOffers.isNotEmpty) {
                            offerDisplayName = autoNamesJoined.isNotEmpty ? autoNamesJoined : 'Day offers';
                          } else {
                            offerDisplayName = 'Offer';
                          }
                          final Map<String, dynamic>? offerPayload = totalOfferDisc < 0.005
                              ? null
                              : {
                                  'name': offerDisplayName,
                                  'uuid': applied?.uuid ?? '',
                                  'type': applied != null ? (applied.type == _OfferValueType.percentage ? 'percentage' : 'amount') : 'amount',
                                  'value': applied?.value ?? 0.0,
                                  'discountAmount': totalOfferDisc,
                                  'toDate': applied?.toDateText ?? '',
                                  'autoDayDiscount': autoDisc,
                                  if (_autoDayOffers.isNotEmpty) 'autoDayOfferNames': _autoDayOffers.map((e) => e.name).toList(),
                                };
                          await widget.onSave(
                            {
                              'name': _nameController.text,
                              'phone': _phoneController.text,
                              'email': _emailController.text,
                              'gender': _genderController.text,
                              'onlineOrderNumber': _onlineOrderNumberController.text.trim().isEmpty ? null : _onlineOrderNumberController.text.trim(),
                            },
                            {
                              'type': _manualDiscountMode,
                              'value': _manualRawValue,
                              'offer': offerPayload,
                            },
                            {
                              'cash': double.tryParse(_cashController.text) ?? 0,
                              'credit': double.tryParse(_creditController.text) ?? 0,
                              'card': double.tryParse(_cardController.text) ?? 0,
                              'online': double.tryParse(_onlineController.text) ?? 0,
                              'other': double.tryParse(_otherController.text) ?? 0,
                            },
                            printInvoice: _printInvoice,
                            printKot: _printKot,
                          );
                        } finally {
                          if (mounted) {
                            setState(() => _isSubmitting = false);
                          }
                        }
                      },
              ),
            ],
          ),
          Expanded(
            child: Center(child: _footerPrintOptions()),
          ),
        ],
      ),
    );
  }

  Widget _footerPrintOptions() {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = AppStyles.getRegularTextStyle(fontSize: 13, color: scheme.onSurface);
    return Theme(
      data: Theme.of(context).copyWith(
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primary;
            }
            return Colors.transparent;
          }),
          checkColor: WidgetStateProperty.all(scheme.onPrimary),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.7), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 32,
                width: 32,
                child: Checkbox(
                  value: _printInvoice,
                  onChanged: (v) => setState(() => _printInvoice = v ?? true),
                ),
              ),
              Text('Invoice print', style: labelStyle),
            ],
          ),
          const SizedBox(width: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 32,
                width: 32,
                child: Checkbox(
                  value: _printKot,
                  onChanged: (v) => setState(() => _printKot = v ?? true),
                ),
              ),
              Text('KOT print', style: labelStyle),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cashFocusNode.removeListener(_onPaymentFocusCash);
    _cardFocusNode.removeListener(_onPaymentFocusCard);
    _creditFocusNode.removeListener(_onPaymentFocusCredit);
    _onlineFocusNode.removeListener(_onPaymentFocusOnline);
    _otherFocusNode.removeListener(_onPaymentFocusOther);
    _cashFocusNode.dispose();
    _cardFocusNode.dispose();
    _creditFocusNode.dispose();
    _onlineFocusNode.dispose();
    _otherFocusNode.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _genderController.dispose();
    _cashController.dispose();
    _creditController.dispose();
    _cardController.dispose();
    _onlineController.dispose();
    _otherController.dispose();
    _onlineOrderNumberController.dispose();
    _discountByAmountController.dispose();
    _discountByPercentController.dispose();
    super.dispose();
  }
}

class _KotReferenceAutocompleteField extends StatefulWidget {
  const _KotReferenceAutocompleteField({
    required this.controller,
    required this.suggestions,
  });

  final TextEditingController controller;
  final List<String> suggestions;

  @override
  State<_KotReferenceAutocompleteField> createState() => _KotReferenceAutocompleteFieldState();
}

class _KotReferenceAutocompleteFieldState extends State<_KotReferenceAutocompleteField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutoCompleteTextField<String>(
      items: widget.suggestions,
      displayStringFunction: (s) => s,
      defaultText: '',
      labelText: 'Reference Number',
      filterType: FilterType.contains,
      controller: widget.controller,
      focusNode: _focusNode,
      maxHeight: MediaQuery.sizeOf(context).height / 3,
      onSelected: (s) {
        widget.controller.value = TextEditingValue(
          text: s,
          selection: TextSelection.collapsed(offset: s.length),
        );
      },
      onChanged: (_) {},
    );
  }
}

/// Kitchen order ticket (KOT) — icon + label to match Pay/Save clarity.
class _KitchenOrderIconButton extends StatelessWidget {
  const _KitchenOrderIconButton({
    required this.onPressed,
    required this.width,
  });

  final VoidCallback? onPressed;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Tooltip(
        message: 'KOT — send to kitchen',
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            disabledBackgroundColor: AppColors.primaryColor.withValues(alpha: 0.45),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: onPressed == null ? 0 : 2,
            surfaceTintColor: Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'KOT',
                style: AppStyles.getSemiBoldTextStyle(fontSize: 15, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
