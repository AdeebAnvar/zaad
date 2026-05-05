import 'package:shared_preferences/shared_preferences.dart';

import 'local_hub_settings.dart';

/// Thrown when SUB tries tenant cloud pull/push/Dio.
class TenantCloudDisabledOnLanSubException implements Exception {
  TenantCloudDisabledOnLanSubException([
    this.message = 'This device is a LAN SUB cashier. Company cloud sync is disabled; '
        'data flows only through the MAIN POS hub (WebSocket).',
  ]);

  final String message;

  @override
  String toString() => message;
}

/// Ensures prefs allow HTTP calls to pull/push APIs before [SyncApi] runs.
///
/// On LAN SUB (`pos_local_role == hub_sub`), tenant REST is always forbidden.
Future<void> assertTenantCloudSyncConfigured() async {
  final prefs = await SharedPreferences.getInstance();
  if (LocalHubSettings.readIsHubSub(prefs)) {
    throw TenantCloudDisabledOnLanSubException();
  }
  final base = (prefs.getString('baseUrl') ?? '').trim();
  if (base.isEmpty) {
    throw Exception(
      'No tenant API URL. On the login screen tap “Connect to server”, enter your '
      'company link code, wait until it succeeds, then sync. '
      '(Not available on LAN SUB devices — use MAIN to connect, then receive data from the hub.)',
    );
  }
}
