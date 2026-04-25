import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/presentation/sale/cart_cubit/cart_cubit.dart';

class ToppingsDialog extends StatefulWidget {
  final Item item;
  final ItemVariant? variant;
  final int qty;
  final List<ItemTopping> toppings;
  final CartCubit? cartCubit; // Optional - can be passed or accessed via context
  final Map<ItemTopping, int>? initialSelectedToppings; // Pre-fill existing selections
  final int? cartItemId; // If updating existing cart item

  const ToppingsDialog({
    required this.item,
    required this.variant,
    required this.qty,
    required this.toppings,
    this.cartCubit,
    this.initialSelectedToppings,
    this.cartItemId,
  });

  @override
  State<ToppingsDialog> createState() => _ToppingsDialogState();
}

class _ToppingsDialogState extends State<ToppingsDialog> {
  late Map<ItemTopping, int> selected;
  ItemTopping? hoveredTopping;

  @override
  void initState() {
    super.initState();
    selected = widget.initialSelectedToppings?.map((k, v) => MapEntry(k, v)) ?? {};
  }

  double get unitBasePrice => widget.variant?.price ?? widget.item.price;

  double get total {
    double sum = unitBasePrice;
    selected.forEach((t, q) => sum += t.price * q);
    return sum * widget.qty;
  }

  /* ───────────────── DIALOG ───────────────── */

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(18),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: size.width > 900
              ? 600
              : size.width > 600
                  ? 500
                  : size.width * 0.95,
          constraints: const BoxConstraints(maxHeight: 650),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(
                blurRadius: 35,
                color: Colors.black26,
              )
            ],
          ),
          child: Column(
            children: [
              _header(theme),
              const Divider(height: 1),
              Expanded(child: _content()),
              _footer(theme),
            ],
          ),
        ),
      ),
    );
  }

  /* ───────────────── HEADER ───────────────── */

  Widget _header(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 22, 18, 16),
      child: Row(
        children: [
          const Icon(Icons.tapas, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Customize Toppings",
                  style: AppStyles.getBoldTextStyle(fontSize: 22),
                ),
                Text(
                  widget.item.name,
                  style: AppStyles.getRegularTextStyle(fontSize: 14, color: Colors.grey.shade600),
                )
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  /* ───────────────── CONTENT ───────────────── */

  Widget _content() {
    if (widget.toppings.isEmpty) {
      return Center(child: Text("No toppings available", style: AppStyles.getRegularTextStyle(fontSize: 14, color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: widget.toppings.length,
      itemBuilder: (_, index) {
        final topping = widget.toppings[index];
        final qty = selected[topping] ?? 0;

        return MouseRegion(
          onEnter: (_) => setState(() => hoveredTopping = topping),
          onExit: (_) => setState(() => hoveredTopping = null),
          child: _toppingCard(topping, qty),
        );
      },
    );
  }

  /* ───────────────── TOPPING CARD ───────────────── */

  Widget _toppingCard(ItemTopping topping, int qty) {
    final bool isSelected = qty > 0;
    final bool isHovered = hoveredTopping == topping;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primaryColor.withOpacity(0.85)
            : isHovered
                ? Colors.grey.shade100
                : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? AppColors.primaryColor : Colors.grey.shade300,
        ),
        boxShadow: isHovered
            ? const [
                BoxShadow(
                  blurRadius: 10,
                  color: Colors.black12,
                )
              ]
            : [],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  topping.name,
                  style: AppStyles.getSemiBoldTextStyle(fontSize: 16, color: isSelected ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 6),
                Text(
                  RuntimeAppSettings.money(topping.price),
                  style: AppStyles.getRegularTextStyle(fontSize: 14, color: isSelected ? Colors.white70 : Colors.grey.shade700),
                )
              ],
            ),
          ),
          _stepper(topping, qty),
        ],
      ),
    );
  }

  /* ───────────────── STEPPER ───────────────── */

  Widget _stepper(ItemTopping topping, int qty) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          _stepperButton(
            icon: Icons.remove,
            enabled: qty > 0,
            onTap: () {
              setState(() {
                if (qty <= 1) {
                  selected.remove(topping);
                } else {
                  selected[topping] = qty - 1;
                }
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "$qty",
              style: AppStyles.getBoldTextStyle(fontSize: 17),
            ),
          ),
          _stepperButton(
            icon: Icons.add,
            enabled: qty < topping.maxQty,
            onTap: () => setState(() {
              selected[topping] = qty + 1;
            }),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 20,
          color: enabled ? Colors.black : Colors.grey,
        ),
      ),
    );
  }

  /* ───────────────── FOOTER ───────────────── */

  Widget _footer(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 14,
            color: Colors.black12,
            offset: Offset(0, -4),
          )
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Total",
                style: AppStyles.getRegularTextStyle(fontSize: 14, color: Colors.grey),
              ),
              Text(
                RuntimeAppSettings.money(total),
                style: AppStyles.getBoldTextStyle(fontSize: 22),
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: AppStyles.getMediumTextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              widget.cartItemId != null ? "Update Item" : "Add To Cart",
              style: AppStyles.getMediumTextStyle(fontSize: 13, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }

  void _onSave() {
    // Try to get CartCubit from passed parameter or context
    CartCubit? cubit = widget.cartCubit;
    if (cubit == null) {
      try {
        cubit = context.read<CartCubit>();
      } catch (e) {
        // If not available in context, try to get from navigator context
        final navigatorContext = Navigator.of(context, rootNavigator: true).context;
        if (navigatorContext.mounted) {
          try {
            cubit = navigatorContext.read<CartCubit>();
          } catch (_) {
            // If still not found, return without saving
            Navigator.pop(context);
            return;
          }
        } else {
          Navigator.pop(context);
          return;
        }
      }
    }

    // If updating existing cart item, use updateCartItemToppings
    if (widget.cartItemId != null) {
      cubit.updateCartItemToppings(widget.cartItemId!, selected);
    } else {
      // Adding new item with toppings
      cubit.addItemWithVariantAndToppings(
        widget.item,
        widget.variant,
        widget.qty,
        selected,
      );
    }
    Navigator.pop(context);
  }
}
