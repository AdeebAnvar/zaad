import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/presentation/sale/cart_cubit/cart_cubit.dart';
import 'package:pos/presentation/sale/cart_item_image.dart';
import 'package:pos/presentation/sale/qty_button.dart';
import 'package:pos/presentation/sale/topping_dialogue.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';

class CartItemTile extends StatelessWidget {
  final CartItem cartItem;
  final int index;
  const CartItemTile({super.key, required this.cartItem, required this.index});

  @override
  Widget build(BuildContext context) {
    return _CartItemContent(cartItem: cartItem, index: index);
  }
}

class _CartItemContent extends StatefulWidget {
  final CartItem cartItem;
  final int index;

  const _CartItemContent({
    required this.cartItem,
    required this.index,
  });

  @override
  State<_CartItemContent> createState() => _CartItemContentState();
}

class _CartItemContentState extends State<_CartItemContent> {
  Item? _item;
  ItemVariant? _variant;
  List<Map<String, dynamic>>? _toppings; // All toppings from JSON
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItemData();
  }

  @override
  void didUpdateWidget(_CartItemContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Always reload if cart item ID changed (different cart item) or item details changed
    if (oldWidget.cartItem.id != widget.cartItem.id ||
        oldWidget.cartItem.itemId != widget.cartItem.itemId ||
        oldWidget.cartItem.itemVariantId != widget.cartItem.itemVariantId ||
        oldWidget.cartItem.itemToppingId != widget.cartItem.itemToppingId ||
        oldWidget.cartItem.notes != widget.cartItem.notes) {
      // Reset state when switching to a different cart item
      _item = null;
      _variant = null;
      _toppings = null;
      _isLoading = true;
      _loadItemData();
    }
  }

  Future<void> _loadItemData() async {
    setState(() => _isLoading = true);
    final itemRepo = locator<ItemRepository>();

    final item = await itemRepo.fetchItemByIdFromLocal(widget.cartItem.itemId);
    if (item == null) {
      setState(() => _isLoading = false);
      return;
    }

    ItemVariant? variant;
    if (widget.cartItem.itemVariantId != null) {
      variant = await itemRepo.fetchVariantById(widget.cartItem.itemVariantId!);
    }

    // Parse toppings from JSON in notes field
    final cartCubit = context.read<CartCubit>();
    final toppingsData = cartCubit.getToppingsFromCartItem(widget.cartItem);

    if (mounted) {
      setState(() {
        _item = item;
        _variant = variant;
        _toppings = toppingsData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _item == null) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Always derive unit price from cart data so manual edits are reflected. effective unit = (total + discount) / quantity.
    final double unitPrice = (widget.cartItem.total + widget.cartItem.discount) / widget.cartItem.quantity;

    final cartCubit = context.read<CartCubit>();
    final isNewlyAdded = cartCubit.isNewlyAddedCartItem(widget.cartItem.id);

    return Dismissible(
      key: ValueKey(widget.cartItem.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        if (isNewlyAdded) return true;
        final isDeleted = await _showDeleteDialog(context);
        return isDeleted; // true = dismiss, false = cancel
      },
      onDismissed: (_) async {
        context.read<CartCubit>().removeItemByCartItemId(widget.cartItem.id);
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE
            CartItemImage(path: _item!.localImagePath),

            const SizedBox(width: 10),

            // DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _item!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.getSemiBoldTextStyle(fontSize: 14),
                  ),
                  if (_variant != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        "Variant: ${_variant!.name}",
                        style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  if (widget.cartItem.itemVariantId != null && _variant == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        "Variant (₹ ${(widget.cartItem.total + widget.cartItem.discount).toStringAsFixed(2)} total)",
                        style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  Text(
                    "SKU: ${_item!.sku}",
                    style: AppStyles.getRegularTextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  if (_toppings != null && _toppings!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _toppings!.map((topping) {
                          final name = topping['name'] ?? '';
                          final price = topping['price'] ?? 0.0;
                          final qty = topping['qty'] ?? 1;
                          return Text(
                            "Topping: $name × $qty (₹${(price * qty).toStringAsFixed(2)})",
                            style: AppStyles.getRegularTextStyle(fontSize: 11, color: Colors.blue),
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 6),

                  // Price breakdown
                  Builder(
                    builder: (context) {
                      // Calculate toppings total
                      double toppingsTotal = 0;
                      if (_toppings != null && _toppings!.isNotEmpty) {
                        for (var topping in _toppings!) {
                          final price = (topping['price'] ?? 0.0) as double;
                          final qty = (topping['qty'] ?? 1) as int;
                          toppingsTotal += price * qty;
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product amount
                          Row(
                            children: [
                              Text(
                                "Product: ₹${(unitPrice * widget.cartItem.quantity).toStringAsFixed(2)}",
                                style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              if (toppingsTotal > 0) ...[
                                const SizedBox(width: 8),
                                Text(
                                  "Toppings: ₹${(toppingsTotal * widget.cartItem.quantity).toStringAsFixed(2)}",
                                  style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.blue),
                                ),
                              ],
                            ],
                          ),
                          // Subtotal and discount
                          if (widget.cartItem.discount > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  Text(
                                    "Subtotal: ₹${((unitPrice + toppingsTotal) * widget.cartItem.quantity).toStringAsFixed(2)}",
                                    style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Disc: -₹${widget.cartItem.discount.toStringAsFixed(2)}",
                                    style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 4),
                          // Unit price (editable) and total for this variant
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _showUnitPriceEditDialog(context, (widget.cartItem.total + widget.cartItem.discount) / widget.cartItem.quantity),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Unit: ₹${unitPrice.toStringAsFixed(2)} × ${widget.cartItem.quantity}${toppingsTotal > 0 ? ' + toppings' : ''}",
                                      style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.edit, size: 12, color: Colors.grey.shade500),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "Total: ₹ ${widget.cartItem.total.toStringAsFixed(2)}",
                                style: AppStyles.getBoldTextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 6),

                  // ACTION ROW
                  Row(
                    children: [
                      QtyButton(
                        icon: Icons.remove,
                        onTap: () async {
                          if (isNewlyAdded) {
                            context.read<CartCubit>().decreaseQtyByCartItemId(widget.cartItem.id);
                          } else {
                            final proceed = await _showDeleteDialog(context);
                            if (proceed && context.mounted) {
                              context.read<CartCubit>().decreaseQtyByCartItemId(widget.cartItem.id);
                            }
                          }
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          "${widget.cartItem.quantity}",
                          style: AppStyles.getRegularTextStyle(fontSize: 16),
                        ),
                      ),
                      QtyButton(
                        icon: Icons.add,
                        onTap: () => context.read<CartCubit>().increaseQtyByCartItemId(widget.cartItem.id),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.percent, size: 18),
                        onPressed: () => showDiscountDialog(context, widget.cartItem),
                      ),
                      IconButton(
                        icon: const Icon(Icons.restaurant_menu, size: 18),
                        onPressed: () => _showToppingDialog(context, widget.cartItem),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        onPressed: () async {
                          if (isNewlyAdded) {
                            context.read<CartCubit>().removeItemByCartItemId(widget.cartItem.id);
                          } else {
                            final isDeleted = await _showDeleteDialog(context);
                            if (isDeleted && context.mounted) {
                              context.read<CartCubit>().removeItemByCartItemId(widget.cartItem.id);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteDialog(BuildContext context) async {
    final reasonController = TextEditingController();
    final refController = TextEditingController();
    bool isDeleted = false;
    await showGeneralDialog(
      context: context,
      barrierLabel: "Delete Dialog",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _title(),
                  const SizedBox(height: 16),
                  _textField(
                    controller: reasonController,
                    label: "Reason",
                  ),
                  const SizedBox(height: 12),
                  _textField(
                    controller: refController,
                    label: "Password",
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          backgroundColor: AppColors.danger,
                          onPressed: () {
                            Navigator.pop(context);
                            isDeleted = true;
                          },
                          text: "Delete",
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
            ),
            child: child,
          ),
        );
      },
    );
    return isDeleted;
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
  }) {
    return CustomTextField(
      controller: controller,
      labelText: label,
    );
  }

  Widget _title() {
    return Column(
      children: [
        const Icon(Icons.delete_outline, color: Colors.red, size: 32),
        const SizedBox(height: 8),
        Text(
          "Delete Item",
          style: AppStyles.getBoldTextStyle(fontSize: 18),
        ),
      ],
    );
  }

  void _showToppingDialog(BuildContext context, CartItem cartItem) async {
    final itemRepo = locator<ItemRepository>();

    // Fetch the item and toppings
    final item = await itemRepo.fetchItemByIdFromLocal(cartItem.itemId);
    if (item == null) return;

    final availableToppings = await itemRepo.fetchToppingsByItem(cartItem.itemId);

    // Fetch variant if exists
    ItemVariant? variant;
    if (cartItem.itemVariantId != null && cartItem.itemVariantId! > 0) {
      final variants = await itemRepo.fetchVariantsByItem(cartItem.itemId);
      if (variants.isNotEmpty) {
        variant = variants.firstWhere(
          (v) => v.id == cartItem.itemVariantId,
          orElse: () => variants.first,
        );
      }
    }

    // Parse existing toppings from cart item notes
    final cartCubit = context.read<CartCubit>();
    final existingToppingsData = cartCubit.getToppingsFromCartItem(cartItem);
    Map<ItemTopping, int>? initialSelectedToppings;

    if (existingToppingsData != null && existingToppingsData.isNotEmpty) {
      initialSelectedToppings = {};
      for (var toppingData in existingToppingsData) {
        final toppingId = toppingData['id'] as int?;
        final toppingQty = toppingData['qty'] as int? ?? 0;

        if (toppingId != null && toppingQty > 0) {
          // Find matching topping from available toppings
          final topping = availableToppings.firstWhere(
            (t) => t.id == toppingId,
            orElse: () => throw StateError('Topping not found'),
          );
          initialSelectedToppings[topping] = toppingQty;
        }
      }
    }

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => BlocProvider.value(
          value: cartCubit,
          child: ToppingsDialog(
            item: item,
            variant: variant,
            qty: cartItem.quantity,
            toppings: availableToppings,
            cartCubit: cartCubit,
            initialSelectedToppings: initialSelectedToppings,
            cartItemId: cartItem.id,
          ),
        ),
      );
    }
  }

  void _showUnitPriceEditDialog(BuildContext context, double currentUnitPrice) {
    final controller = TextEditingController(text: currentUnitPrice.toStringAsFixed(2));
    final cartCubit = context.read<CartCubit>();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Unit Price'),
          content: CustomTextField(
            controller: controller,
            labelText: 'Unit price (₹)',
            keyBoardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            CustomButton(
              text: 'Save',
              onPressed: () async {
                final value = double.tryParse(controller.text);
                if (value != null && value >= 0) {
                  await cartCubit.updateUnitPrice(widget.cartItem.id, value);
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
            ),
          ],
        );
      },
    );
  }

  void showDiscountDialog(BuildContext context, CartItem cartItem) {
    final cartCubit = context.read<CartCubit>();

    final amountController = TextEditingController(
      text: cartItem.discountType == 'amount' && cartItem.discount > 0 ? cartItem.discount.toStringAsFixed(2) : '',
    );

    final percentController = TextEditingController(
      text: cartItem.discountType == 'percentage' && cartItem.discount > 0 ? ((cartItem.discount / (cartItem.total + cartItem.discount)) * 100).toStringAsFixed(2) : '',
    );

    final notesController = TextEditingController(text: cartItem.notes ?? '');

    String discountType = cartItem.discountType ?? 'amount';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return BlocProvider.value(
          value: cartCubit,
          child: StatefulBuilder(
            builder: (context, setState) {
              final width = MediaQuery.of(context).size.width;

              return Dialog(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: width > 600 ? 480 : width * 0.95,
                  ),
                  child: Container(
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
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
                              Text(
                                'Apply Discount',
                                style: AppStyles.getBoldTextStyle(fontSize: 20),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => Navigator.pop(context),
                              )
                            ],
                          ),

                          const SizedBox(height: 16),

                          /// Segmented Control
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                _DiscountSegment(
                                  label: '₹ Amount',
                                  selected: discountType == 'amount',
                                  onTap: () {
                                    setState(() {
                                      discountType = 'amount';
                                      percentController.clear();
                                    });
                                  },
                                ),
                                _DiscountSegment(
                                  label: '% Percentage',
                                  selected: discountType == 'percentage',
                                  onTap: () {
                                    setState(() {
                                      discountType = 'percentage';
                                      amountController.clear();
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// Input (Animated)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: discountType == 'amount'
                                ? CustomTextField(
                                    key: const ValueKey('amount'),
                                    controller: amountController,
                                    labelText: 'Discount Amount',
                                    keyBoardType: const TextInputType.numberWithOptions(decimal: true),
                                  )
                                : CustomTextField(
                                    key: const ValueKey('percentage'),
                                    controller: percentController,
                                    labelText: 'Discount Percentage',
                                    keyBoardType: const TextInputType.numberWithOptions(decimal: true),
                                  ),
                          ),

                          const SizedBox(height: 16),

                          /// Notes
                          CustomTextField(
                            controller: notesController,
                            labelText: 'Notes (optional)',
                            maxLines: 3,
                          ),

                          const SizedBox(height: 28),

                          /// Actions
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: 'Apply',
                                  onPressed: () {
                                    final notes = notesController.text.trim();
                                    double value = 0;

                                    if (discountType == 'amount') {
                                      value = double.tryParse(amountController.text) ?? 0;
                                    } else {
                                      value = double.tryParse(percentController.text) ?? 0;
                                    }

                                    cartCubit.applyDiscount(
                                      cartItem,
                                      value > 0 ? value : 0,
                                      discountType == 'percentage',
                                      notes: notes.isEmpty ? null : notes,
                                    );

                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                              if (cartItem.discount > 0) ...[
                                const SizedBox(width: 12),
                                TextButton(
                                  onPressed: () {
                                    cartCubit.applyDiscount(cartItem, 0, false, notes: null);
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'Remove',
                                    style: AppStyles.getRegularTextStyle(fontSize: 14, color: Colors.red),
                                  ),
                                ),
                              ],
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _DiscountSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DiscountSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? Theme.of(context).primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              label,
              style: AppStyles.getSemiBoldTextStyle(fontSize: 14, color: selected ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }
}
