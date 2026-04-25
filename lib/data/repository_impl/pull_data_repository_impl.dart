import 'dart:convert';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:pos/core/utils/image_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/pull_data_repository.dart';
import 'package:pos/domain/models/api/sync/sync_api.dart';
import 'package:pos/domain/models/category_model.dart';
import 'package:pos/domain/models/customer_model.dart';
import 'package:pos/domain/models/delivery_partner_model.dart';
import 'package:pos/domain/models/driver_model.dart' as api_driver;
import 'package:pos/domain/models/expense_category_model.dart';
import 'package:pos/domain/models/item_model.dart';
import 'package:pos/domain/models/kitchen_model.dart';
import 'package:pos/domain/models/pagination_model.dart';
import 'package:pos/domain/models/pull_data_model.dart';
import 'package:pos/domain/models/staff_model.dart';
import 'package:pos/domain/models/table_model.dart';
import 'package:pos/domain/models/toppings_model.dart';
import 'package:pos/domain/models/variation_model.dart';
import 'package:pos/domain/models/waiter_model.dart';

/// Syncs with [PullDataModel] JSON keys and [SyncPaginationStates.resourceKey] values.
class _PullResource {
  const _PullResource(this.dataKey, this.paginationStoreKey);
  final String dataKey;
  final String paginationStoreKey;
}

class PullDataRepositoryImpl implements PullDataRepository {
  PullDataRepositoryImpl(this._db, this._api);

  final AppDatabase _db;
  final SyncApi _api;
  final StreamController<PullSyncProgress> _progressController = StreamController<PullSyncProgress>.broadcast();

  @override
  Stream<PullSyncProgress> get progressStream => _progressController.stream;

  void _emitProgress(String message, int current, int total) {
    if (_progressController.isClosed) return;
    _progressController.add(PullSyncProgress(message: message, current: current, total: total));
  }

  /// API query parameter name for paged pull requests.
  static const String _pageQuery = 'page';
  static const int _kMaxPagesPerResource = 500;

  static const List<_PullResource> _kPullResources = [
    _PullResource('category', 'category'),
    _PullResource('variations', 'variations'),
    _PullResource('variationOptions', 'variationOptions'),
    _PullResource('toppingCategories', 'toppingCategories'),
    _PullResource('toppings', 'toppings'),
    _PullResource('expenseCategory', 'expenseCategory'),
    _PullResource('driver', 'driver'),
    _PullResource('staffs', 'staffs'),
    _PullResource('waiters', 'waiters'),
    _PullResource('unit', 'unit'),
    _PullResource('paymentMethods', 'paymentMethods'),
    _PullResource('floors', 'pull_floors'),
    _PullResource('deliveryService', 'deliveryService'),
    _PullResource('kitchens', 'kitchens'),
    _PullResource('item', 'item'),
    _PullResource('customer', 'customer'),
    _PullResource('tables', 'tables'),
  ];

  @override
  Future<PullData> pullAndPersist() async {
    final allItemForImages = <ItemCreatedUpdated>[];
    PullData? lastPull;
    var page = 1;
    _emitProgress('Starting sync...', 0, _kMaxPagesPerResource);
    while (page <= _kMaxPagesPerResource) {
      _emitProgress('Pulling page $page...', page - 1, _kMaxPagesPerResource);
      final Response response;
      try {
        response = await _api.pullData({
          _pageQuery: page,
        });
      } on DioException catch (e) {
        throw Exception('Pull failed (page $page): ${e.message}');
      }
      if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
        throw Exception('Pull failed: HTTP ${response.statusCode}');
      }
      final raw = _normalizeToMap(response.data);
      if (raw == null) {
        throw Exception('Pull failed: response body is not a JSON object');
      }

      final driverForPersist = _extractApiDriverMap(raw);
      _injectFullPullDataForParse(raw);

      final pull = PullData.fromJson(Map<String, dynamic>.from(raw));
      if (pull.success != true) {
        throw Exception(pull.message.isNotEmpty ? pull.message : 'Pull was not successful');
      }

      final m = pull.data;
      lastPull = pull;
      _emitProgress('Saving page $page to local database...', page - 1, _kMaxPagesPerResource);

      await _db.transaction(() async {
        for (final res in _kPullResources) {
          _emitProgress('Processing ${res.dataKey} (page $page)...', page - 1, _kMaxPagesPerResource);
          final rawEnvelope = _rawResourceEnvelopeFromResponse(raw, res.dataKey);
          final items = await _persistForResource(
            m,
            res,
            driverFromPersist: res.dataKey == 'driver' ? driverForPersist : null,
            rawResourceEnvelope: rawEnvelope,
          );
          if (items.isNotEmpty) {
            allItemForImages.addAll(items);
          }
        }
      });

      var allDone = true;
      for (final res in _kPullResources) {
        final PaginationModel? pageMeta = res.dataKey == 'driver' ? driverForPersist?.pagination : _paginationForDataKey(m, res.dataKey);
        await _savePagination(res.paginationStoreKey, pageMeta);
        if (!_paginationComplete(pageMeta)) {
          allDone = false;
        }
      }
      if (allDone) {
        break;
      }
      page++;
    }

