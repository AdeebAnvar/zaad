import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/presentation/sale/cart_cubit/cart_cubit.dart';
import 'package:pos/presentation/sale/desktop/desktop_cart_panel.dart';
import 'package:pos/presentation/sale/desktop/desktop_sale_layout.dart';
import 'package:pos/presentation/sale/item_cubit.dart/items_cubit.dart';
import 'package:pos/presentation/sale/mobile/mobile_sale_layout.dart';
import 'package:pos/presentation/sale/topping_dialogue.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';

const double kTabletWidth = 900;

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      context.read<ItemsCubit>().fetchItemsAndCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'TakeAway',
      appBarScreen: 'take_away',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < kTabletWidth;
          return isMobile ? const MobileSaleLayout() : const DesktopSaleLayout();
        },
      ),
    );
  }
}

class SaleScreenFunction {
  static void openCart(BuildContext context) {
    final cartCubit = context.read<CartCubit>();
    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: cartCubit,
        child: CartPanel(),
      ),
    );
  }

  void showToppingDialog(
    BuildContext context,
    Item item,
    ItemVariant? variant,
    int qty,
    List<ItemTopping> toppings,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ToppingsDialog(
        item: item,
        variant: variant,
        qty: qty,
        toppings: toppings,
      ),
    );
  }
}
