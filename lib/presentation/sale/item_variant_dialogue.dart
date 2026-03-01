import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/presentation/sale/cart_cubit/cart_cubit.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';

class ItemVariantDialog extends StatefulWidget {
  final Item item;
  final List<ItemVariant> variants;
  final List<ItemTopping> toppings;
  final BuildContext parentContext;

  const ItemVariantDialog({
    super.key,
    required this.item,
    required this.variants,
    required this.toppings,
    required this.parentContext,
  });

  @override
  State<ItemVariantDialog> createState() => _ItemVariantDialogState();
}

class _ItemVariantDialogState extends State<ItemVariantDialog> {
  /// Single variant selection; none selected by default.
  ItemVariant? selectedVariant;
  int qty = 1;

  double get unitPrice => selectedVariant?.price ?? widget.item.price;
  double get totalPrice => unitPrice * qty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(theme),
            Flexible(child: _content(theme)),
            _footer(theme),
          ],
        ),
      ),
    );
  }

  /* ───────── HEADER ───────── */

  Widget _header(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _image(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.name,
                  style: AppStyles.getBoldTextStyle(fontSize: 22),
                ),
                if (widget.item.otherName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      widget.item.otherName,
                      style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  "₹ ${unitPrice.toStringAsFixed(2)}",
                  style: AppStyles.getBoldTextStyle(fontSize: 16, color: theme.primaryColor),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          )
        ],
      ),
    );
  }

  Widget _image() {
    return Container(
      height: 90,
      width: 90,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.item.localImagePath != null && widget.item.localImagePath!.isNotEmpty
          ? Image.file(
              File(widget.item.localImagePath!),
              fit: BoxFit.cover,
            )
          : const Icon(Icons.fastfood, size: 40, color: Colors.grey),
    );
  }

  /* ───────── CONTENT ───────── */

  Widget _content(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.variants.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text("Choose Variant", style: AppStyles.getSemiBoldTextStyle(fontSize: 14)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.variants.map((v) {
                final selected = v == selectedVariant;
                return ChoiceChip(
                  backgroundColor: Colors.white,
                  checkmarkColor: selected ? Colors.white : Colors.black,
                  label: Text(v.name),
                  selected: selected,
                  selectedColor: AppColors.primaryColor,
                  surfaceTintColor: Colors.transparent,
                  side: BorderSide(
                    color: selected ? theme.primaryColor : Colors.grey.shade300,
                  ),
                  labelStyle: AppStyles.getMediumTextStyle(fontSize: 14, color: selected ? Colors.white : Colors.black87),
                  onSelected: (_) => setState(() => selectedVariant = selected ? null : v),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 28),
          Text("Quantity", style: AppStyles.getSemiBoldTextStyle(fontSize: 14)),
          const SizedBox(height: 12),
          _qtySelector(theme),
        ],
      ),
    );
  }

  /* ───────── QUANTITY ───────── */

  Widget _qtySelector(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _qtyButton(Icons.remove, qty > 1 ? () => setState(() => qty--) : null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "$qty",
            style: AppStyles.getBoldTextStyle(fontSize: 22),
          ),
        ),
        _qtyButton(Icons.add, () => setState(() => qty++)),
      ],
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: onTap == null ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon),
      ),
    );
  }

  /* ───────── FOOTER ───────── */

  Widget _footer(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Text(
            "₹ ${totalPrice.toStringAsFixed(2)}",
            style: AppStyles.getBoldTextStyle(fontSize: 16),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          const SizedBox(width: 8),
          Opacity(
            opacity: _canAddToCart ? 1 : 0.5,
            child: CustomButton(
              width: 150,
              onPressed: _canAddToCart ? _onAddToCart : () {},
              text: "Add to Cart",
            ),
          ),
        ],
      ),
    );
  }

  /* ───────── ACTION ───────── */

  bool get _canAddToCart => widget.variants.isEmpty ? qty > 0 : selectedVariant != null && qty > 0;

  void _onAddToCart() {
    final cartCubit = widget.parentContext.read<CartCubit>();
    cartCubit.addItemToCart(widget.item, selectedVariant: selectedVariant, quantity: qty);
    Navigator.pop(context);
    _showAddToCartConfirmation(widget.parentContext);
  }

  void _showAddToCartConfirmation(BuildContext context) {
    CustomSnackBar.showAddedToCart(context: context);
  }
}
