import 'dart:convert';

import 'package:pos/domain/models/driver_model.dart' as api_driver;
import 'package:pos/domain/models/pull_data_model.dart';

/// Normalizes Dio / hub mirror response bodies to a JSON object map.
Map<String, dynamic>? normalizePullResponseToMap(dynamic data) {
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

/// Parsed API driver for persistence when the payload uses sync shape with `created_updated`.
/// Call **before** [injectFullPullDataForParse], which replaces the driver envelope.
api_driver.DriverModel? extractApiDriverMap(Map<String, dynamic> raw) {
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

String? extractLastSyncedAtFromResponse(Map<String, dynamic> raw) {
  final data = raw['data'];
  if (data is Map) {
    final inData = data['last_synced_at']?.toString().trim();
    if (inData != null && inData.isNotEmpty) return inData;
  }
  final rootValue = raw['last_synced_at']?.toString().trim();
  if (rootValue != null && rootValue.isNotEmpty) return rootValue;
  return null;
}

/// Top-level entry for [AppIsolateService]: heavy JSON → [PullData] off the UI isolate.
@pragma('vm:entry-point')
PullData parsePullPageFromRaw(Map<String, dynamic> raw) {
  final prepared = Map<String, dynamic>.from(raw);
  injectFullPullDataForParse(prepared);
  return PullData.fromJson(Map<String, dynamic>.from(prepared));
}

/// Placeholder for [PullDataModel.driver] (Drift [DriverModel]) so [PullData.fromJson] succeeds.
Map<String, dynamic> _driftDriverPlaceholder() => <String, dynamic>{
      'id': 0,
      'name': '',
    };

Map<String, dynamic> _emptyResourceEnvelope() => <String, dynamic>{
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
void injectFullPullDataForParse(Map<String, dynamic> raw) {
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
    'offers',
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
      inData[k] = normalizeItemResourceEnvelope(Map<String, dynamic>.from(inData[k] as Map));
    }
  }

  raw['data'] = inData;
}

/// API sometimes returns map/object instead of list for item subfields.
Map<String, dynamic> normalizeItemResourceEnvelope(Map<String, dynamic> itemEnvelope) {
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
