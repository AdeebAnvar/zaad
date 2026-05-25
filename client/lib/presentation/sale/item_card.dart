import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/presentation/sale/cart_cubit/cart_cubit.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';
import 'package:pos/presentation/sale/items_cubit/items_cubit.dart';
import 'package:pos/presentation/sale/item_variant_dialog.dart';
import 'package:pos/presentation/widgets/catalog_item_image.dart';

class ItemCard extends StatelessWidget {
  final Item item;

  const ItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
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

        try {
          final variants = await itemsCubit.getVariants(item.id);
          final toppings = await itemsCubit.getToppings(item.id);
          final toppingGroups = await itemsCubit.getToppingGroups(item.id);
          // If item has variants, show configuration dialog (variant required before add).
          if (variants.isNotEmpty) {
            if (!context.mounted) return;
            showItemConfigDialog(
              context,
              item: item,
              variants: variants,
              toppings: toppings,
              toppingGroups: toppingGroups,
            );
          } else {
            await cartCubit.addItemToCart(item);
            itemsCubit.clearSearch();
          }
        } catch (e) {
          if (!context.mounted) return;
          final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
          if (msg.contains('No active branch session')) {
            CustomSnackBar.showError(
              message: 'Session expired — log in again before adding items.',
            );
          } else {
            showErrorDialog(context, e);
          }
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
              // 🔹 IMAGE (local file when present; else remote/placeholder)
              Positioned.fill(
                child: CatalogItemImage(
                  item: item,
                  fit: BoxFit.cover,
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
    required List<ToppingGroup> toppingGroups,
  }) {
    showDialog(
      context: context,
      builder: (_) => ItemVariantDialog(
        item: item,
        parentContext: context,
        variants: variants,
        toppings: toppings,
        toppingGroups: toppingGroups,
      ),
    );
  }
}
