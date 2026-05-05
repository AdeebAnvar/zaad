import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/sync/cloud_order_push_queue.dart';
import 'package:pos/core/sync/pos_sync_wire.dart';
import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/branch_repository.dart';
import 'package:pos/data/repository/pull_data_repository.dart';
import 'package:pos/data/repository/settings_repository.dart';
import 'package:pos/data/repository/user_repository.dart';
import 'package:pos/domain/models/branch_model.dart';
import 'package:pos/domain/models/category_model.dart';
import 'package:pos/domain/models/company_Data.dart';
import 'package:pos/domain/models/item_model.dart';
import 'package:pos/domain/models/settings_model.dart';
import 'package:pos/domain/models/user_model.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';
import 'package:pos/features/orders/data/order_push_status.dart';
import 'package:uuid/uuid.dart';

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
  })  : _userRepo = userRepo,
        _branchRepo = branchRepo,
        _settingsRepo = settingsRepo;

  final AppDatabase db;
  final LocalHubSettings settings;
  final HubOrdersLiveSync ordersLiveSync;
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
  }

  Future<void> _applyCompanySnapshot(Map<String, dynamic> payload) async {
    final usersRaw = payload['users'];
    final branchesRaw = payload['branches'];
    final settingsRaw = payload['settings'];
    if (usersRaw is! List || branchesRaw is! List || settingsRaw is! Map) {
      if (kDebugMode) debugPrint('[SyncInbox] COMPANY_SNAPSHOT missing users/branches/settings');
      return;
    }

    final users = usersRaw.map((e) => UserModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    final branchesBare = branchesRaw.map((e) => BranchModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    final settingsModel = SettingsModel.fromJson(Map<String, dynamic>.from(settingsRaw));

    final inline = payload['branchImageInline'];
    final branches = inline is Map
        ? await _branchesWithInlineLogos(
            branchesBare,
            Map<dynamic, dynamic>.from(inline),
          )
        : branchesBare;

    await db.transaction(() async {
      await _userRepo.saveUsersToLocal(users);
      await _branchRepo.saveBranchesToLocal(branches, downloadRemoteImages: false);
      await _settingsRepo.saveSettingsToLocal(settingsModel);
    });

    ordersLiveSync.notifyHubOrdersChanged();
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

  Future<int> _ensureShadowCart() async {
    final cached = settings.shadowCartRowIdOrNull();
    if (cached != null) {
      final row = await db.cartsDao.getCartByCartId(cached);
      if (row != null) return cached;
    }
    final cid = await db.cartsDao.createCart('_hub_shadow_cart', orderType: 'take_away');
    await settings.cacheShadowCartId(cid);
    return cid;
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
    final ot = snap['order_type']?.toString();
    Map<String, dynamic>? flutterSnap;
    final meta = snap['metadata'];
    if (meta is Map<String, dynamic>) {
      flutterSnap = meta['flutter'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(meta['flutter'] as Map)
          : null;
    }
    final orderTypeRaw = ot ?? flutterSnap?['order_type']?.toString();
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

    final hubMeta = jsonEncode(payload);
    final existing = await db.ordersDao.getOrderByServerId(sid);

    final ref =
        (flutterSnap?['reference_number'] ?? snap['reference_number'])?.toString();

    if (existing != null) {
      await (db.update(db.orders)..where((o) => o.serverOrderId.equals(sid))).write(
        OrdersCompanion(
          invoiceNumber: Value(invoice),
          totalAmount: Value(totalAmt),
          finalAmount: Value(finalAmt),
          status: Value(status),
          orderType: orderTypeRaw != null ? Value(orderTypeRaw) : const Value.absent(),
          referenceNumber: ref != null && ref.isNotEmpty ? Value(ref) : const Value.absent(),
          hubMetadata: Value(hubMeta),
        ),
      );
    } else {
      final sess = await db.sessionDao.getActiveSession();
      final branchBid = sess?.branchId ?? 1;
      final cartId = await _ensureShadowCart();
      await db.into(db.orders).insert(
            OrdersCompanion.insert(
              cartId: cartId,
              invoiceNumber: invoice,
              branchId: Value(branchBid),
              referenceNumber:
                  ref != null && ref.isNotEmpty ? Value(ref) : const Value.absent(),
              totalAmount: totalAmt,
              finalAmount: finalAmt,
              createdAt: created,
              status: Value(status),
              orderType: orderTypeRaw != null ? Value(orderTypeRaw) : const Value.absent(),
              serverOrderId: Value(sid),
              hubMetadata: Value(hubMeta),
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
      final o = await db.ordersDao.getOrderByServerId(idStr);
      if (o != null) {
        await db.ordersDao.deleteOrderLogsForLocalOrderId(o.id);
        await db.ordersDao.deleteOrder(o.id);
      }
    }
  }
}
