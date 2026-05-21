import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;
import 'package:pos/core/debug/agent_debug_log.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/sync/cloud_order_push_queue.dart';
import 'package:pos/core/sync/pos_sync_wire.dart';
import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/core/utils/delivery_partner_catalog_signal.dart';
import 'package:pos/core/utils/json_int_parse.dart';
import 'package:pos/core/utils/order_log_cart_fallback.dart';
import 'package:pos/core/utils/order_owner_display_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/branch_repository.dart';
import 'package:pos/data/repository/pull_data_repository.dart';
import 'package:pos/data/repository/settings_repository.dart';
import 'package:pos/data/repository/user_repository.dart';
import 'package:pos/domain/models/branch_model.dart';
import 'package:pos/domain/models/category_model.dart';
import 'package:pos/domain/models/company_data.dart';
import 'package:pos/domain/models/item_model.dart';
import 'package:pos/domain/models/settings_model.dart';
import 'package:pos/domain/models/user_model.dart';
import 'package:pos/features/day_closing/data/day_closing_live_sync.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';
import 'package:pos/features/orders/data/order_push_status.dart';
import 'package:pos/presentation/dine_in_log/dine_in_reference_utils.dart';
import 'package:uuid/uuid.dart';

String? _nonEmptyDynamic(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

dynamic _snapshotPick(Map<String, dynamic> snap, Map<String, dynamic>? flutter, String snakeKey,
    [String? camelKey]) {
  dynamic v = snap[snakeKey];
  if (v == null && camelKey != null) v = snap[camelKey];
  if (v == null && flutter != null) {
    v = flutter[snakeKey];
    if (v == null && camelKey != null) v = flutter[camelKey];
  }
  return v;
}

Value<String?> _mirrorOptStr(Map<String, dynamic> snap, Map<String, dynamic>? flutter, String snakeKey,
    [String? camelKey]) {
  final v = _nonEmptyDynamic(_snapshotPick(snap, flutter, snakeKey, camelKey));
  return v != null ? Value<String?>(v) : const Value.absent();
}

Value<double> _mirrorOptDouble(Map<String, dynamic> snap, Map<String, dynamic>? flutter, String snakeKey,
    [String? camelKey]) {
  final raw = _snapshotPick(snap, flutter, snakeKey, camelKey);
  if (raw == null) return const Value.absent();
  final d = raw is num ? raw.toDouble() : double.tryParse(raw.toString());
  if (d == null) return const Value.absent();
  return Value(d);
}

Value<int?> _mirrorOptInt(Map<String, dynamic> snap, Map<String, dynamic>? flutter, String snakeKey,
    [String? camelKey]) {
  final raw = _snapshotPick(snap, flutter, snakeKey, camelKey);
  if (raw == null) return const Value.absent();
  final i = raw is int ? raw : (raw is num ? raw.toInt() : int.tryParse(raw.toString()));
  if (i == null) return const Value.absent();
  return Value<int?>(i);
}

OrdersCompanion _mirroredCustomerPaymentCompanion(Map<String, dynamic> snap, Map<String, dynamic>? flutterSnap) {
  final xf = flutterSnap;
  return OrdersCompanion(
    customerName: _mirrorOptStr(snap, xf, 'customer_name', 'customerName'),
    customerEmail: _mirrorOptStr(snap, xf, 'customer_email', 'customerEmail'),
    customerPhone: _mirrorOptStr(snap, xf, 'customer_phone', 'customerPhone'),
    customerGender: _mirrorOptStr(snap, xf, 'customer_gender', 'customerGender'),
    customerAddress: _mirrorOptStr(snap, xf, 'customer_address', 'customerAddress'),
    discountAmount: _mirrorOptDouble(snap, xf, 'discount_amount', 'discountAmount'),
    discountType: _mirrorOptStr(snap, xf, 'discount_type', 'discountType'),
    cashAmount: _mirrorOptDouble(snap, xf, 'cash_amount', 'cashAmount'),
    creditAmount: _mirrorOptDouble(snap, xf, 'credit_amount', 'creditAmount'),
    cardAmount: _mirrorOptDouble(snap, xf, 'card_amount', 'cardAmount'),
    onlineAmount: _mirrorOptDouble(snap, xf, 'online_amount', 'onlineAmount'),
    deliveryPartner: _mirrorOptStr(snap, xf, 'delivery_partner', 'deliveryPartner'),
    driverId: _mirrorOptInt(snap, xf, 'driver_id', 'driverId'),
    driverName: _mirrorOptStr(snap, xf, 'driver_name', 'driverName'),
    pickupToken: _mirrorOptInt(snap, xf, 'pickup_token', 'pickupToken'),
  );
}

/// Projects validated inbound hub events into Drift after [SyncInbox] persistence.
class SyncInboxApplier {
  SyncInboxApplier(
    this.db,
    this.settings,
    this.ordersLiveSync,
    this.pullData, {
    required UserRepository userRepo,
    required BranchRepository branchRepo,
    required SettingsRepository settingsRepo,
    DayClosingLiveSync? dayClosingLiveSync,
  })  : _userRepo = userRepo,
        _branchRepo = branchRepo,
        _settingsRepo = settingsRepo,
        _dayClosingLive = dayClosingLiveSync;

  final AppDatabase db;
  final LocalHubSettings settings;
  final HubOrdersLiveSync ordersLiveSync;
  final DayClosingLiveSync? _dayClosingLive;
  final PullDataRepository pullData;
  final UserRepository _userRepo;
  final BranchRepository _branchRepo;
  final SettingsRepository _settingsRepo;

  Future<void> apply(String inboxPk, PosSyncEnvelope env, Map<String, dynamic> _) async {
    try {
      switch (env.type) {
        case PosSyncEventTypes.orderCreate:
        case PosSyncEventTypes.orderUpdate:
          await _upsertOrder(env.payload);
          ordersLiveSync.notifyHubOrdersChanged();
          break;
        case PosSyncEventTypes.delete:
          await _deleteEntity(env.payload);
          ordersLiveSync.notifyHubOrdersChanged();
          break;
        case PosSyncEventTypes.itemUpsert:
          await _applyItemUpsert(env.payload);
          break;
        case PosSyncEventTypes.categoryUpsert:
          await _applyCategoryUpsert(env.payload);
          break;
        case PosSyncEventTypes.companySnapshot:
          await _applyCompanySnapshot(env.payload);
          break;
        case PosSyncEventTypes.apiMirror:
          await _applyApiMirror(env.payload);
          break;
        case PosSyncEventTypes.dayClosingSettled:
          if (await _applyDayClosingSettled(env.payload)) {
            _dayClosingLive?.notifyDayClosingChanged();
          }
          break;
        case PosSyncEventTypes.kotCreate:
        case PosSyncEventTypes.paymentCreate:
          if (kDebugMode) {
            debugPrint('[SyncInbox] ${env.type}: stored inbox row $inboxPk (domain projection deferred)');
          }
          break;
        default:
          break;
      }
    } catch (e, st) {
      debugPrint('[SyncInbox] apply failed $inboxPk ${env.type}: $e\n$st');
      rethrow;
    }
  }

  Future<void> _applyCategoryUpsert(Map<String, dynamic> payload) async {
    final raw = payload['pullCategoryJson'];
    if (raw is! Map) {
      if (kDebugMode) debugPrint('[SyncInbox] CATEGORY_UPSERT missing pullCategoryJson');
      return;
    }
    final cat = CategoryCreatedUpdated.fromJson(Map<String, dynamic>.from(raw));
    await pullData.upsertLanHubCategory(cat);
  }

  Future<void> _applyItemUpsert(Map<String, dynamic> payload) async {
    final raw = payload['pullItemJson'];
    if (raw is! Map) {
      if (kDebugMode) debugPrint('[SyncInbox] ITEM_UPSERT missing pullItemJson');
      return;
    }
    final item = ItemCreatedUpdated.fromJson(Map<String, dynamic>.from(raw));

    String? localPath;
    final inline = payload['imageInline'];
    if (inline is Map) {
      final mime = inline['mime']?.toString();
      final b64 = inline['base64']?.toString();
      if (b64 != null && b64.isNotEmpty) {
        try {
          final bytes = base64Decode(b64);
          if (bytes.isNotEmpty) {
            final media = await AppDirectories.media();
            final name = 'hub_item_${item.id}_${const Uuid().v4()}${_extFromMime(mime)}';
            final f = File(p.join(media.path, name));
            await f.writeAsBytes(bytes, flush: true);
            localPath = f.path;
          }
        } catch (e, st) {
          if (kDebugMode) debugPrint('[SyncInbox] ITEM_UPSERT image decode failed: $e\n$st');
        }
      }
    }

    await pullData.upsertLanHubItemSnapshot(item, localImagePath: localPath);
    // #region agent log
    agentDebugLog(
      hypothesisId: 'H_ITEMS_SUB',
      location: 'sync_inbox_applier.dart:_applyItemUpsert',
      message: 'lan_item_upsert_applied',
      data: <String, Object?>{
        'itemId': item.id,
        'branchId': item.branchId,
        'hadInlineImage': localPath != null,
      },
    );
    // #endregion
  }

  Future<void> _applyCompanySnapshot(Map<String, dynamic> payload) async {
    final usersRaw = payload['users'];
    final branchesRaw = payload['branches'];
    final settingsRaw = payload['settings'];
    if (usersRaw is! List || branchesRaw is! List || settingsRaw is! Map) {
      if (kDebugMode) debugPrint('[SyncInbox] COMPANY_SNAPSHOT missing users/branches/settings');
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H3',
        location: 'sync_inbox_applier.dart:_applyCompanySnapshot',
        message: 'company_snapshot_payload_incomplete',
        data: <String, Object?>{
          'usersIsList': usersRaw is List,
          'branchesIsList': branchesRaw is List,
          'settingsIsMap': settingsRaw is Map,
        },
      );
      // #endregion
      return;
    }

    final users = usersRaw.map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    final branchesBare = branchesRaw.map((e) => BranchModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    final settingsModel = SettingsModel.fromJson(Map<String, dynamic>.from(settingsRaw));

    final terminalBid = parseIntLoose(payload['terminal_branch_id']);
    if (terminalBid != null &&
        terminalBid > 0 &&
        GetIt.instance.isRegistered<LocalHubSettings>()) {
      await GetIt.instance<LocalHubSettings>().setTerminalBranchId(terminalBid);
    }

    final inline = payload['branchImageInline'];
    final branches = inline is Map
        ? await _branchesWithInlineLogos(
            branchesBare,
            Map<dynamic, dynamic>.from(inline),
          )
        : branchesBare;

    final partnersRaw = payload['delivery_partners'];
    final partnerRows = <({int id, String name})>[];
    if (partnersRaw is List) {
      for (final row in partnersRaw) {
        if (row is! Map) continue;
        final m = Map<String, dynamic>.from(row);
        final id = parseIntLoose(m['id']);
        final name = m['name']?.toString().trim() ?? '';
        if (id != null && id > 0 && name.isNotEmpty) {
          partnerRows.add((id: id, name: name));
        }
      }
    }

    await db.transaction(() async {
      await _userRepo.saveUsersToLocal(users);
      await _branchRepo.saveBranchesToLocal(branches, downloadRemoteImages: false);
      await _settingsRepo.saveSettingsToLocal(settingsModel);
      if (partnerRows.isNotEmpty) {
        for (final p in partnerRows) {
          await db.deliveryPartnersDao.upsertDeliveryPartner(
            DeliveryPartnersCompanion.insert(
              id: Value(p.id),
              name: p.name,
            ),
          );
        }
      }
    });

    if (partnerRows.isNotEmpty) {
      DeliveryPartnerCatalogSignal.notifyPartnersChanged();
    }

    ordersLiveSync.notifyHubOrdersChanged();
    // #region agent log
    agentDebugLog(
      hypothesisId: 'H3',
      location: 'sync_inbox_applier.dart:_applyCompanySnapshot',
      message: 'company_snapshot_applied_ok',
      data: <String, Object?>{
        'savedUserCount': users.length,
        'savedBranchCount': branches.length,
        'savedDeliveryPartnerCount': partnerRows.length,
      },
    );
    // #endregion
  }

  Future<List<BranchModel>> _branchesWithInlineLogos(List<BranchModel> bare, Map<dynamic, dynamic> inline) async {
    final out = <BranchModel>[];
    for (final b in bare) {
      dynamic cell = inline[b.id] ?? inline['${b.id}'];
      if (cell is! Map) {
        out.add(b);
        continue;
      }
      final mime = cell['mime']?.toString();
      final b64 = cell['base64']?.toString();
      if (mime == null || b64 == null || b64.isEmpty) {
        out.add(b);
        continue;
      }
      try {
        final bytes = base64Decode(b64);
        if (bytes.isEmpty) {
          out.add(b);
          continue;
        }
        final media = await AppDirectories.media();
        final name = 'hub_branch_${b.id}_${const Uuid().v4()}${_extFromMimeForFile(mime)}';
        final f = File(p.join(media.path, name));
        await f.writeAsBytes(bytes, flush: true);
        out.add(b.copyWith(localImage: f.path));
      } catch (e, st) {
        if (kDebugMode) debugPrint('[SyncInbox] branch inline decode failed id=${b.id}: $e\n$st');
        out.add(b);
      }
    }
    return out;
  }

  static String _extFromMimeForFile(String mime) {
    switch (mime.toLowerCase().trim()) {
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'image/gif':
        return '.gif';
      case 'image/jpeg':
      case 'image/jpg':
        return '.jpg';
      default:
        return '.bin';
    }
  }

  Future<void> _applyApiMirror(Map<String, dynamic> payload) async {
    final path = payload['path']?.toString() ?? '';
    final body = payload['body'];
    final lp = path.toLowerCase();

    if (body is Map<String, dynamic> || body is Map) {
      final map = body is Map<String, dynamic> ? body : Map<String, dynamic>.from(body as Map);
      if (lp.contains('pull_records')) {
        await pullData.applyMirroredPullPage(map);
        ordersLiveSync.notifyHubOrdersChanged();
        return;
      }
      if (lp.contains('/sync/bootstrap') || lp.contains('bootstrap')) {
        try {
          final cdm = CompanyDataModel.fromJson(map);
          if (cdm.success != true || cdm.data.user.isEmpty || cdm.data.branch.isEmpty) {
            return;
          }
          await db.transaction(() async {
            await _userRepo.saveUsersToLocal(cdm.data.user);
            await _branchRepo.saveBranchesToLocal(
              cdm.data.branch,
              downloadRemoteImages: !settings.blocksTenantCloudRest,
            );
            await _settingsRepo.saveSettingsToLocal(cdm.data.settings);
          });
          ordersLiveSync.notifyHubOrdersChanged();
        } catch (_) {
          /* ignore malformed bootstrap mirror */
        }
        return;
      }
    }
  }

  static String _extFromMime(String? mime) {
    switch ((mime ?? '').toLowerCase().trim()) {
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'image/gif':
        return '.gif';
      case 'image/jpeg':
      case 'image/jpg':
        return '.jpg';
      default:
        return '.bin';
    }
  }

  /// Returns true when the local checkpoint was advanced.
  Future<bool> _applyDayClosingSettled(Map<String, dynamic> payload) async {
    final branchId = coerceUserId(payload['branchId']) ??
        coerceUserId(payload['branch_id']);
    if (branchId == null || branchId <= 0) return false;

    final atRaw = payload['lastSettledAt'] ?? payload['last_settled_at'];
    if (atRaw == null) return false;
    DateTime incoming;
    try {
      incoming = DateTime.parse(atRaw.toString());
    } catch (_) {
      return false;
    }

    final existing = await db.dayClosingCheckpointDao.lastSettledAtForBranch(branchId);
    if (existing != null && !incoming.isAfter(existing)) {
      return false;
    }

    await db.dayClosingCheckpointDao.upsertLastSettledAt(branchId, incoming);
    if (kDebugMode) {
      debugPrint(
        '[SyncInbox] DAY_CLOSING_SETTLED branch=$branchId '
        '${existing?.toIso8601String() ?? "null"} -> ${incoming.toIso8601String()}',
      );
    }
    return true;
  }

  int _hubPayloadUpdatedAtMs(Map<String, dynamic> payload) {
    final u = payload['updatedAt'];
    if (u is num) return u.toInt();
    return 0;
  }

  int _hubMetadataUpdatedAtMs(String? hubMetadataJson) {
    if (hubMetadataJson == null || hubMetadataJson.isEmpty) return 0;
    try {
      final root = jsonDecode(hubMetadataJson);
      if (root is Map<String, dynamic>) {
        final u = root['updatedAt'];
        if (u is num) return u.toInt();
      }
    } catch (_) {
      /* ignore */
    }
    return 0;
  }

  List<dynamic>? _snapshotItemsList(Map<String, dynamic> snap) {
    final items = snap['items'];
    if (items is List && items.isNotEmpty) return items;
    final meta = snap['metadata'];
    if (meta is Map) {
      final cl = meta['cart_lines'];
      if (cl is List && cl.isNotEmpty) return cl;
    }
    return null;
  }

  /// Dedicated cart per mirrored order (not the shared shadow cart) with lines from hub snapshot.
  Future<int> _syncMirroredCartLines({
    required String serverOrderId,
    required String invoice,
    required String? orderType,
    required int branchId,
    required Map<String, dynamic> snap,
    int? existingCartId,
  }) async {
    final shadowId = settings.shadowCartRowIdOrNull();
    final dedicatedInvoice = '_hub_$serverOrderId';
    var cartId = existingCartId;
    final dedicated = await db.cartsDao.getCartByInvoice(dedicatedInvoice);
    if (dedicated != null) {
      cartId = dedicated.id;
    } else if (cartId == null || (shadowId != null && cartId == shadowId)) {
      cartId = await db.cartsDao.createCart(
        dedicatedInvoice,
        orderType: orderType ?? 'take_away',
        branchId: branchId,
      );
    }

    final linesRaw = _snapshotItemsList(snap);
    if (linesRaw != null) {
      final existingLines = await db.cartsDao.getItemsByCart(cartId);
      for (final line in existingLines) {
        await db.cartsDao.removeCartItem(line.id);
      }
      final decoded = OrderLogCartFallback.decodeCartItemsFromItemsList(linesRaw, cartId);
      for (final line in decoded) {
        await db.cartsDao.addCartItem(
          CartItemsCompanion.insert(
            cartId: cartId,
            itemId: line.itemId,
            itemName: Value(line.itemName),
            itemVariantId: line.itemVariantId == null ? const Value.absent() : Value(line.itemVariantId),
            itemToppingId: line.itemToppingId == null ? const Value.absent() : Value(line.itemToppingId),
            quantity: line.quantity,
            total: Value(line.total),
            discount: Value(line.discount),
            discountType: line.discountType == null ? const Value.absent() : Value(line.discountType),
            notes: line.notes == null ? const Value.absent() : Value(line.notes),
          ),
        );
      }
    }
    return cartId;
  }

  double _finalFromSnapshot(Map<String, dynamic> snap) {
    final tc = snap['totalCents'];
    if (tc is num) return tc / 100.0;
    final meta = snap['metadata'];
    if (meta is Map<String, dynamic>) {
      final flutter = meta['flutter'];
      if (flutter is Map<String, dynamic>) {
        final fa = flutter['final_amount'];
        if (fa is num) return fa.toDouble();
      }
    }
    final flutterTop = snap['flutter'];
    if (flutterTop is Map<String, dynamic>) {
      final fa = flutterTop['final_amount'];
      if (fa is num) return fa.toDouble();
    }
    final faRoot = snap['final_amount'];
    if (faRoot is num) return faRoot.toDouble();
    final ta = snap['total_amount'];
    if (ta is num) return ta.toDouble();
    return 0;
  }

  Future<void> _upsertOrder(Map<String, dynamic> payload) async {
    final sid = payload['orderId']?.toString() ?? payload['serverOrderId']?.toString() ?? payload['id']?.toString();
    if (sid == null || sid.isEmpty) return;

    final snapRaw = payload['snapshot'];
    if (snapRaw is! Map) {
      if (kDebugMode) debugPrint('[SyncInbox] ORDER_* missing snapshot (serverOrderId=$sid)');
      return;
    }
    final snap = Map<String, dynamic>.from(snapRaw);

    final invoice = snap['invoice_number']?.toString() ?? sid;
    Map<String, dynamic>? flutterSnap;
    final meta = snap['metadata'];
    if (meta is Map<String, dynamic>) {
      flutterSnap = meta['flutter'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(meta['flutter'] as Map)
          : null;
    }
    String? cartTypeHint;
    final cartIdHint = parseIntLoose(snap['cart_id'] ?? snap['cartId'] ?? flutterSnap?['cart_id']);
    if (cartIdHint != null && cartIdHint > 0) {
      final cartRow = await db.cartsDao.getCartByCartId(cartIdHint);
      cartTypeHint = cartRow?.orderType;
    }
    final orderTypeRaw = resolveMirroredOrderType(
      snap: snap,
      flutterSnap: flutterSnap,
      cartOrderType: cartTypeHint,
    );
    final hubStatusRaw = snap['status']?.toString() ?? 'pending';
    final status = OrderPushStatus.localFromHub(
      orderType: orderTypeRaw,
      hubStatus: hubStatusRaw,
    );

    DateTime created;
    try {
      created = DateTime.parse(snap['created_at']?.toString() ?? '');
    } catch (_) {
      created = DateTime.now();
    }

    final finalAmt = _finalFromSnapshot(snap);
    final totalAmt =
        flutterSnap != null && flutterSnap['total_amount'] is num ? (flutterSnap['total_amount'] as num).toDouble() : finalAmt;

    var hubMeta = jsonEncode(payload);
    final routingAnchor = DineInRefParser.routingAnchorFromLanSnapshot(snap, flutterSnap);
    if (routingAnchor != null) {
      hubMeta = DineInRefParser.mergeHubMetadataAnchor(hubMeta, routingAnchor);
    }
    var existing = await db.ordersDao.getOrderByServerId(sid);
    final sess = await db.sessionDao.getActiveSession();
    final branchBid = resolveMirroredOrderBranchId(
      snap: snap,
      flutterSnap: flutterSnap,
      sessionBranchId: sess?.branchId,
    );
    if (branchBid <= 0) {
      if (kDebugMode) {
        debugPrint('[SyncInbox] ORDER_* skipped sid=$sid — no branch_id in snapshot or session');
      }
      return;
    }

    final ref =
        (flutterSnap?['reference_number'] ?? snap['reference_number'])?.toString();

    final mirroredUserId = coerceUserId(snap['user_id']) ??
        coerceUserId(flutterSnap?['user_id']);

    final mirroredExtra = _mirroredCustomerPaymentCompanion(snap, flutterSnap);

    // Avoid duplicate rows when MAIN hub upsert arrives before local row had [serverOrderId].
    if (existing == null && invoice.trim().isNotEmpty) {
      final byInvoice = await db.ordersDao.getKotByInvoiceAndBranch(invoice, branchId: branchBid) ??
          await db.ordersDao.findLocalOrderAwaitingHubLinkByInvoice(invoice, branchId: branchBid);
      if (byInvoice != null) {
        await db.ordersDao.setHubCorrelationIfUnset(orderId: byInvoice.id, correlationId: sid);
        existing = await db.ordersDao.getOrderById(byInvoice.id);
      }
    }

    final incomingMs = _hubPayloadUpdatedAtMs(payload);
    var stalePayload = false;
    var staleStatusWins = false;
    var staleDineInRoutingPatch = false;
    if (existing != null) {
      final existingMs = _hubMetadataUpdatedAtMs(existing.hubMetadata);
      if (incomingMs > 0 && existingMs > 0 && incomingMs < existingMs) {
        stalePayload = true;
        staleStatusWins = OrderPushStatus.incomingStatusShouldWin(
          currentLocal: existing.status,
          incomingMappedLocal: status,
        );
        if (orderTypeRaw == 'dine_in' && routingAnchor != null) {
          final currentRoute = DineInRefParser.dineInRoutingAnchorForMatching(existing);
          staleDineInRoutingPatch = currentRoute != routingAnchor;
        }
        if (!staleStatusWins && !staleDineInRoutingPatch) {
          if (kDebugMode) {
            debugPrint('[SyncInbox] ORDER_* ignored stale payload sid=$sid ($incomingMs < $existingMs)');
          }
          return;
        }
        if (kDebugMode) {
          debugPrint(
            '[SyncInbox] ORDER_* stale payload sid=$sid partial apply '
            '(statusWin=$staleStatusWins dineInRoute=$staleDineInRoutingPatch, $incomingMs < $existingMs)',
          );
        }
      }
    }

    final mirroredCartId = await _syncMirroredCartLines(
      serverOrderId: sid,
      invoice: invoice,
      orderType: orderTypeRaw,
      branchId: branchBid,
      snap: snap,
      existingCartId: existing?.cartId,
    );

    if (existing != null) {
      final priorStatus = existing.status;
      if (stalePayload) {
        await (db.update(db.orders)..where((o) => o.id.equals(existing!.id))).write(
          OrdersCompanion(
            status: staleStatusWins ? Value(status) : const Value.absent(),
            hubMetadata: Value(hubMeta),
          ),
        );
      } else {
        await (db.update(db.orders)..where((o) => o.id.equals(existing!.id))).write(
          mirroredExtra.copyWith(
            cartId: Value(mirroredCartId),
            invoiceNumber: Value(invoice),
            totalAmount: Value(totalAmt),
            finalAmount: Value(finalAmt),
            status: Value(status),
            orderType: orderTypeRaw != null ? Value(orderTypeRaw) : const Value.absent(),
            referenceNumber: ref != null && ref.isNotEmpty ? Value(ref) : const Value.absent(),
            userId: mirroredUserId != null ? Value(mirroredUserId) : const Value.absent(),
            hubMetadata: Value(hubMeta),
            branchId: Value(branchBid),
          ),
        );
      }
      // #region agent log
      if (orderTypeRaw == 'delivery' || orderTypeRaw == 'take_away') {
        agentDebugLog(
          hypothesisId: 'H5',
          location: 'sync_inbox_applier.dart:_upsertOrder',
          message: 'lan_order_mirror_status',
          data: <String, Object?>{
            'sid': sid,
            'invoice': invoice,
            'orderType': orderTypeRaw,
            'priorStatus': priorStatus,
            'incomingMappedStatus': status,
            'stalePayload': stalePayload,
            'staleStatusWins': staleStatusWins,
            'incomingMs': incomingMs,
            'existingMs': _hubMetadataUpdatedAtMs(existing.hubMetadata),
          },
        );
      }
      // #endregion
    } else {
      await db.into(db.orders).insert(
            OrdersCompanion.insert(
              cartId: mirroredCartId,
              invoiceNumber: invoice,
              branchId: Value(branchBid),
              referenceNumber:
                  ref != null && ref.isNotEmpty ? Value(ref) : const Value.absent(),
              totalAmount: totalAmt,
              finalAmount: finalAmt,
              createdAt: created,
              status: Value(status),
              orderType: Value(orderTypeRaw),
              userId: Value(mirroredUserId),
              serverOrderId: Value(sid),
              hubMetadata: Value(hubMeta),
              customerName: mirroredExtra.customerName,
              customerEmail: mirroredExtra.customerEmail,
              customerPhone: mirroredExtra.customerPhone,
              customerGender: mirroredExtra.customerGender,
              customerAddress: mirroredExtra.customerAddress,
              discountAmount: mirroredExtra.discountAmount,
              discountType: mirroredExtra.discountType,
              cashAmount: mirroredExtra.cashAmount,
              creditAmount: mirroredExtra.creditAmount,
              cardAmount: mirroredExtra.cardAmount,
              onlineAmount: mirroredExtra.onlineAmount,
              deliveryPartner: mirroredExtra.deliveryPartner,
              driverId: mirroredExtra.driverId,
              driverName: mirroredExtra.driverName,
              pickupToken: mirroredExtra.pickupToken,
            ),
          );
    }

    if (!settings.blocksTenantCloudRest) {
      final rowAfter = await db.ordersDao.getOrderByServerId(sid);
      if (rowAfter != null) {
        await enqueueOrderLogSnapshotForCloudPush(
          db: db,
          order: rowAfter,
          snapshotPayload: Map<String, dynamic>.from(snap),
        );
      }
    }
  }

  Future<void> _deleteEntity(Map<String, dynamic> payload) async {
    final entity = payload['entity']?.toString().toLowerCase() ?? '';
    final idStr = payload['id']?.toString();
    if (idStr == null || idStr.isEmpty) return;
    if (entity.contains('order')) {
      final trimmed = idStr.trim();
      if (trimmed.isEmpty) return;

      Order? o = await db.ordersDao.getOrderByServerId(trimmed);
      if (o == null) {
        // SUB-created rows often omit [server_order_id]; hub delete key is then the local SQLite id string.
        final asLocalId = int.tryParse(trimmed);
        if (asLocalId != null && asLocalId > 0) {
          final candidate = await db.ordersDao.getOrderById(asLocalId);
          final sid = (candidate?.serverOrderId ?? '').trim();
          if (candidate != null && sid.isEmpty) {
            o = candidate;
          }
        }
      }
      if (o != null) {
        await db.ordersDao.deleteOrderLogsForLocalOrderId(o.id);
        await db.ordersDao.deleteOrder(o.id);
      }
    }
  }
}
