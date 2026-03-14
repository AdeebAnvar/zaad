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

  int _selectedCategoryId = -1;
  int get selectedCategoryId => _selectedCategoryId;
  String _searchQuery = "";

  Future<void> fetchItemsAndCategories() async {
    _allItems = await _repo.fetchItemsFromLocal();
    _allCategories = await _repo.fetchCategoriesFromLocal();
    _applyFilters();
  }

  void selectCategory(int categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
  }

  void search(String query) {
    _searchQuery = query.toLowerCase().trim();
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
  bool get hasVariants => false; // default
  bool get hasToppings => false; // default
}
