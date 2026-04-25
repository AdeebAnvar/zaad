import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multi_expansion_card/multi_expansion_card.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/core/utils/dine_in_sale_navigation.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/models/pos_customer.dart';
import 'package:pos/data/repository/customer_repository.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/domain/models/customer_model.dart';
import 'package:pos/presentation/sale/cart_cubit/cart_cubit.dart';
import 'package:pos/presentation/sale/desktop/cart_preview_dialog.dart';
import 'package:pos/presentation/sale/desktop/desktop_cart_item_tile.dart';
import 'package:pos/presentation/widgets/auto_complete_textfield.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';
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

Future<void> showCartStylePaymentDialogForOrder(
  BuildContext context, {
  required Order order,
  VoidCallback? onPaymentRecorded,
}) async {
  final prefill = <String, dynamic>{
    'name': order.customerName,
    'phone': order.customerPhone,
    'email': order.customerEmail,
    'gender': order.customerGender,
    'onlineOrderNumber': order.referenceNumber,
    'cash': order.cashAmount,
    'credit': order.creditAmount,
    'card': order.cardAmount,
    'online': order.onlineAmount,
    'discountAmount': order.discountAmount,
    'discountType': order.discountType,
  };

  await showDialog<bool>(
    context: context,
    builder: (dialogContext) => PaymentDialog(
      totalAmount: order.totalAmount,
      closeSheetOnClose: false,
      parentContext: context,
      isDelivery: order.orderType == 'delivery',
      deliveryPartner: order.deliveryPartner,
      prefill: prefill,
      onSave: (customerDetails, discount, payments) async {
        final repo = locator<OrderRepository>();
        final freshOrder = await repo.getOrderById(order.id);
        if (freshOrder == null) return;

        final discountAmount = (discount['value'] as double?) ?? 0.0;
        final finalAmount = (freshOrder.totalAmount - discountAmount).clamp(0.0, double.infinity);
        final onlineOrderNumber = customerDetails['onlineOrderNumber'] as String?;
        final updatedRef = freshOrder.orderType == 'delivery' && onlineOrderNumber != null && onlineOrderNumber.isNotEmpty
            ? onlineOrderNumber
            : freshOrder.referenceNumber;

        final updatedOrder = freshOrder.copyWith(
          referenceNumber: Value(updatedRef),
          discountAmount: discountAmount,
          discountType: Value(discount['type'] as String?),
          finalAmount: finalAmount,
          customerName: Value(customerDetails['name'] as String?),
          customerEmail: Value(customerDetails['email'] as String?),
          customerPhone: Value(customerDetails['phone'] as String?),
          customerGender: Value(customerDetails['gender'] as String?),
          cashAmount: payments['cash'] ?? 0.0,
          creditAmount: payments['credit'] ?? 0.0,
          cardAmount: payments['card'] ?? 0.0,
          onlineAmount: (payments['online'] ?? 0.0) + (payments['other'] ?? 0.0),
          status: freshOrder.orderType == 'delivery' ? freshOrder.status : 'completed',
        );

        await repo.updateOrder(updatedOrder);
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
    this.onCloseCart,
    this.openPaymentOnLoad = false,
  });

  /// Optional scroll controller for use in DraggableScrollableSheet (mobile).
  final ScrollController? scrollController;
  final bool closeOnComplete;
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
                              isDelivery: cartCubit.orderType == 'delivery',
                              deliveryPartner: cartCubit.deliveryPartner,
                            );
                            onCloseCart?.call(true);
                          });
                        }
                      }
                      final isNarrow = constraints.maxWidth < 420;
                      final preferHorizontalButtons = MediaQuery.sizeOf(context).width < 1400;

                      Widget totalWidget = MediaQuery.sizeOf(context).width <= 1400
                          ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text(
                                "$itemCount item${itemCount == 1 ? '' : 's'}",
                                style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.black54),
                              ),
                              Text(
                                RuntimeAppSettings.money(totalAmount),
                                style: AppStyles.getBoldTextStyle(fontSize: 18),
                              ),
                            ])
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$itemCount item${itemCount == 1 ? '' : 's'}",
                                  style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.black54),
                                ),
                                Text(
                                  "Total payable",
                                  style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                                Text(
                                  RuntimeAppSettings.money(totalAmount),
                                  style: AppStyles.getBoldTextStyle(fontSize: 18),
                                ),
                              ],
                            );

                      Widget buttonsWidget = BlocBuilder<CartCubit, CartState>(
                        builder: (context, cartState) {
                          final cartCubit = context.read<CartCubit>();
                          final isEditingPaidOrder = cartCubit.isEditingPaidOrder;
                          final isOpenedForEdit = cartCubit.isOpenedForEdit;
                          final isDelivery = cartCubit.orderType == 'delivery';
                          final shouldSaveAsEdit = isOpenedForEdit || isEditingPaidOrder;

                          // Delivery: only Save button (no KOT, no Pay) — Save opens payment dialog
                          if (isDelivery || isEditingPaidOrder) {
                            final saveButton = CustomButton(
                              width: (isNarrow && !preferHorizontalButtons) ? constraints.maxWidth : 150,
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
                                      onCloseCart?.call(true);
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
                            if (isNarrow && !preferHorizontalButtons) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Align(alignment: Alignment.centerRight, child: eye),
                                  const SizedBox(height: 4),
                                  saveButton,
                                ],
                              );
                            }
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                eye,
                                const SizedBox(width: 4),
                                saveButton,
                              ],
                            );
                          }

                          if (!isNarrow || preferHorizontalButtons) {
                            return Row(
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
                                          final skipKotReferenceDialog = hasRef && (isOpenedForEdit || cartCubit.orderType == 'dine_in');
                                          if (skipKotReferenceDialog) {
                                            try {
                                              final printFailed = await cartCubit.saveKOTWithExistingReference();
                                              if (context.mounted) {
                                                CustomSnackBar.showKotSaved(context: context);
                                                if (printFailed.isNotEmpty) {
                                                  showPrintFailedDialog(context, printFailed);
                                                }
                                                if (closeOnComplete) {
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
                                  width: 150,
                                  onPressed: state.items.isEmpty
                                      ? () {}
                                      : () async {
                                          await _showPaymentDialog(context, totalAmount, isEditing: isOpenedForEdit);
                                          onCloseCart?.call(true);
                                        },
                                  text: "Pay",
                                ),
                              ],
                            );
                          }

                          // Narrow screens: stack buttons to avoid overflow.
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  tooltip: 'View cart',
                                  icon: Icon(
                                    Icons.visibility_outlined,
                                    color: state.items.isNotEmpty ? AppColors.primaryColor : Colors.grey,
                                  ),
                                  onPressed: state.items.isNotEmpty ? () => showCartPreviewDialog(context) : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _KitchenOrderIconButton(
                                width: constraints.maxWidth,
                                onPressed: state.items.isEmpty
                                    ? null
                                    : () async {
                                        final hasRef = cartCubit.currentKOTReference != null && cartCubit.currentKOTReference!.trim().isNotEmpty;
                                        final skipKotReferenceDialog = hasRef && (isOpenedForEdit || cartCubit.orderType == 'dine_in');
                                        if (skipKotReferenceDialog) {
                                          try {
                                            final printFailed = await cartCubit.saveKOTWithExistingReference();
                                            if (context.mounted) {
                                              CustomSnackBar.showKotSaved(context: context);
                                              if (printFailed.isNotEmpty) {
                                                showPrintFailedDialog(context, printFailed);
                                              }
                                              if (closeOnComplete) {
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
                              const SizedBox(height: 10),
                              CustomButton(
                                width: constraints.maxWidth,
                                onPressed: state.items.isEmpty
                                    ? () {}
                                    : () async {
                                        await _showPaymentDialog(context, totalAmount, isEditing: isOpenedForEdit);
                                        onCloseCart?.call(true);
                                      },
                                text: "Pay",
                              ),
                            ],
                          );
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

    showDialog(
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// Header
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentReference == null ? 'Add reference' : 'Edit reference',
                                  style: AppStyles.getBoldTextStyle(fontSize: 20),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Used for kitchen order tracking',
                                  style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// Input
                      CustomTextField(
                        controller: referenceController,
                        labelText: 'Reference Number',
                        // autoFocus: true,
                      ),

                      const SizedBox(height: 28),

                      /// Actions
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                            child: const Text('Cancel'),
                          ),
                          const Spacer(),
                          CustomButton(
                            width: 120,
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
                                if (closeOnComplete && parentContext.mounted) {
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
                  ),
                ),
              );
            },
          ),
        );
      },
    );
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
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => PaymentDialog(
        totalAmount: totalAmount,
        closeSheetOnClose: closeOnComplete,
        parentContext: context,
        isDelivery: isDelivery,
        deliveryPartner: deliveryPartner,
        prefill: prefill,
        onSave: (customerDetails, discount, payments) async {
          try {
            List<String> printFailed;
            if (isEditing) {
              printFailed = await cartCubit.updateOrderWithPayment(
                customerDetails: customerDetails,
                discount: discount,
                payments: payments,
                onlineOrderNumber: customerDetails['onlineOrderNumber'] as String?,
              );
            } else {
              printFailed = await cartCubit.placeOrderWithPayment(
                customerDetails: customerDetails,
                discount: discount,
                payments: payments,
                onlineOrderNumber: customerDetails['onlineOrderNumber'] as String?,
              );
            }

            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop(true); // ✅ return true
            }

            // Show printer warning before popping the cart sheet, so [context] stays valid.
            if (printFailed.isNotEmpty && context.mounted) {
              showPrintFailedDialog(context, printFailed);
            }

            if (context.mounted && closeOnComplete) {
              Navigator.of(context).pop(); // close sheet
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
  final bool closeSheetOnClose;
  final BuildContext parentContext;
  final bool isDelivery;
  final String? deliveryPartner;
  final Map<String, dynamic>? prefill;
  final Function(
    Map<String, dynamic> customer,
    Map<String, dynamic> discount,
    Map<String, double> payments,
  ) onSave;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
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

  final _discountAmountController = TextEditingController();
  final _discountPercentController = TextEditingController();

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

  String _discountType = 'amount';
  double _discountValue = 0;
  double _finalAmount = 0;

  final CustomerRepository _customerRepo = locator<CustomerRepository>();
  List<PosCustomer> _allCustomers = [];
  bool _loadingCustomers = true;
  bool _isSubmitting = false;
  bool _showOtherPaymentField = false;

  @override
  void initState() {
    super.initState();
    final prefill = widget.prefill;

    _finalAmount = widget.totalAmount;

    if (prefill != null) {
      _nameController.text = (prefill['name'] as String?)?.trim() ?? '';
      _phoneController.text = (prefill['phone'] as String?)?.trim() ?? '';
      _emailController.text = (prefill['email'] as String?)?.trim() ?? '';
      _genderController.text = (prefill['gender'] as String?)?.trim() ?? '';
      _onlineOrderNumberController.text = (prefill['onlineOrderNumber'] as String?)?.trim() ?? '';

      final savedDisc = (prefill['discountAmount'] as num?)?.toDouble() ?? 0.0;
      final savedDiscType = prefill['discountType'] as String?;
      if (savedDisc > 0 && savedDiscType == 'percentage') {
        _discountType = 'percentage';
        final subtotal = widget.totalAmount;
        final pct = subtotal > 0 ? (savedDisc / subtotal * 100) : 0.0;
        _discountPercentController.text = pct > 0 ? pct.toStringAsFixed(2) : savedDisc.toString();
        _discountAmountController.clear();
      } else if (savedDisc > 0) {
        _discountType = 'amount';
        _discountAmountController.text = savedDisc.toString();
        _discountPercentController.clear();
      }
    }

    _updateFinalAmount();

    // New order: [getPaymentPrefillForEdit] is null — leave payment fields empty (take away, dine in, delivery).
    // Editing: prefill cash/card/credit/online from the saved order.
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
    setState(() {
      if (_discountType == 'percentage') {
        final percent = double.tryParse(_discountPercentController.text) ?? 0;
        _discountValue = widget.totalAmount * (percent / 100);
      } else {
        _discountValue = double.tryParse(_discountAmountController.text) ?? 0;
      }
      _finalAmount = (widget.totalAmount - _discountValue).clamp(0, double.infinity);
    });
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
    final width = MediaQuery.of(context).size.width;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          width: width > 1000
              ? 720
              : width > 700
                  ? 620
                  : width * 0.96,
          constraints: const BoxConstraints(maxHeight: 560),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
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
                Expanded(child: _content()),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _currencyLabel,
                style: AppStyles.getRegularTextStyle(fontSize: 16, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                widget.totalAmount.toStringAsFixed(2),
                style: AppStyles.getBoldTextStyle(fontSize: 32, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /* ───────── CONTENT (expandable cards) ───────── */

  Widget _content() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MultipleExpansionCard(
            titles: [
              Row(
                children: [
                  Icon(Icons.person_outline, size: 20, color: AppColors.primaryColor),
                  const SizedBox(width: 10),
                  Text('Customer Details', style: AppStyles.getSemiBoldTextStyle(fontSize: 15)),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.discount_outlined, size: 20, color: AppColors.primaryColor),
                  const SizedBox(width: 10),
                  Text('Discount', style: AppStyles.getSemiBoldTextStyle(fontSize: 15)),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.payment, size: 20, color: AppColors.primaryColor),
                  const SizedBox(width: 10),
                  Text('Payment Methods', style: AppStyles.getSemiBoldTextStyle(fontSize: 15)),
                ],
              ),
            ],
            childrens: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _customerFields(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _discountFields(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _paymentFields(),
                    if (!_validatePayments() &&
                        (_cashController.text.isNotEmpty ||
                            _creditController.text.isNotEmpty ||
                            _cardController.text.isNotEmpty ||
                            _onlineController.text.isNotEmpty ||
                            _otherController.text.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Payment total must match payable amount',
                          style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.red.shade700),
                        ),
                      ),
                    SizedBox(height: 20),
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
            initialExpanded: const {2: true},
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
        const SizedBox(height: 12),
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
            contentPadding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 13,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discount by Amount',
                style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.textColor),
              ),
              const SizedBox(height: 6),
              CustomTextField(
                controller: _discountAmountController,
                labelText: '',
                keyBoardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                onTap: () {
                  _discountType = 'amount';
                  _discountPercentController.clear();
                  _updateFinalAmount();
                },
                onChanged: (_) => _updateFinalAmount(),
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
                style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.textColor),
              ),
              const SizedBox(height: 6),
              CustomTextField(
                controller: _discountPercentController,
                labelText: '',
                keyBoardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                onTap: () {
                  _discountType = 'percentage';
                  _discountAmountController.clear();
                  _updateFinalAmount();
                },
                onChanged: (_) => _updateFinalAmount(),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Amount Payable (right side, like image)
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Amount Payable',
              style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.textColor),
            ),
            const SizedBox(height: 6),
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Center(
                child: Text(
                  '$_currencyLabel ${_finalAmount.toStringAsFixed(2)}',
                  style: AppStyles.getBoldTextStyle(fontSize: 18, color: AppColors.primaryColor),
                ),
              ),
            ),
          ],
        ),
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
        const SizedBox(height: 10),
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
          const SizedBox(height: 10),
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
        const SizedBox(height: 6),
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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            color: Colors.black12,
            offset: Offset(0, -4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'CLOSE',
                  style: AppStyles.getSemiBoldTextStyle(fontSize: 14, color: AppColors.primaryColor),
                ),
              ),
              const SizedBox(width: 12),
              // SUBMIT - only when amount payable is 0 (payments match). Show SnackBar on error.
              CustomButton(
                width: 120,
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
                          await widget.onSave(
                            {
                              'name': _nameController.text,
                              'phone': _phoneController.text,
                              'email': _emailController.text,
                              'gender': _genderController.text,
                              'onlineOrderNumber': _onlineOrderNumberController.text.trim().isEmpty ? null : _onlineOrderNumberController.text.trim(),
                            },
                            {
                              'type': _discountType,
                              'value': _discountValue,
                            },
                            {
                              'cash': double.tryParse(_cashController.text) ?? 0,
                              'credit': double.tryParse(_creditController.text) ?? 0,
                              'card': double.tryParse(_cardController.text) ?? 0,
                              'online': double.tryParse(_onlineController.text) ?? 0,
                              'other': double.tryParse(_otherController.text) ?? 0,
                            },
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
    _discountAmountController.dispose();
    _discountPercentController.dispose();
    _cashController.dispose();
    _creditController.dispose();
    _cardController.dispose();
    _onlineController.dispose();
    _otherController.dispose();
    _onlineOrderNumberController.dispose();
    super.dispose();
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
