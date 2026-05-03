import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Stable device UUID for LAN hub attribution (`POST /orders` payload `device.id`).
class PosHubDeviceIdentity {
  static const _key = 'pos_hub_device_uuid';

  final SharedPreferences _prefs;
  PosHubDeviceIdentity(this._prefs);

  static Future<PosHubDeviceIdentity> load(SharedPreferences prefs) async =>
      PosHubDeviceIdentity(prefs);

  Future<String> getOrCreateUuid() async {
    var id = _prefs.getString(_key);
    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
      await _prefs.setString(_key, id);
    }
    return id;
  }
}
