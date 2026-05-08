import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  StreamSubscription<List<Item>>? _itemsSub;
  StreamSubscription<List<Category>>? _categoriesSub;
  StreamSubscription<List<ItemVariant>>? _variantsSub;

  int _selectedCategoryId = -1;
  int get selectedCategoryId => _selectedCategoryId;
  String _searchQuery = "";
  static const String _debugLogPath = r'c:\Users\adeeb\OneDrive\Desktop\pos\pos\debug-aa2a57.log';
  static const String _debugSessionId = 'aa2a57';

  /// Canonical token for `[Item.deliveryPartner]` comparison (often numeric id string).
  String? _deliveryFilterToken;

  Future<void> fetchItemsAndCategories() async {
    _allItems = await _repo.fetchItemsFromLocal();
    _allCategories = await _repo.fetchCategoriesFromLocal();
    final allVariants = await _repo.fetchAllVariants();
    _variantItemIds = allVariants.map((v) => v.itemId).toSet();
    await _resolveDeliveryFilterToken();
    // #region agent log
    await _agentLog(
      runId: 'pre-fix',
      hypothesisId: 'H2',
      location: 'items_cubit.dart:49',
      message: 'Initial catalog snapshot loaded',
      data: {
        'total_items': _allItems.length,
        'nutella_ids': _allItems
            .where((i) => i.name.trim().toLowerCase().contains('nutella'))
            .map((i) => i.id)
            .toList(),
        'category_count': _allCategories.length,
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
      // #region agent log
      unawaited(_agentLog(
        runId: 'pre-fix',
        hypothesisId: 'H3',
        location: 'items_cubit.dart:66',
        message: 'Items watcher emitted update',
        data: {
          'total_items': items.length,
          'nutella_ids': items
              .where((i) => i.name.trim().toLowerCase().contains('nutella'))
              .map((i) => i.id)
              .toList(),
        },
      ));
      // #endregion
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
    // #region agent log
    unawaited(_agentLog(
      runId: 'pre-fix',
      hypothesisId: 'H4',
      location: 'items_cubit.dart:142',
      message: 'Filtered catalog emitted to UI',
      data: {
        'selected_category': _selectedCategoryId,
        'search': _searchQuery,
        'filtered_count': filtered.length,
        'filtered_nutella_ids': filtered
            .where((i) => i.name.trim().toLowerCase().contains('nutella'))
            .map((i) => i.id)
            .toList(),
      },
    ));
    // #endregion
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

  Future<void> _agentLog({
    required String runId,
    required String hypothesisId,
    required String location,
    required String message,
    required Map<String, dynamic> data,
  }) async {
    try {
      final payload = <String, dynamic>{
        'sessionId': _debugSessionId,
        'runId': runId,
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await File(_debugLogPath).writeAsString(
        '${jsonEncode(payload)}\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {}
  }
}

extension ItemUiX on Item {
  /// UI helpers (do NOT touch DB schema)
  bool get hasVariants => false; // derived from cubit state
  bool get hasToppings => false; // default
}
