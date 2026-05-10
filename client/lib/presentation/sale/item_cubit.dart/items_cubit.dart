import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/core/constants/enums.dart';
import 'package:pos/core/debug/agent_debug_log.dart';
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
  StreamSubscription<List<Item>>? _itemsSub;
  StreamSubscription<List<Category>>? _categoriesSub;
  StreamSubscription<List<ItemVariant>>? _variantsSub;

  /// Avoid spamming debug log on every keystroke/category tap.
  String? _lastFilterLogSignature;

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
    // #region agent log
    agentDebugLog(
      hypothesisId: 'H_ITEMS_2',
      location: 'items_cubit.dart:fetchItemsAndCategories',
      message: 'catalog_snapshot_loaded',
      data: <String, Object?>{
        'rawItemCount': _allItems.length,
        'categoryCount': _allCategories.length,
        'saleOrderType': saleOrderType.name,
      },
    );
    // #endregion
    _applyFilters();
    _startCatalogWatchers();
  }

  void _startCatalogWatchers() {
    _itemsSub?.cancel();
    _categoriesSub?.cancel();
    _variantsSub?.cancel();

    _itemsSub = _repo.watchItemsFromLocal().listen((items) {
      _allItems = items;
      _applyFilters();
    });
    _categoriesSub = _repo.watchCategoriesFromLocal().listen((categories) {
      _allCategories = categories;
      _applyFilters();
    });
    _variantsSub = _repo.watchAllVariants().listen((variants) {
      _variantItemIds = variants.map((v) => v.itemId).toSet();
      _applyFilters();
    });
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
    final rawCount = filtered.length;

    final token = _deliveryFilterToken;
    if (saleOrderType == OrderType.delivery && token != null && token.isNotEmpty) {
      filtered = filtered.where((i) => _itemMatchesDeliveryService(i, token)).toList();
    }
    final afterDeliveryCount = filtered.length;

    filtered = filtered.where((i) => i.supportsCurrentSale(saleOrderType)).toList();
    final afterChannelCount = filtered.length;

    if (_selectedCategoryId != -1) {
      filtered = filtered.where((i) => i.categoryId == _selectedCategoryId).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((i) {
        return i.name.toLowerCase().contains(_searchQuery) || i.barcode.contains(_searchQuery) || i.otherName.toLowerCase().contains(_searchQuery);
      }).toList();
    }
    final sig =
        '${rawCount}_${afterDeliveryCount}_${afterChannelCount}_${filtered.length}_${_selectedCategoryId}_${saleOrderType.name}_${_searchQuery.isNotEmpty}';
    final shouldLogFilter = rawCount == 0 || _lastFilterLogSignature != sig;
    _lastFilterLogSignature = sig;
    if (shouldLogFilter) {
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H_ITEMS_3',
        location: 'items_cubit.dart:_applyFilters',
        message: 'filtered_catalog_emit',
        data: <String, Object?>{
          'saleOrderType': saleOrderType.name,
          'deliveryTokenSet': token != null && token.isNotEmpty,
          'rawCount': rawCount,
          'afterDeliveryFilter': afterDeliveryCount,
          'afterChannelFilter': afterChannelCount,
          'selectedCategoryId': _selectedCategoryId,
          'hasSearchQuery': _searchQuery.isNotEmpty,
          'finalFilteredCount': filtered.length,
        },
      );
      // #endregion
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

  @override
  Future<void> close() async {
    await _itemsSub?.cancel();
    await _categoriesSub?.cancel();
    await _variantsSub?.cancel();
    return super.close();
  }
}

extension ItemUiX on Item {
  /// UI helpers (do NOT touch DB schema)
  bool get hasVariants => false; // derived from cubit state
  bool get hasToppings => false; // default
}
