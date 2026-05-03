import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// LAN hub Bearer token persisted with [FlutterSecureStorage] (matches `Authorization: Bearer` on Node).
class PosHubAuth {
  /// Same key used by tooling that avoids GetIt bootstrap ordering (see [SyncApi] tunnel transport).
  static const bearerStorageKey = 'pos_hub_bearer_token';

  PosHubAuth(this._secure);

  final FlutterSecureStorage _secure;
  String? _memo;

  Future<String?> bearerToken() async {
    final v = _memo ?? await _secure.read(key: bearerStorageKey);
    _memo = v;
    final t = (v ?? '').trim();
    return t.isEmpty ? null : t;
  }

  /// Call from your settings/onboarding UI once hub token is provisioned into `installer/config.sample.json`.
  Future<void> setBearerToken(String token) async {
    final t = token.trim();
    _memo = t;
    await _secure.write(key: bearerStorageKey, value: t);
  }

  Future<void> clear() async {
    _memo = null;
    await _secure.delete(key: bearerStorageKey);
  }
}
