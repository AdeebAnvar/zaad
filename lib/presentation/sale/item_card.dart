import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/presentation/sale/cart_cubit/cart_cubit.dart';
import 'package:pos/presentation/sale/item_cubit.dart/items_cubit.dart';
import 'package:pos/presentation/sale/item_variant_dialogue.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';

class ItemCard extends StatelessWidget {
  final Item item;

  const ItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final hasImage = item.localImagePath != null && item.localImagePath!.isNotEmpty && File(item.localImagePath!).existsSync();
    final hasVariants = context.select<ItemsCubit, bool>((cubit) {
      final state = cubit.state;
      if (state is ItemsLoadedState) {
        return state.variantItemIds.contains(item.id);
      }
      return false;
    });

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final cartCubit = context.read<CartCubit>();
        final itemsCubit = context.read<ItemsCubit>();

        final variants = await itemsCubit.getVariants(item.id);
        final toppings = await itemsCubit.getToppings(item.id);
        log('''${item.name} Toppings  ${toppings.map((e) => e.toJson())} Variants ${variants.map((e) => e.toJson())}''');

        // If item has variants, show variant dialog
        if (variants.isNotEmpty) {
          showItemConfigDialog(
            context,
            item: item,
            variants: variants,
            toppings: toppings,
          );
        } else {
          // Check if item already exists in cart (without variant or topping)
          final existingCartItem = cartCubit.state.items.firstWhere(
            (cartItem) => cartItem.itemId == item.id && cartItem.itemVariantId == null && cartItem.itemToppingId == null,
            orElse: () => CartItem(
              id: -1, // Not found marker
              cartId: 0,
              itemId: 0,
              quantity: 0,
              total: 0,
              discount: 0,
            ),
          );

          // If item exists in cart, increase quantity
          if (existingCartItem.id != -1) {
            await cartCubit.increaseQtyByCartItemId(existingCartItem.id);
          } else {
            // If item doesn't exist, add to cart
            cartCubit.addItemToCart(item);
          }
          if (context.mounted) CustomSnackBar.showAddedToCart(context: context);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // 🔹 IMAGE
              Positioned.fill(
                child: hasImage
                    ? Image.file(
                        File(item.localImagePath!),
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: Icon(
                            Icons.fastfood,
                            size: 40,
                            color: Colors.black38,
                          ),
                        ),
                      ),
              ),

              // 🔹 STOCK BADGE (only when server enables stock tracking)
              if (item.stockEnabled && RuntimeAppSettings.stockShowEnabled)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.stock > 0 ? AppColors.primaryColor.withOpacity(0.85) : Colors.red.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.stock > 0 ? "${item.stock}" : "Out of stock",
                      style: AppStyles.getSemiBoldTextStyle(fontSize: 11, color: Colors.white),
                    ),
                  ),
                ),

              // 🔹 BOTTOM INFO PANEL
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.14),
                        Colors.black.withOpacity(0.75),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.getSemiBoldTextStyle(fontSize: 14, color: Colors.white),
                      ),
                      if (item.otherName.isNotEmpty)
                        Text(
                          item.otherName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.getRegularTextStyle(fontSize: 11, color: Colors.white70),
                        ),
                      const SizedBox(height: 4),
                      if (!hasVariants)
                        Text(
                          RuntimeAppSettings.money(item.price),
                          style: AppStyles.getBoldTextStyle(fontSize: 15, color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showItemConfigDialog(
    BuildContext context, {
    required Item item,
    required List<ItemVariant> variants,
    required List<ItemTopping> toppings,
  }) {
    showDialog(
      context: context,
      builder: (_) => ItemVariantDialog(
        item: item,
        parentContext: context,
        variants: variants,
        toppings: toppings,
      ),
    );
  }
}
