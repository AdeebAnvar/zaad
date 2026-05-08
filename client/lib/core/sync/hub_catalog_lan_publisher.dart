import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pos/core/network/lan_hub_health.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/sync/hub_order_lan_publisher.dart';
import 'package:pos/core/sync/pos_sync_wire.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/domain/models/category_model.dart';
import 'package:pos/domain/models/item_model.dart';

/// After MAIN finishes a tenant pull + local image downloads, optionally mirror
/// categories + items (including **base64-encoded** images when on disk) to SUBs via Node MAIN.
///
/// Requires [LocalHubSettings.publishesCatalogAfterTenantPull], [hubWsUrl], and **`pos_local_role` ≠ hub_sub**.
class HubCatalogLanPublisher {
  HubCatalogLanPublisher._();

  static Future<void> publishAfterTenantPull({
    required AppDatabase db,
    required List<ItemCreatedUpdated> pulledItemsSnapshot,
  }) async {
    final g = GetIt.instance;
    if (!g.isRegistered<LocalHubSettings>()) return;

    final hub = g<LocalHubSettings>();

    // SUB terminals never publish catalog deltas.
    if (hub.blocksTenantCloudRest) return;
    if (!hub.publishesCatalogAfterTenantPull) return;

    final resolvedUrl = hub.publishHubWsUrlOrLoopback;
    if (resolvedUrl.isEmpty) {
      return;
    }

    if (await LanHeavyMirrorGate.shouldSkipForSolitaryWsHub(hub)) {
      if (kDebugMode) {
        debugPrint(
          '[HubCatalogLanPublisher] skip: hub reports ≤1 open WS client (solitary MAIN — toggle in LAN hub settings)',
        );
      }
      return;
    }

    try {
      final cats = await db.pullDataDao.lanPublishMirrorCategories();
      if (cats.isEmpty && pulledItemsSnapshot.isEmpty) return;

      for (final row in cats) {
        await _sleepBetweenFrames();
        await HubOrderLanPublisher.enqueueMainEventWithQueue(
          type: PosSyncEventTypes.categoryUpsert,
          payload: {
            'pullCategoryJson': _categoryMirrorToApiJson(row),
            'updatedAt': row.updatedAt.millisecondsSinceEpoch,
          },
        );
      }

      for (final e in pulledItemsSnapshot) {
        await _sleepBetweenFrames();
        final payload = await _payloadForItem(db, e);
        await HubOrderLanPublisher.enqueueMainEventWithQueue(
          type: PosSyncEventTypes.itemUpsert,
          payload: payload,
        );
      }

      if (kDebugMode) {
        debugPrint(
          '[HubCatalogLanPublisher] queued ${cats.length} categories + ${pulledItemsSnapshot.length} items for ACK-backed outbox',
        );
      }
    } catch (e, st) {
      if (kDebugMode) debugPrint('[HubCatalogLanPublisher] failed: $e\n$st');
    }
  }

  static Map<String, dynamic> _categoryMirrorToApiJson(PullCategoryRow row) {
    final m = CategoryCreatedUpdated(
      id: row.id,
      uuid: row.uuid,
      branchId: row.branchId,
      categoryName: row.categoryName,
      categorySlug: row.categorySlug,
      otherName: row.otherName,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      deletedAt: row.deletedAt,
    ).toJson();
    return Map<String, dynamic>.from(m);
  }

  static Future<Map<String, dynamic>> _payloadForItem(AppDatabase db, ItemCreatedUpdated e) async {
    final out = <String, dynamic>{
      'pullItemJson': e.toJson(),
      'updatedAt': e.updatedAt.millisecondsSinceEpoch,
    };

    final cached = await db.itemDao.getItemById(e.id);
    final local = cached?.localImagePath?.trim();

    if (local != null && local.isNotEmpty) {
      try {
        final f = File(local);
        if (await f.exists()) {
          final len = await f.length();
          if (len > 0 && len < 14 * 1024 * 1024) {
            out['imageInline'] = <String, dynamic>{
              'mime': _guessMime(local),
              'base64': base64Encode(await f.readAsBytes()),
            };
          } else if (kDebugMode && len >= 14 * 1024 * 1024) {
            debugPrint('[HubCatalogLanPublisher] skip inline image (${len}b) item ${e.id} — increase WS_MAX_PAYLOAD_BYTES');
          }
        }
      } catch (_) {
        /* keep pullItemJson only */
      }
    }

    return out;
  }

  static String _guessMime(String absolutePath) {
    final lower = absolutePath.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  /// Slightly spaced frames reduce Windows TCP / hub overload (errno 121) when mirroring many items.
  static Future<void> _sleepBetweenFrames() => Future<void>.delayed(const Duration(milliseconds: 35));
}
