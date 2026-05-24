import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/presentation/sale/cart_cubit/cart_cubit.dart';
import 'package:pos/presentation/sale/item_search_field.dart';
import 'package:pos/presentation/sale/mobile/mobile_category_bar.dart';
import 'package:pos/presentation/sale/mobile/mobile_item_list.dart';
import 'package:pos/presentation/sale/sale_screen.dart';

class MobileSaleLayout extends StatelessWidget {
  const MobileSaleLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Stack(
        children: [
          Column(
            children: [
              const ItemSearchField(),
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8),
                child: MobileCategoryBar(),
              ),
              Expanded(child: MobileItemsList()),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: BlocBuilder<CartCubit, CartState>(
              builder: (_, state) => Stack(
                clipBehavior: Clip.none,
                children: [
                  FloatingActionButton(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    onPressed: () => SaleScreenFunction.openCart(context),
                    child: const Icon(Icons.shopping_cart),
                  ),
                  if (state.items.isNotEmpty)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Center(
                          child: Text(
                            state.items.length > 99 ? '99+' : '${state.items.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