    _emitProgress('Downloading item images...', page, _kMaxPagesPerResource);
    await _downloadItemImages(allItemForImages);
    if (lastPull == null) {
      throw StateError('Pull did not return data');
    }
    _emitProgress('Sync completed', page, page);
    return lastPull;
  }

  /// Placeholder for [PullDataModel.driver] (Drift [DriverModel]) so [PullData.fromJson] succeeds.
  static Map<String, dynamic> _driftDriverPlaceholder() => <String, dynamic>{
        'id': 0,
        'name': '',
      };

  static Map<String, dynamic> _emptyResourceEnvelope() => <String, dynamic>{
        'created_updated': <dynamic>[],
        'deleted': <dynamic>[],
        'pagination': {
          'current_page': 1,
          'last_page': 1,
          'per_page': 15,
          'total': 0,
          'has_more': false,
        },
      };

  /// Ensures [raw] has a full `data` object so [PullDataModel.fromJson] can run on partial paged API responses.
  void _injectFullPullDataForParse(Map<String, dynamic> raw) {
    const keys = <String>[
      'category',
      'unit',
      'deliveryService',
      'variations',
      'variationOptions',
      'toppingCategories',
      'toppings',
      'kitchens',
      'item',
      'expenseCategory',
      'paymentMethods',
      'customer',
      'driver',
      'staffs',
      'waiters',
      'floors',
      'tables',
    ];
    final inRoot = raw['data'];
    final inData = inRoot is Map
        ? Map<String, dynamic>.from(
            inRoot.map((k, v) => MapEntry(k.toString(), v)),
          )
        : <String, dynamic>{};

    final d = inData['driver'];
    if (d is Map && d['created_updated'] != null) {
      inData['driver'] = _driftDriverPlaceholder();
    } else {
      inData['driver'] = d ?? _driftDriverPlaceholder();
    }

    for (final k in keys) {
      if (k == 'driver') {
        continue;
      }
      inData.putIfAbsent(k, () => _emptyResourceEnvelope());
      if (k == 'item' && inData[k] is Map) {
        inData[k] = _normalizeItemResourceEnvelope(Map<String, dynamic>.from(inData[k] as Map));
      }
    }

    raw['data'] = inData;
  }

  /// API sometimes returns map/object instead of list for item subfields.
  /// Normalize to the shapes expected by [ItemModel.fromJson] and [ItemCreatedUpdated.fromJson].
  Map<String, dynamic> _normalizeItemResourceEnvelope(Map<String, dynamic> itemEnvelope) {
    final out = Map<String, dynamic>.from(itemEnvelope);

    final created = out['created_updated'];
    final createdList = created is List ? created : (created is Map ? <dynamic>[created] : <dynamic>[]);

    final normalizedCreated = <dynamic>[];
    for (final row in createdList) {
      if (row is! Map) continue;
      final m = Map<String, dynamic>.from(row.map((k, v) => MapEntry(k.toString(), v)));

      final itemVariations = m['item_variations'];
      if (itemVariations is Map) {
        m['item_variations'] = <dynamic>[itemVariations];
      } else if (itemVariations is! List) {
        m['item_variations'] = <dynamic>[];
      }

      final itemPrice = m['itemprice'];
      if (itemPrice is Map) {
        m['itemprice'] = <dynamic>[itemPrice];
      } else if (itemPrice is! List) {
        m['itemprice'] = <dynamic>[];
      }

      normalizedCreated.add(m);
    }

    out['created_updated'] = normalizedCreated;
    out['deleted'] = out['deleted'] is List ? out['deleted'] : <dynamic>[];
    out['pagination'] = out['pagination'] is Map ? out['pagination'] : _emptyResourceEnvelope()['pagination'];
    return out;
  }

  /// Parsed API driver for persistence when the payload uses sync shape with `created_updated`.
  api_driver.DriverModel? _extractApiDriverMap(Map<String, dynamic> raw) {
    try {
      final data = raw['data'];
      if (data is! Map) return null;
      final d = data['driver'];
      if (d is! Map) return null;
      if (d['created_updated'] == null) return null;
      return api_driver.DriverModel.fromJson(Map<String, dynamic>.from(d));
    } catch (_) {
      return null;
    }
  }

  PaginationModel? _paginationForDataKey(PullDataModel m, String dataKey) {
    switch (dataKey) {
      case 'category':
        return m.category.pagination;
      case 'unit':
        return m.unit.pagination;
      case 'deliveryService':
        return m.deliveryService.pagination;
      case 'variations':
        return m.variations.pagination;
      case 'variationOptions':
        return m.variationOptions.pagination;
      case 'toppingCategories':
        return m.toppingCategories.pagination;
      case 'toppings':
        return m.toppings.pagination;
      case 'kitchens':
        return m.kitchens.pagination;
      case 'item':
        return m.item.pagination;
      case 'expenseCategory':
        return m.expenseCategory.pagination;
      case 'paymentMethods':
        return m.paymentMethods.pagination;
      case 'customer':
        return m.customer.pagination;
      case 'driver':
        return null;
      case 'staffs':
        return m.staffs.pagination;
      case 'waiters':
        return m.waiters.pagination;
      case 'floors':
        return m.floors.pagination;
      case 'tables':
        return m.tables.pagination;
      default:
        return null;
    }
  }

  bool _paginationComplete(PaginationModel? pg) {
    if (pg == null) return true;
    if (pg.hasMore) return false;
    if (pg.currentPage < pg.lastPage) return false;
    return true;
  }

  /// Persists a single [PullData] slice for the resource in [res]. Returns item rows that need image download for `item` only.
  Future<List<ItemCreatedUpdated>> _persistForResource(
    PullDataModel m,
    _PullResource res, {
    api_driver.DriverModel? driverFromPersist,
    Map<String, dynamic>? rawResourceEnvelope,
  }) async {
    switch (res.dataKey) {
      case 'category':
        await _persistCategoryModel(m.category, 'category', alsoCategoriesTable: true);
        await _applyDeletedForResource(res.dataKey, rawResourceEnvelope);
        return <ItemCreatedUpdated>[];
      case 'variations':
        await _persistVariationsModel(m.variations, 'variations', alsoCategoriesTable: false);
        await _applyDeletedForResource(res.dataKey, rawResourceEnvelope);
        return <ItemCreatedUpdated>[];
      case 'variationOptions':
        await _persistVariationOptionsModel(m.variationOptions, 'variationOptions', alsoCategoriesTable: false);
        await _applyDeletedForResource(res.dataKey, rawResourceEnvelope);
        return <ItemCreatedUpdated>[];
      case 'toppingCategories':
        await _persistToppingModel(m.toppingCategories, 'toppingCategories', alsoCategoriesTable: false);
        await _applyDeletedForResource(res.dataKey, rawResourceEnvelope);
        return <ItemCreatedUpdated>[];
      case 'toppings':
        await _persistToppingModel(m.toppings, 'toppings', alsoCategoriesTable: false);
        await _applyDeletedForResource(res.dataKey, rawResourceEnvelope);
        return <ItemCreatedUpdated>[];
      case 'expenseCategory':
        await _persistExpenseCategoryModel(m.expenseCategory, 'expenseCategory', alsoCategoriesTable: false);
        await _applyDeletedForResource(res.dataKey, rawResourceEnvelope);
        return <ItemCreatedUpdated>[];
      case 'driver':
        if (driverFromPersist != null) {
          await _persistDriverPull(driverFromPersist);
        }
        await _applyDeletedForResource(res.dataKey, rawResourceEnvelope);
        return <ItemCreatedUpdated>[];
      case 'staffs':
        await _persistStaffsModel(m.staffs, 'staffs', alsoCategoriesTable: false);
        await _applyDeletedForResource(res.dataKey, rawResourceEnvelope);
        return <ItemCreatedUpdated>[];
      case 'waiters':
        await _persistWaitersModel(m.waiters, 'waiters', alsoCategoriesTable: false);
        await _applyDeletedForResource(res.dataKey, rawResourceEnvelope);
        return <ItemCreatedUpdated>[];
      case 'unit':
        await _persistFloorModel(m.unit, 'unit', syncDineFloors: false);
        await _applyDeletedForResource(res.dataKey, rawResourceEnvelope);
        return <ItemCreatedUpdated>[];
      case 'paymentMethods':
        await _persistFloorModel(m.paymentMethods, 'paymentMethods', syncDineFloors: false);
        await _applyDeletedForResource(res.dataKey, rawResourceEnvelope);
        return <ItemCreatedUpdated>[];
      case 'floors':
        await _persistFloorModel(m.floors, 'floors', syncDineFloors: true);
        await _applyDeletedForResource(res.dataKey, rawResourceEnvelope);
        return <ItemCreatedUpdated>[];
      case 'deliveryService':
        await _persistDeliveryService(m.deliveryService);
        await _applyDeletedForResource(res.dataKey, rawResourceEnvelope);
        return <ItemCreatedUpdated>[];
      case 'kitchens':
        await _persistKitchens(m.kitchens);
        await _applyDeletedForResource(res.dataKey, rawResourceEnvelope);
        return <ItemCreatedUpdated>[];
      case 'item':
        final items = await _persistItems(m.item);
        await _applyDeletedForResource(res.dataKey, rawResourceEnvelope);
        return items;
      case 'customer':
        await _persistCustomers(m.customer);
        await _applyDeletedForResource(res.dataKey, rawResourceEnvelope);
        return <ItemCreatedUpdated>[];
      case 'tables':
        await _persistTables(m.tables);
        await _applyDeletedForResource(res.dataKey, rawResourceEnvelope);
        return <ItemCreatedUpdated>[];
      default:
        return <ItemCreatedUpdated>[];
    }
  }

  Map<String, dynamic>? _rawResourceEnvelopeFromResponse(
    Map<String, dynamic> raw,
    String dataKey,
  ) {
    final data = raw['data'];
    if (data is! Map) return null;
    final dynamic envelope = data[dataKey];
    if (envelope is! Map) return null;
    return Map<String, dynamic>.from(
      envelope.map((k, v) => MapEntry(k.toString(), v)),
    );
  }

  List<int> _extractDeletedIds(Map<String, dynamic>? resourceEnvelope) {
    if (resourceEnvelope == null) return const <int>[];
    final rawDeleted = resourceEnvelope['deleted'];
    if (rawDeleted is! List) return const <int>[];
    final ids = <int>{};
    for (final e in rawDeleted) {
      if (e is int) {
        ids.add(e);
        continue;
      }
      if (e is String) {
        final p = int.tryParse(e);
        if (p != null) ids.add(p);
        continue;
      }
      if (e is Map) {
        final m = Map<String, dynamic>.from(
          e.map((k, v) => MapEntry(k.toString(), v)),
        );
        final rawId = m['id'] ?? m['record_id'] ?? m['model_id'];
        if (rawId is int) {
          ids.add(rawId);
        } else if (rawId is String) {
          final p = int.tryParse(rawId);
          if (p != null) ids.add(p);
        }
      }
    }
    return ids.toList();
  }

  Future<void> _deleteFromPullCategoryRows(String resourceKey, List<int> ids) async {
    if (ids.isEmpty) return;
    await (_db.delete(_db.pullCategoryRows)
          ..where(
            (t) => t.resourceKey.equals(resourceKey) & t.id.isIn(ids),
          ))
        .go();
  }

  Future<void> _deleteFromPullFloorRows(String resourceKey, List<int> ids) async {
    if (ids.isEmpty) return;
    await (_db.delete(_db.pullFloorRows)
          ..where(
            (t) => t.resourceKey.equals(resourceKey) & t.id.isIn(ids),
          ))
        .go();
  }

  Future<void> _applyDeletedForResource(
    String dataKey,
    Map<String, dynamic>? resourceEnvelope,
  ) async {
    final ids = _extractDeletedIds(resourceEnvelope);
    if (ids.isEmpty) return;

    switch (dataKey) {
      case 'category':
        await _deleteFromPullCategoryRows('category', ids);
        await (_db.delete(_db.categories)..where((t) => t.id.isIn(ids))).go();
        break;
      case 'variations':
      case 'variationOptions':
      case 'toppingCategories':
      case 'toppings':
      case 'expenseCategory':
      case 'staffs':
      case 'waiters':
        await _deleteFromPullCategoryRows(dataKey, ids);
        break;
      case 'driver':
        await _deleteFromPullCategoryRows('driver', ids);
        await (_db.delete(_db.drivers)..where((t) => t.id.isIn(ids))).go();
        break;
      case 'unit':
      case 'paymentMethods':
        await _deleteFromPullFloorRows(dataKey, ids);
        break;
      case 'floors':
        await _deleteFromPullFloorRows('floors', ids);
        await (_db.delete(_db.diningFloors)..where((t) => t.id.isIn(ids))).go();
        await (_db.delete(_db.diningTables)..where((t) => t.floorId.isIn(ids))).go();
        break;
      case 'deliveryService':
        await (_db.delete(_db.pullDeliveryServiceRows)..where((t) => t.id.isIn(ids))).go();
        await (_db.delete(_db.deliveryPartners)..where((t) => t.id.isIn(ids))).go();
        break;
      case 'kitchens':
        await (_db.delete(_db.kitchens)..where((t) => t.id.isIn(ids))).go();
        break;
      case 'item':
        await (_db.delete(_db.pullItemRows)..where((t) => t.id.isIn(ids))).go();
        await (_db.delete(_db.itemVariants)..where((t) => t.itemId.isIn(ids))).go();
        await (_db.delete(_db.itemToppings)..where((t) => t.itemId.isIn(ids))).go();
        await (_db.delete(_db.items)..where((t) => t.id.isIn(ids))).go();
        break;
      case 'customer':
        await (_db.delete(_db.customers)
              ..where(
                (t) => t.serverId.isIn(ids.map((e) => e.toString()).toList()) | t.id.isIn(ids),
              ))
            .go();
        break;
      case 'tables':
        await (_db.delete(_db.diningTables)..where((t) => t.id.isIn(ids))).go();
        break;
      default:
        break;
    }
  }

  Map<String, dynamic>? _normalizeToMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.map((k, v) => MapEntry(k.toString(), v));
    if (data is String) {
      try {
        final d = json.decode(data);
        if (d is Map<String, dynamic>) return d;
        if (d is Map) return d.map((k, v) => MapEntry(k.toString(), v));
      } catch (_) {}
    }
    return null;
  }

  Future<void> _savePagination(String resourceKey, PaginationModel? pg) async {
    if (pg == null) return;
    final from = pg.perPage > 0 ? (pg.currentPage - 1) * pg.perPage + 1 : null;
    final to = pg.perPage > 0 ? (pg.currentPage * pg.perPage).clamp(0, pg.total) : null;
    await _db.pullDataDao.savePagination(
      SyncPaginationStatesCompanion.insert(
        resourceKey: resourceKey,
        currentPage: Value(pg.currentPage),
        pageFrom: Value(from),
        lastPage: Value(pg.lastPage),
        perPage: Value(pg.perPage),
        pageTo: Value(to),
        total: Value(pg.total),
      ),
    );
  }

  DateTime? _asDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  String _dynToString(dynamic o) {
    if (o == null) return '';
    return o.toString();
  }

  String _variationsToJson(List<dynamic> list) {
    return jsonEncode(list);
  }

  String? _toppingIdsToString(dynamic t) {
    if (t == null) return null;
    if (t is String) return t.isEmpty ? null : t;
    return jsonEncode(t);
  }

  Future<void> _persistCategoryModel(
    CategoryModel r,
    String resourceKey, {
    required bool alsoCategoriesTable,
  }) async {
    for (final c in r.createdUpdated) {
      final onValue = c.otherName == null ? const Value<String?>(null) : Value<String?>(_dynToString(c.otherName));
      await _db.pullDataDao.upsertPullCategory(
        PullCategoryRowsCompanion.insert(
          resourceKey: resourceKey,
          id: c.id,
          uuid: c.uuid,
          branchId: c.branchId,
          categoryName: c.categoryName,
          categorySlug: c.categorySlug,
          otherName: onValue,
          createdAt: c.createdAt,
          updatedAt: c.updatedAt,
          deletedAt: Value(_asDateTime(c.deletedAt)),
        ),
      );
      if (alsoCategoriesTable) {
        await _db.categoryDao.insertOrUpdateCategory(
          CategoriesCompanion.insert(
            id: Value(c.id),
            name: c.categoryName,
            otherName: _dynToString(c.otherName),
            recordUuid: Value(c.uuid),
            branchId: Value(c.branchId),
            categorySlug: Value(c.categorySlug),
            deletedAt: Value(_asDateTime(c.deletedAt)),
          ),
        );
      }
    }
  }

  Future<void> _persistVariationsModel(
    VariationsModel r,
    String resourceKey, {
    required bool alsoCategoriesTable,
  }) async {
    for (final c in r.createdUpdated) {
      await _db.pullDataDao.upsertPullCategory(
        PullCategoryRowsCompanion.insert(
          resourceKey: resourceKey,
          id: c.id,
          uuid: c.uuid,
          branchId: c.branchId,
          categoryName: c.name,
          categorySlug: c.variationSlug,
          otherName: const Value(null),
          createdAt: c.createdAt,
          updatedAt: c.updatedAt,
          deletedAt: Value(_asDateTime(c.deletedAt)),
        ),
      );
    }
  }

  Future<void> _persistVariationOptionsModel(
    VariationOptionsModel r,
    String resourceKey, {
    required bool alsoCategoriesTable,
  }) async {
    for (final c in r.createdUpdated) {
      await _db.pullDataDao.upsertPullCategory(
        PullCategoryRowsCompanion.insert(
          resourceKey: resourceKey,
          id: c.id,
          uuid: c.uuid,
          branchId: c.branchId,
          categoryName: c.option,
          categorySlug: c.optionSlug,
          otherName: const Value(null),
          createdAt: c.createdAt,
          updatedAt: c.updatedAt,
          deletedAt: Value(_asDateTime(c.deletedAt)),
        ),
      );
    }
  }

  Future<void> _persistToppingModel(
    ToppingModel r,
    String resourceKey, {
    required bool alsoCategoriesTable,
  }) async {
    for (final c in r.createdUpdated) {
      await _db.pullDataDao.upsertPullCategory(
        PullCategoryRowsCompanion.insert(
          resourceKey: resourceKey,
          id: c.id,
          uuid: c.uuid,
          branchId: c.branchId,
          categoryName: c.name,
          categorySlug: c.slug,
          otherName: const Value(null),
          createdAt: c.createdAt,
          updatedAt: c.updatedAt,
          deletedAt: Value(_asDateTime(c.deletedAt)),
        ),
      );
    }
  }

  Future<void> _persistExpenseCategoryModel(
    ExpenseCategoryModel r,
    String resourceKey, {
    required bool alsoCategoriesTable,
  }) async {
    for (final c in r.createdUpdated) {
      final name = c.expenseCategoryName != null && c.expenseCategoryName!.trim().isNotEmpty
          ? c.expenseCategoryName!.trim()
          : (c.unitName != null && c.unitName!.trim().isNotEmpty
              ? c.unitName!.trim()
              : (c.floorName != null && c.floorName!.trim().isNotEmpty
                  ? c.floorName!.trim()
                  : (c.paymentMethodName?.trim().isNotEmpty == true ? c.paymentMethodName!.trim() : 'item')));
      final slug = c.expenseCategorySlug != null && c.expenseCategorySlug!.trim().isNotEmpty
          ? c.expenseCategorySlug!.trim()
          : (c.unitSlug != null && c.unitSlug!.trim().isNotEmpty
              ? c.unitSlug!.trim()
              : (c.floorSlug != null && c.floorSlug!.trim().isNotEmpty
                  ? c.floorSlug!.trim()
                  : (c.paymentMethodSlug != null && c.paymentMethodSlug!.trim().isNotEmpty ? c.paymentMethodSlug!.trim() : (name.isNotEmpty ? name : 'id-${c.id}'))));
      await _db.pullDataDao.upsertPullCategory(
        PullCategoryRowsCompanion.insert(
          resourceKey: resourceKey,
          id: c.id,
          uuid: c.uuid,
          branchId: c.branchId,
          categoryName: name,
          categorySlug: slug,
          otherName: const Value(null),
          createdAt: c.createdAt,
          updatedAt: c.updatedAt,
          deletedAt: Value(_asDateTime(c.deletedAt)),
        ),
      );
    }
  }

  Future<void> _persistDriverPull(api_driver.DriverModel r) async {
    for (final c in r.createdUpdated) {
      final slug = c.driverCode.isNotEmpty ? c.driverCode : c.uuid;
      await _db.pullDataDao.upsertPullCategory(
        PullCategoryRowsCompanion.insert(
          resourceKey: 'driver',
          id: c.id,
          uuid: c.uuid,
          branchId: c.branchId,
          categoryName: c.driverName,
          categorySlug: slug,
          otherName: const Value(null),
          createdAt: c.createdAt,
          updatedAt: c.updatedAt,
          deletedAt: Value(_asDateTime(c.deletedAt)),
        ),
      );
    }
  }

  Future<void> _persistStaffsModel(
    StaffsModel r,
    String resourceKey, {
    required bool alsoCategoriesTable,
  }) async {
    for (final c in r.createdUpdated) {
      final slug = c.staffCode.isNotEmpty ? c.staffCode : c.uuid;
      await _db.pullDataDao.upsertPullCategory(
        PullCategoryRowsCompanion.insert(
          resourceKey: resourceKey,
          id: c.id,
          uuid: c.uuid,
          branchId: c.branchId,
          categoryName: c.staffName,
          categorySlug: slug,
          otherName: const Value(null),
          createdAt: c.createdAt,
          updatedAt: c.updatedAt,
          deletedAt: Value(_asDateTime(c.deletedAt)),
        ),
      );
    }
  }

  Future<void> _persistWaitersModel(
    WaitersModel r,
    String resourceKey, {
    required bool alsoCategoriesTable,
  }) async {
    for (final c in r.createdUpdated) {
      final slug = c.waiterCode.isNotEmpty ? c.waiterCode : c.uuid;
      await _db.pullDataDao.upsertPullCategory(
        PullCategoryRowsCompanion.insert(
          resourceKey: resourceKey,
          id: c.id,
          uuid: c.uuid,
          branchId: c.branchId,
          categoryName: c.waiterName,
          categorySlug: slug,
          otherName: const Value(null),
          createdAt: c.createdAt,
          updatedAt: c.updatedAt,
          deletedAt: Value(_asDateTime(c.deletedAt)),
        ),
      );
    }
  }

  /// [unit], [paymentMethods], [floors] in [PullDataModel] are [ExpenseCategoryModel].
  Future<void> _persistFloorModel(
    ExpenseCategoryModel r,
    String resourceKey, {
    required bool syncDineFloors,
  }) async {
    for (final f in r.createdUpdated) {
      await _db.pullDataDao.upsertPullFloor(
        PullFloorRowsCompanion.insert(
          resourceKey: resourceKey,
          id: f.id,
          uuid: f.uuid,
          branchId: f.branchId,
          floorName: Value(f.floorName),
          floorSlug: Value(f.floorSlug),
          createdAt: f.createdAt,
          updatedAt: f.updatedAt,
          deletedAt: Value(_asDateTime(f.deletedAt)),
          paymentMethodName: Value(f.paymentMethodName),
          paymentMethodSlug: Value(f.paymentMethodSlug),
          unitName: Value(f.unitName),
          unitSlug: Value(f.unitSlug),
        ),
      );
      final dineName = f.floorName != null && f.floorName!.trim().isNotEmpty ? f.floorName!.trim() : f.unitName?.trim();
      if (syncDineFloors && dineName != null && dineName.isNotEmpty) {
        await _db.diningTablesDao.upsertFloor(
          DiningFloorsCompanion.insert(
            id: Value(f.id),
            name: dineName,
            sortOrder: const Value(0),
            recordUuid: Value(f.uuid),
            branchId: Value(f.branchId),
            floorSlug: Value(f.floorSlug ?? f.unitSlug),
            deletedAt: Value(_asDateTime(f.deletedAt)),
          ),
        );
      }
    }
  }

  Future<void> _persistDeliveryService(DeliveryServiceModel r) async {
    for (final d in r.createdUpdated) {
      String? dr;
      if (d.driverStatus != null) {
        final s = d.driverStatus is String ? d.driverStatus as String : d.driverStatus.toString();
        if (s.isNotEmpty) dr = s;
      }
      await _db.pullDataDao.upsertPullDeliveryService(
        PullDeliveryServiceRowsCompanion.insert(
          id: Value(d.id),
          uuid: d.uuid,
          branchId: d.branchId,
          serviceName: d.serviceName,
          serviceNameSlug: d.serviceNameSlug,
          driverStatus: Value(dr),
          createdAt: d.createdAt,
          updatedAt: d.updatedAt,
          deletedAt: Value(_asDateTime(d.deletedAt)),
        ),
      );
      await _db.deliveryPartnersDao.upsertDeliveryPartner(
        DeliveryPartnersCompanion.insert(
          id: Value(d.id),
          name: d.serviceName,
        ),
      );
    }
  }

  Future<void> _persistKitchens(KitchensModel r) async {
    for (final k in r.createdUpdated) {
      await _db.itemDao.upsertKitchen(
        KitchensCompanion.insert(
          id: Value(k.id),
          name: k.kitchenName,
          printerDetails: Value(k.printerDetails),
          printerType: Value(k.printerType),
          recordUuid: Value(k.uuid),
          branchId: Value(k.branchId),
          deletedAt: Value(_asDateTime(k.deletedAt)),
        ),
      );
    }
  }

  Future<List<ItemCreatedUpdated>> _persistItems(ItemModel r) async {
    final out = <ItemCreatedUpdated>[];
    for (final e in r.createdUpdated) {
      out.add(e);
      final varJson = _variationsToJson(e.itemVariations);
      final priceJson = jsonEncode(e.itemprice.map((ip) => ip.toJson()).toList());
      await _db.pullDataDao.upsertPullItem(
        PullItemRowsCompanion.insert(
          id: Value(e.id),
          uuid: e.uuid,
          branchId: e.branchId,
          categoryId: e.categoryId,
          unitId: e.unitId,
          itemName: e.itemName,
          itemSlug: e.itemSlug,
          itemOtherName: Value(e.itemOtherName),
          kitchenIds: e.kitchenIds,
          toppingIds: Value(_toppingIdsToString(e.toppingIds)),
          tax: e.tax.name,
          taxPercent: Value(e.taxPercent?.toString()),
          minimumQty: e.minimumQty,
          itemType: e.itemType,
          stockApplicable: e.stockApplicable,
          ingredient: e.ingredient,
          orderType: e.orderType.name,
          deliveryService: e.deliveryService,
          image: e.image,
          expiryDate: Value(e.expiryDate.toString()),
          active: e.active.name,
          isVariant: e.isVariant,
          itemVariationsJson: Value(varJson),
          itempriceJson: Value(priceJson),
          createdAt: e.createdAt,
          updatedAt: e.updatedAt,
          deletedAt: Value(_asDateTime(e.deletedAt)),
        ),
      );

      final firstPrice = e.itemprice.isNotEmpty ? e.itemprice.first.price : 0.0;
      final firstStock = e.itemprice.isNotEmpty ? e.itemprice.first.stock : 0;
      final kId = _firstIntFromKitchenIds(e.kitchenIds);
      final stockOn = (e.stockApplicable).toLowerCase() == 'yes' || e.stockApplicable == '1';

      await _db.itemDao.upsertItem(
        ItemsCompanion.insert(
          id: Value(e.id),
          name: e.itemName,
          otherName: e.itemOtherName,
          sku: e.itemSlug,
          price: firstPrice,
          stock: firstStock,
          stockEnabled: Value(stockOn),
          localImagePath: const Value(null),
          imagePath: Value(e.image),
          categoryName: '',
          categoryOtherName: '',
          barcode: e.itemSlug,
          categoryId: e.categoryId,
          kitchenId: Value(kId),
          kitchenName: const Value(null),
          deliveryPartner: e.deliveryService.isNotEmpty ? Value(e.deliveryService) : const Value(null),
        ),
      );

      for (final v in e.itemVariations) {
        if (v is! Map) continue;
        final vm = Map<String, dynamic>.from(v);
        final vn = vm['name']?.toString() ?? 'Variant';
        final rawP = vm['price'];
        final vp = rawP is num ? rawP.toDouble() : (double.tryParse('$rawP') ?? 0.0);
        await _db.itemDao.upsertVariant(
          ItemVariantsCompanion.insert(
            itemId: e.id,
            name: vn,
            price: vp,
          ),
        );
      }
    }
    return out;
  }

  int? _firstIntFromKitchenIds(String kitchenIds) {
    if (kitchenIds.isEmpty) return null;
    final p = RegExp(r'\d+').firstMatch(kitchenIds);
    if (p == null) return null;
    return int.tryParse(p.group(0)!);
  }

  String _buildSafeImageName(int id, String url) {
    final uri = Uri.parse(url);
    final ext = p.extension(uri.path).isNotEmpty ? p.extension(uri.path) : '.jpg';
    return 'item_$id$ext';
  }

  Future<void> _downloadItemImages(List<ItemCreatedUpdated> items) async {
    for (final e in items) {
      if (e.image.isEmpty) continue;
      final row = await _db.itemDao.getItemById(e.id);
      if (row == null) continue;
      if (row.localImagePath != null && row.localImagePath!.isNotEmpty) continue;
      try {
        final path = await ImageUtils.downloadImage(e.image, _buildSafeImageName(e.id, e.image));
        await _db.itemDao.upsertItem(
          ItemsCompanion(
            id: Value(e.id),
            localImagePath: Value(path),
          ),
        );
      } catch (_) {}
    }
  }

  Future<void> _persistCustomers(CustomerModel r) async {
    for (final c in r.createdUpdated) {
      final serverKey = c.id.toString();
      final existing = await _db.customersDao.getCustomerByServerId(serverKey);
      final phone = c.customerNumber.isNotEmpty ? c.customerNumber : null;
      if (existing == null) {
        await _db.customersDao.insertOrUpdateCustomer(
          CustomersCompanion.insert(
            serverId: Value(serverKey),
            name: c.customerName,
            email: Value(c.customerEmail.isNotEmpty ? c.customerEmail : null),
            phone: Value(phone),
            gender: Value(c.customerGender.isNotEmpty ? c.customerGender : null),
            address: Value(c.customerAddress.isNotEmpty ? c.customerAddress : null),
            cardNo: Value(c.cardNo.isNotEmpty ? c.cardNo : null),
            recordUuid: Value(c.uuid),
            branchId: Value(c.branchId),
            customerNumber: Value(c.customerNumber),
            createdAt: Value(c.createdAt),
            updatedAt: Value(c.updatedAt),
            isSynced: const Value(true),
          ),
        );
      } else {
        await _db.customersDao.updateCustomer(
          CustomersCompanion(
            id: Value(existing.id),
            serverId: Value(serverKey),
            name: Value(c.customerName),
            email: Value(c.customerEmail.isNotEmpty ? c.customerEmail : null),
            phone: Value(phone),
            gender: Value(c.customerGender.isNotEmpty ? c.customerGender : null),
            address: Value(c.customerAddress.isNotEmpty ? c.customerAddress : null),
            cardNo: Value(c.cardNo.isNotEmpty ? c.cardNo : null),
            recordUuid: Value(c.uuid),
            branchId: Value(c.branchId),
            customerNumber: Value(c.customerNumber),
            updatedAt: Value(DateTime.now()),
            isSynced: const Value(true),
          ),
        );
      }
    }
  }

  Future<void> _persistTables(TablesModel r) async {
    for (final t in r.createdUpdated) {
      final code = t.tableName.isNotEmpty ? t.tableName : t.tableSlug;
      try {
        await _db.diningTablesDao.upsertTable(
          DiningTablesCompanion.insert(
            id: Value(t.id),
            floorId: t.floorId,
            code: code,
            chairs: const Value(4),
            status: const Value('free'),
            recordUuid: Value(t.uuid),
            branchId: Value(t.branchId),
            pulledTableName: Value(t.tableName),
            pulledTableSlug: Value(t.tableSlug),
            orderCount: Value(t.orderCount),
            deletedAt: Value(_asDateTime(t.deletedAt)),
          ),
        );
      } catch (_) {
        // e.g. missing floor_id FK; surface could log in debug
      }
    }
  }
}
