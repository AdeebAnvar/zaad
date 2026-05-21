import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pos/core/debug/agent_debug_log.dart';
import 'package:pos/core/auth/terminal_branch_scope.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/sync/hub_order_lan_publisher.dart';
import 'package:pos/core/sync/pos_sync_wire.dart';
import 'package:pos/core/utils/image_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/domain/models/branch_model.dart';

/// After MAIN successfully links the tenant ([connectToServer]), push users/branches/settings
/// to the Node hub so SUB devices can log in locally without tenant REST.
///
/// Branch logos are inlined as base64 (+ mime) so SUBs never HTTP-download tenant images.
class HubCompanySnapshotPublisher {
  HubCompanySnapshotPublisher._();

  static const _maxBranchImageBytes = 4 * 1024 * 1024;

  static Future<void> broadcastAfterTenantLink(AppDatabase db) async {
    final g = GetIt.instance;
    if (!g.isRegistered<LocalHubSettings>()) {
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H1',
        location: 'hub_company_snapshot_publisher.dart:broadcastAfterTenantLink',
        message: 'early_return_no_LocalHubSettings',
        data: const <String, Object?>{},
      );
      // #endregion
      return;
    }

    final hub = g<LocalHubSettings>();
    final resolvedUrl = hub.publishHubWsUrlOrLoopback;

    if (hub.blocksTenantCloudRest) {
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H1',
        location: 'hub_company_snapshot_publisher.dart:broadcastAfterTenantLink',
        message: 'skip_blocksTenantCloudRest_MAIN_is_SUB',
        data: const <String, Object?>{},
      );
      // #endregion
      return;
    }
    if (resolvedUrl.isEmpty) {
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H1',
        location: 'hub_company_snapshot_publisher.dart:broadcastAfterTenantLink',
        message: 'skip_empty_resolvedUrl',
        data: const <String, Object?>{},
      );
      // #endregion
      return;
    }

    // Never skip COMPANY_SNAPSHOT when the hub is solitary: SUB tablets need users/branches
    // in Drift before they can log in. Catalog mirrors still use [LanHeavyMirrorGate].

    final allUsers = await db.usersDao.getAllUsers();
    final allBranches = await db.branchesDao.getAllBranches();
    final settings = await db.settingsDao.getSettings();
    final deliveryPartners = await db.deliveryPartnersDao.getAll();
    final terminalBranchId = await _resolveSnapshotBranchId(db, hub);
    final users = terminalBranchId == null
        ? allUsers
        : TerminalBranchScope.filterUsers(allUsers, terminalBranchId);
    final branches = terminalBranchId == null
        ? allBranches
        : TerminalBranchScope.filterBranches(allBranches, terminalBranchId);
    if (users.isEmpty || branches.isEmpty || settings == null) {
      if (kDebugMode) {
        debugPrint(
          '[HubCompanySnapshotPublisher] skip: incomplete local data users=${users.length} branches=${branches.length} settings=${settings != null}',
        );
      }
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H1',
        location: 'hub_company_snapshot_publisher.dart:broadcastAfterTenantLink',
        message: 'skip_incomplete_local_company_data',
        data: <String, Object?>{
          'userCount': users.length,
          'branchCount': branches.length,
          'hasSettings': settings != null,
        },
      );
      // #endregion
      return;
    }

    final branchImageInline = await _branchImagesPayload(branches);

    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final payload = <String, dynamic>{
        'users': users.map((u) => u.toJson()).toList(),
        'branches': branches.map((b) => b.toJson()).toList(),
        'settings': settings.toJson(),
        'delivery_partners': deliveryPartners
            .map((p) => <String, dynamic>{'id': p.id, 'name': p.name})
            .toList(),
        'updatedAt': nowMs,
        if (terminalBranchId != null) 'terminal_branch_id': terminalBranchId,
      };
      if (branchImageInline.isNotEmpty) {
        payload['branchImageInline'] = branchImageInline;
      }

      await HubOrderLanPublisher.enqueueMainEventWithQueue(
        type: PosSyncEventTypes.companySnapshot,
        payload: payload,
      );
      if (kDebugMode) {
        debugPrint(
          '[HubCompanySnapshotPublisher] queued COMPANY_SNAPSHOT (${users.length} users, ${branches.length} branches, ${deliveryPartners.length} delivery partners, ${branchImageInline.length} branch images)',
        );
      }
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H1',
        location: 'hub_company_snapshot_publisher.dart:broadcastAfterTenantLink',
        message: 'company_snapshot_queued_ok',
        data: <String, Object?>{
          'userCount': users.length,
          'branchCount': branches.length,
          'branchInlineKeys': branchImageInline.length,
          'deliveryPartnerCount': deliveryPartners.length,
        },
      );
      // #endregion
    } catch (e, st) {
      if (kDebugMode) debugPrint('[HubCompanySnapshotPublisher] failed: $e\n$st');
      // #region agent log
      agentDebugLog(
        hypothesisId: 'H1',
        location: 'hub_company_snapshot_publisher.dart:broadcastAfterTenantLink',
        message: 'company_snapshot_enqueue_exception',
        data: <String, Object?>{
          'errorType': e.runtimeType.toString(),
        },
      );
      // #endregion
    }
  }

  /// Re-push company identity after MAIN login sets [LocalHubSettings.terminalBranchId].
  static Future<void> broadcastForTerminalBranch(AppDatabase db) =>
      broadcastAfterTenantLink(db);

  static Future<int?> _resolveSnapshotBranchId(AppDatabase db, LocalHubSettings hub) async {
    final locked = hub.terminalBranchId;
    if (locked != null && locked > 0) return locked;
    final sess = await db.sessionDao.getActiveSession();
    if (sess != null && sess.branchId > 0) return sess.branchId;
    return null;
  }

  static Future<Map<String, Map<String, String>>> _branchImagesPayload(List<BranchModel> branches) async {
    final out = <String, Map<String, String>>{};
    for (final b in branches) {
      try {
        List<int>? bytes;
        String? mime;
        final lp = b.localImage.trim();
        if (lp.isNotEmpty) {
          final f = File(lp);
          if (await f.exists()) {
            final len = await f.length();
            if (len > 0 && len <= _maxBranchImageBytes) {
              bytes = await f.readAsBytes();
              mime = _guessMime(lp);
            }
          }
        }
        if ((bytes == null || bytes.isEmpty) && b.image.trim().isNotEmpty) {
          final path = await ImageUtils.downloadImage(
            b.image,
            'hub_snap_branch_${b.id}',
          );
          if (path != null && path.isNotEmpty) {
            final f = File(path);
            if (await f.exists()) {
              final len = await f.length();
              if (len > 0 && len <= _maxBranchImageBytes) {
                bytes = await f.readAsBytes();
                mime = _guessMime(path);
              }
            }
          }
        }
        if (bytes != null && mime != null && bytes.isNotEmpty) {
          out['${b.id}'] = {
            'mime': mime,
            'base64': base64Encode(bytes),
          };
        }
      } catch (_) {
        /* one branch skipped */
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
}
