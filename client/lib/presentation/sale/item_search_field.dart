import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/presentation/sale/item_cubit.dart/items_cubit.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';

/// Search / scan field for the item catalog; clears when [ItemsCubit.clearSearch] runs.
class ItemSearchField extends StatefulWidget {
  const ItemSearchField({super.key});

  @override
  State<ItemSearchField> createState() => _ItemSearchFieldState();
}

class _ItemSearchFieldState extends State<ItemSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ItemsCubit, ItemState>(
      listenWhen: (prev, curr) {
        if (curr is! ItemsLoadedState) return false;
        if (prev is! ItemsLoadedState) return true;
        return prev.searchQuery != curr.searchQuery;
      },
      listener: (context, state) {
        if (state is ItemsLoadedState && state.searchQuery.isEmpty && _controller.text.isNotEmpty) {
          _controller.clear();
        }
      },
      child: CustomTextField(
        controller: _controller,
        onChanged: (v) => context.read<ItemsCubit>().search(v),
        labelText: 'Search/Scan Item',
        textAlign: TextAlign.center,
      ),
    );
  }
}
