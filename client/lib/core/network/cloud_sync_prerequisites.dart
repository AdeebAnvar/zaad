import 'package:pos/core/config/lan_pos_role.dart';
import 'package:pos/core/config/pos_app_runtime_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mirrors [SyncApi] tunnel flag — direct tenant HTTPS vs hub `/sync/proxy`.
const bool kCloudSyncViaLanHub =
    bool.fromEnvironment('CLOUD_SYNC_VIA_NODE', defaultValue: false);

/// Ensures prefs/env allow HTTP calls to pull/push APIs before [SyncApi] runs.
///
/// Without this, Dio may use an empty [baseUrl] (requests never reach suite.zaad…).
Future<void> assertTenantCloudSyncConfigured() async {
  final prefs = await SharedPreferences.getInstance();

  final role = parseLanPosRole(prefs.getString(PosAppRuntimeConfig.keyLanPosRole));
  if (role == LanPosRole.satellite) {
    throw Exception(
      'This terminal is set as a sub device — it cannot call the cloud API directly. '
      'Use Local POS, point to the main PC, and run cloud sync only on the Node server.',
    );
  }

  if (kCloudSyncViaLanHub) {
    final hub = (prefs.getString('pos_server_base_url') ?? '').trim();
    if (hub.isEmpty) {
      throw Exception(
        'Cloud sync is set to use the LAN hub (CLOUD_SYNC_VIA_NODE), but '
        'no hub URL is saved. Set Deployment / LAN hub URL, or build without that define '
        'to call the tenant URL directly.',
      );
    }
    return;
  }

  final base = (prefs.getString('baseUrl') ?? '').trim();
  if (base.isEmpty) {
    throw Exception(
      'No tenant API URL. On the login screen tap “Connect to server”, enter your '
      'company link code, wait until it succeeds, then sync.',
    );
  }
}
