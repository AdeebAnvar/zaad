import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/presentation/sale/item_card.dart';
import 'package:pos/presentation/sale/item_cubit.dart/items_cubit.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';

class ItemsPanel extends StatelessWidget {
  const ItemsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 5, right: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        children: [
          CustomTextField(
            onChanged: (v) => context.read<ItemsCubit>().search(v),
            labelText: 'Search/Scan Item',
            // decoration: const InputDecoration(hintText: "Search items"),
          ),
          Expanded(
            child: BlocBuilder<ItemsCubit, ItemState>(
              builder: (_, state) {
                if (state is ItemsLoadedState) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      crossAxisSpacing: 5,
                      mainAxisSpacing: 5,
                    ),
                    itemCount: state.items.length,
                    itemBuilder: (_, i) => ItemCard(item: state.items[i]),
                  );
                } else {
                  return const Center(child: Text("No items found"));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
