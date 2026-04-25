import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/presentation/sale/cart_cubit/cart_cubit.dart';
import 'package:pos/presentation/sale/qty_button.dart';
import 'package:pos/presentation/sale/topping_dialogue.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';

class CartItemTile extends StatelessWidget {
  final int cartItemId;
  const CartItemTile({super.key, required this.cartItemId});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CartCubit, CartState, CartItem?>(
      selector: (state) {
        for (final e in state.items) {
          if (e.id == cartItemId) return e;
        }
        return null;
      },
      builder: (context, cartItem) {
        if (cartItem == null) return const SizedBox.shrink();
        return _CartItemContent(cartItem: cartItem);
      },
    );
  }
}

class _CartItemContent extends StatefulWidget {
  final CartItem cartItem;

  const _CartItemContent({
    required this.cartItem,
  });

  @override
  State<_CartItemContent> createState() => _CartItemContentState();
}

class _CartItemContentState extends State<_CartItemContent> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Item? _item;
  ItemVariant? _variant;
  List<Map<String, dynamic>>? _toppings; // All toppings from JSON
  bool _isLoading = true;
  bool _isEditingUnitPrice = false;
  late TextEditingController _unitPriceController;
  late final FocusNode _unitPriceFocusNode;

  @override
  void initState() {
    super.initState();
    _unitPriceController = TextEditingController();
    _unitPriceFocusNode = FocusNode();
    _unitPriceFocusNode.addListener(_onUnitPriceFocusChange);
    _loadItemData();
  }

  void _onUnitPriceFocusChange() {
    if (!_unitPriceFocusNode.hasFocus && _isEditingUnitPrice) {
      _commitUnitPriceEdit();
    }
  }

  Future<void> _commitUnitPriceEdit() async {
    if (!mounted || !_isEditingUnitPrice) return;
    final cartCubit = context.read<CartCubit>();
    final parsed = double.tryParse(_unitPriceController.text.trim());
    if (parsed != null && parsed >= 0) {
      await cartCubit.updateUnitPrice(widget.cartItem.id, parsed);
    }
    if (mounted) {
      setState(() => _isEditingUnitPrice = false);
    }
  }

  @override
  void didUpdateWidget(_CartItemContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload when cart line identity or line payload tied to item metadata changes.
    if (oldWidget.cartItem.id != widget.cartItem.id ||
        oldWidget.cartItem.itemId != widget.cartItem.itemId ||
        oldWidget.cartItem.itemVariantId != widget.cartItem.itemVariantId ||
        oldWidget.cartItem.itemToppingId != widget.cartItem.itemToppingId ||
        oldWidget.cartItem.notes != widget.cartItem.notes) {
      // Only clear cached product when switching to a different catalog item (avoids full-row spinner flash on other updates).
      if (oldWidget.cartItem.itemId != widget.cartItem.itemId) {
        _item = null;
        _variant = null;
        _toppings = null;
      }
      _loadItemData();
    }
  }

  @override
  void dispose() {
    _unitPriceFocusNode.removeListener(_onUnitPriceFocusChange);
    _unitPriceFocusNode.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  Future<void> _loadItemData() async {
    final needsFullSpinner = _item == null;
    if (needsFullSpinner && mounted) {
      setState(() => _isLoading = true);
    }
    final itemRepo = locator<ItemRepository>();

    final item = await itemRepo.fetchItemByIdFromLocal(widget.cartItem.itemId);
    if (item == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    super.build(context);
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
      key: ValueKey('swipe_cart_${widget.cartItem.id}'),
      direction: DismissDirection.horizontal,
      // null = skip resize phase; Duration.zero still runs resize animation and can assert
      // "dismissed Dismissible is still part of the tree" before Bloc removes the row.
      resizeDuration: null,
      movementDuration: const Duration(milliseconds: 200),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (context.mounted) {
            await _showLineNotesDialog(context, widget.cartItem);
          }
          return false;
        }
        if (isNewlyAdded) {
          return true;
        }
        return await _showDeleteDialog(context);
      },
      onDismissed: (_) {
        if (!mounted) return;
        context.read<CartCubit>().removeItemByCartItemId(widget.cartItem.id);
      },
      // Right → left: delete (revealed behind row when swiping toward the left).
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.primaryColor.withValues(alpha: 0.5),
          border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.35)),
        ),
        child: Icon(Icons.sticky_note_2_outlined, color: AppColors.primaryColor),
      ),
      // Left → right: notes (revealed when swiping toward the right).
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 10),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.danger.withValues(alpha: 0.5),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
        ),
        child: Icon(Icons.delete_outline, color: AppColors.danger),
      ),
      child: RepaintBoundary(
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Builder(
            builder: (context) {
              double toppingsTotal = 0;
              if (_toppings != null && _toppings!.isNotEmpty) {
                for (var topping in _toppings!) {
                  final price = (topping['price'] ?? 0.0) as double;
                  final qty = (topping['qty'] ?? 1) as int;
                  toppingsTotal += price * qty;
                }
              }

              Widget unitWidget;
              if (_isEditingUnitPrice) {
                unitWidget = SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _unitPriceController,
                    focusNode: _unitPriceFocusNode,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.black87),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _commitUnitPriceEdit(),
                  ),
                );
              } else {
                unitWidget = GestureDetector(
                  onTap: () {
                    setState(() {
                      _isEditingUnitPrice = true;
                      _unitPriceController.text = unitPrice.toStringAsFixed(2);
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Unit: ${unitPrice.toStringAsFixed(2)}",
                        style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit, size: 12, color: Colors.grey.shade500),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: item + variant + unit/total
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _item!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppStyles.getSemiBoldTextStyle(fontSize: 15),
                            ),
                            if (_variant != null)
                              Text(
                                "(${_variant!.name})",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                unitWidget,
                                const SizedBox(width: 12),
                                Text(
                                  "Total: ${widget.cartItem.total.toStringAsFixed(2)}",
                                  style: AppStyles.getBoldTextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Right: delete
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                            icon: const Icon(Icons.delete_outline, size: 19),
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
                  if (widget.cartItem.discount > 0 || toppingsTotal > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (toppingsTotal > 0)
                          Text(
                            "Toppings: +${RuntimeAppSettings.money(toppingsTotal)}",
                            style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        if (toppingsTotal > 0 && widget.cartItem.discount > 0) const SizedBox(width: 12),
                        if (widget.cartItem.discount > 0)
                          Text(
                            "Disc: -${RuntimeAppSettings.money(widget.cartItem.discount)}",
                            style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.red.shade700),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  // Bottom: action buttons on left, qty controls on right
                  Row(
                    children: [
                      IconButton(
                        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                        icon: const Icon(Icons.percent, size: 18),
                        onPressed: () => showDiscountDialog(context, widget.cartItem),
                      ),
                      IconButton(
                        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                        tooltip: 'Line notes',
                        icon: Icon(
                          Icons.sticky_note_2_outlined,
                          size: 18,
                          color: _cartItemHasPlainNotes(widget.cartItem) ? AppColors.primaryColor : null,
                        ),
                        onPressed: () => _showLineNotesDialog(context, widget.cartItem),
                      ),
                      IconButton(
                        visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                        icon: const Icon(Icons.restaurant_menu, size: 18),
                        onPressed: () => _showToppingDialog(context, widget.cartItem),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
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
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "${widget.cartItem.quantity}",
                              style: AppStyles.getSemiBoldTextStyle(fontSize: 15),
                            ),
                          ),
                          QtyButton(
                            icon: Icons.add,
                            onTap: () => context.read<CartCubit>().increaseQtyByCartItemId(widget.cartItem.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
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
                    obscureText: true,
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
                            final expected = RuntimeAppSettings.qtyReducePassword;
                            if (expected.isNotEmpty && refController.text.trim() != expected) {
                              CustomSnackBar.showError(message: 'Invalid qty password');
                              return;
                            }
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
    bool obscureText = false,
  }) {
    return CustomTextField(
      controller: controller,
      labelText: label,
      obscureText: obscureText,
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

  /// Plain-text line notes (not toppings JSON in `notes`).
  String _initialLineNotesPlain(CartItem cartItem) {
    final n = cartItem.notes;
    if (n == null || n.isEmpty) return '';
    if (n.trimLeft().startsWith('[')) return '';
    return n;
  }

  bool _cartItemHasPlainNotes(CartItem cartItem) {
    return _initialLineNotesPlain(cartItem).trim().isNotEmpty;
  }

  Future<void> _showLineNotesDialog(BuildContext context, CartItem cartItem) async {
    final cartCubit = context.read<CartCubit>();
    final hasToppings = cartCubit.getToppingsFromCartItem(cartItem)?.isNotEmpty == true;
    final controller = TextEditingController(text: _initialLineNotesPlain(cartItem));
    final notesFocusNode = FocusNode();

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return BlocProvider.value(
            value: cartCubit,
            child: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                final width = MediaQuery.of(context).size.width;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (notesFocusNode.canRequestFocus && !notesFocusNode.hasFocus) {
                    notesFocusNode.requestFocus();
                  }
                });
                return Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: width > 600 ? 480 : width * 0.95,
                    ),
                    child: Material(
                      color: Colors.white,
                      elevation: theme.dialogTheme.elevation ?? 8,
                      shadowColor: theme.shadowColor.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: AppColors.divider),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.sticky_note_2_outlined, color: AppColors.primaryColor, size: 26),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Line notes',
                                    style: AppStyles.getBoldTextStyle(fontSize: 20, color: AppColors.textColor),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: AppColors.textColor),
                                  onPressed: () => Navigator.pop(dialogContext),
                                ),
                              ],
                            ),
                            if (hasToppings) ...[
                              const SizedBox(height: 8),
                              Text(
                                'This line has toppings. Clear toppings before saving notes here, or topping data may be overwritten.',
                                style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.orange.shade900),
                              ),
                            ],
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: controller,
                              focusNode: notesFocusNode,
                              labelText: 'Notes',
                              maxLines: 4,
                              enabled: !hasToppings,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    text: 'Save',
                                    onPressed: hasToppings
                                        ? null
                                        : () async {
                                            CartItem? current;
                                            for (final e in cartCubit.state.items) {
                                              if (e.id == cartItem.id) {
                                                current = e;
                                                break;
                                              }
                                            }
                                            if (current == null) {
                                              if (context.mounted) Navigator.pop(dialogContext);
                                              return;
                                            }
                                            await cartCubit.updateCartItemLineNotes(current, controller.text);
                                            if (context.mounted) Navigator.pop(dialogContext);
                                          },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ),
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
    } finally {
      notesFocusNode.dispose();
      controller.dispose();
    }
  }

  void showDiscountDialog(BuildContext context, CartItem cartItem) {
    final cartCubit = context.read<CartCubit>();

    final amountController = TextEditingController(
      text: cartItem.discountType == 'amount' && cartItem.discount > 0 ? cartItem.discount.toStringAsFixed(2) : '',
    );

    final percentController = TextEditingController(
      text: cartItem.discountType == 'percentage' && cartItem.discount > 0 ? ((cartItem.discount / (cartItem.total + cartItem.discount)) * 100).toStringAsFixed(2) : '',
    );

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
                                  label: '${RuntimeAppSettings.currency} Amount',
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

                          const SizedBox(height: 28),

                          /// Actions
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: 'Apply',
                                  onPressed: () {
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
