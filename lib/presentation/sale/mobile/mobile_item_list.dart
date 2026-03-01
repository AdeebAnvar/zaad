import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/presentation/sale/item_card.dart';
import 'package:pos/presentation/sale/item_cubit.dart/items_cubit.dart';

class MobileItemsList extends StatelessWidget {
  const MobileItemsList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ItemsCubit, ItemState>(
      builder: (_, state) {
        if (state is ItemsLoadedState) {
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              crossAxisSpacing: 5,
              mainAxisSpacing: 5,
            ),
            itemCount: state.items.length,
            itemBuilder: (_, i) {
              final item = state.items[i];
              return ItemCard(item: item);
            },
          );
        } else {
          return const Center(child: Text("No items available"));
        }
      },
    );
  }
}
