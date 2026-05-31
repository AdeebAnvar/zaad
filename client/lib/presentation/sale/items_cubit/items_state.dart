part of 'items_cubit.dart';

abstract class ItemState {}

class ItemsInitialState extends ItemState {}

class ItemsLoadedState extends ItemState {
  final List<Item> items;
  final List<Category> categories;
  final Set<int> variantItemIds;
  final Set<int> toppingItemIds;
  final String searchQuery;

  ItemsLoadedState({
    required this.items,
    required this.categories,
    this.variantItemIds = const {},
    this.toppingItemIds = const {},
    this.searchQuery = '',
  });
}
