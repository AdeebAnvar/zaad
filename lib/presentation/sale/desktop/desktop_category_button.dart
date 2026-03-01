import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/presentation/sale/category_button.dart';
import 'package:pos/presentation/sale/item_cubit.dart/items_cubit.dart';

class CategoryPanel extends StatelessWidget {
  const CategoryPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      // margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: BlocBuilder<ItemsCubit, ItemState>(
        builder: (_, state) {
          final cubit = context.read<ItemsCubit>();
          if (state is ItemsLoadedState) {
            return ListView(
              children: [
                CategoryButton(
                  label: "ALL",
                  selected: cubit.selectedCategoryId == -1,
                  onTap: () => context.read<ItemsCubit>().selectCategory(-1),
                ),
                ...state.categories.map(
                  (c) => CategoryButton(
                    label: c.name,
                    selected: cubit.selectedCategoryId == c.id,
                    onTap: () => context.read<ItemsCubit>().selectCategory(c.id),
                  ),
                ),
              ],
            );
          }
          return Text('No Categories');
        },
      ),
    );
  }
}
