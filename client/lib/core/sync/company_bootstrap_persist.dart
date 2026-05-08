import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/sync/hub_company_snapshot_publisher.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/branch_repository.dart';
import 'package:pos/data/repository/settings_repository.dart';
import 'package:pos/data/repository/user_repository.dart';
import 'package:pos/domain/models/company_data.dart';

/// Applies `/sync/bootstrap`-shaped JSON to MAIN Drift, then broadcasts [COMPANY_SNAPSHOT] over the hub WS
/// (users include [UserModel.permissions] as in the tenant response).
///
/// Mirrors what SUB terminals apply via [SyncInboxApplier._applyApiMirror] for bootstrap [API_MIRROR]
/// payloads — MAIN previously only forwarded the mirror and did **not** refresh local identity rows until now.
Future<void> persistCompanyBootstrapFromApiBody(
  dynamic body, {
  bool broadcastToLanHub = true,
}) async {
  final g = GetIt.instance;
  if (!g.isRegistered<UserRepository>() ||
      !g.isRegistered<BranchRepository>() ||
      !g.isRegistered<SettingsRepository>() ||
      !g.isRegistered<AppDatabase>()) {
    return;
  }

  Map<String, dynamic>? raw;
  if (body is Map<String, dynamic>) {
    raw = body;
  } else if (body is Map) {
    raw = Map<String, dynamic>.from(body);
  }
  if (raw == null) return;

  final CompanyDataModel cdm;
  try {
    cdm = CompanyDataModel.fromJson(raw);
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[company_bootstrap_persist] skip parse: $e\n$st');
    }
    return;
  }

  if (cdm.success != true || cdm.data.user.isEmpty || cdm.data.branch.isEmpty) {
    return;
  }

  final db = g<AppDatabase>();
  final userRepo = g<UserRepository>();
  final branchRepo = g<BranchRepository>();
  final settingsRepo = g<SettingsRepository>();

  final bool downloadImages =
      !(g.isRegistered<LocalHubSettings>() && g<LocalHubSettings>().blocksTenantCloudRest);

  try {
    await db.transaction(() async {
      await userRepo.saveUsersToLocal(cdm.data.user);
      await branchRepo.saveBranchesToLocal(cdm.data.branch, downloadRemoteImages: downloadImages);
      await settingsRepo.saveSettingsToLocal(cdm.data.settings);
    });

    if (broadcastToLanHub) {
      await HubCompanySnapshotPublisher.broadcastAfterTenantLink(db);
    }
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[company_bootstrap_persist] apply failed: $e\n$st');
    }
  }
}
