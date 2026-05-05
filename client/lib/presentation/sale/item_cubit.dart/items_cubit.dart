import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/constants/enums.dart';
import 'package:pos/core/utils/item_order_channels.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/delivery_partner_repository.dart';
import 'package:pos/data/repository/item_repository.dart';
part 'items_state.dart';

class ItemsCubit extends Cubit<ItemState> {
  ItemsCubit(
    this._repo,
    this._deliveryPartnerRepo, {
    this.deliveryPartner,
    this.deliveryServiceId,
    required this.saleOrderType,
  }) : super(ItemsInitialState());

  final ItemRepository _repo;
  final DeliveryPartnerRepository _deliveryPartnerRepo;

  /// Shown on counter / persisted on carts & orders (name or `NORMAL`).
  final String? deliveryPartner;

  /// API stores `delivery_service` on items as **service id** (string); filter uses this first.
  final String? deliveryServiceId;

  /// Current counter mode (take away / dine in / delivery) from [SaleScreen].
  final OrderType saleOrderType;

  List<Item> _allItems = [];
  List<Category> _allCategories = [];
  Set<int> _variantItemIds = {};

  int _selectedCategoryId = -1;
  int get selectedCategoryId => _selectedCategoryId;
  String _searchQuery = "";

  /// Canonical token for `[Item.deliveryPartner]` comparison (often numeric id string).
  String? _deliveryFilterToken;

  Future<void> fetchItemsAndCategories() async {
    _allItems = await _repo.fetchItemsFromLocal();
    _allCategories = await _repo.fetchCategoriesFromLocal();
    final allVariants = await _repo.fetchAllVariants();
    _variantItemIds = allVariants.map((v) => v.itemId).toSet();
    await _resolveDeliveryFilterToken();
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

  Future<void> _resolveDeliveryFilterToken() async {
    _deliveryFilterToken = null;
    if (saleOrderType != OrderType.delivery) return;

    final sid = deliveryServiceId?.trim();
    if (sid != null && sid.isNotEmpty) {
      _deliveryFilterToken = sid;
      return;
    }

    final lbl = deliveryPartner?.trim();
    if (lbl == null || lbl.isEmpty) return;

    if (lbl.toUpperCase() == 'NORMAL') {
      _deliveryFilterToken = 'NORMAL';
      return;
    }
    if (int.tryParse(lbl) != null) {
      _deliveryFilterToken = lbl;
      return;
    }

    final partners = await _deliveryPartnerRepo.getAll();
    for (final p in partners) {
      if (p.name.trim().toLowerCase() == lbl.toLowerCase()) {
        _deliveryFilterToken = p.id.toString();
        return;
      }
    }

    _deliveryFilterToken = lbl;
  }

  bool _itemMatchesDeliveryService(Item i, String token) {
    final raw = i.deliveryPartner?.trim() ?? '';
    if (raw.isEmpty) return true;

    final t = token.trim();
    if (raw == t || raw.toLowerCase() == t.toLowerCase()) return true;

    final ri = int.tryParse(raw);
    final ti = int.tryParse(t);
    return ri != null && ti != null && ri == ti;
  }

  void _applyFilters() {
    List<Item> filtered = _allItems;

    final token = _deliveryFilterToken;
    if (saleOrderType == OrderType.delivery && token != null && token.isNotEmpty) {
      filtered = filtered.where((i) => _itemMatchesDeliveryService(i, token)).toList();
    }

    filtered = filtered.where((i) => i.supportsCurrentSale(saleOrderType)).toList();

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

  Future<List<ToppingGroup>> getToppingGroups(int itemId) {
    return _repo.fetchToppingGroups(itemId);
  }
}

extension ItemUiX on Item {
  /// UI helpers (do NOT touch DB schema)
  bool get hasVariants => false; // derived from cubit state
  bool get hasToppings => false; // default
}
