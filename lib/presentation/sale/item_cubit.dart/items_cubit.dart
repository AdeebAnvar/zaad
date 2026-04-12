import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/item_repository.dart';
part 'items_state.dart';

class ItemsCubit extends Cubit<ItemState> {
  ItemsCubit(this._repo, {this.deliveryPartner}) : super(ItemsInitialState());

  final ItemRepository _repo;
  /// When set (delivery mode), filter items by this delivery partner
  final String? deliveryPartner;

  List<Item> _allItems = [];
  List<Category> _allCategories = [];
  Set<int> _variantItemIds = {};

  int _selectedCategoryId = -1;
  int get selectedCategoryId => _selectedCategoryId;
  String _searchQuery = "";

  Future<void> fetchItemsAndCategories() async {
    _allItems = await _repo.fetchItemsFromLocal();
    _allCategories = await _repo.fetchCategoriesFromLocal();
    final allVariants = await _repo.fetchAllVariants();
    _variantItemIds = allVariants.map((v) => v.itemId).toSet();
    _applyFilters();
  }

  void selectCategory(int categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
  }

  void search(String query) {
    _searchQuery = query.toLowerCase().trim();
    if (_searchQuery.isNotEmpty) {
      _selectedCategoryId = -1;
    }
    _applyFilters();
  }

  void _applyFilters() {
    List<Item> filtered = _allItems;

    if (deliveryPartner != null && deliveryPartner!.isNotEmpty) {
      filtered = filtered.where((i) {
        final dp = i.deliveryPartner;
        return dp == null || dp.isEmpty || dp == deliveryPartner;
      }).toList();
    }

    if (_selectedCategoryId != -1) {
      filtered = filtered.where((i) => i.categoryId == _selectedCategoryId).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((i) {
        return i.name.toLowerCase().contains(_searchQuery) || i.barcode.contains(_searchQuery) || i.otherName.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    emit(
      ItemsLoadedState(
        items: filtered,
        categories: _allCategories,
        variantItemIds: _variantItemIds,
      ),
    );
  }

  Future<List<ItemVariant>> getVariants(int itemId) {
    return _repo.fetchVariantsByItem(itemId);
  }

  Future<List<ItemTopping>> getToppings(int itemId) {
    return _repo.fetchToppingsByItem(itemId);
  }
}

extension ItemUiX on Item {
  /// UI helpers (do NOT touch DB schema)
  bool get hasVariants => false; // derived from cubit state
  bool get hasToppings => false; // default
}
