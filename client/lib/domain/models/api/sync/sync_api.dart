import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pos/core/network/cloud_sync_prerequisites.dart';
import 'package:pos/core/network/pos_hub_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api_endpoints.dart';
import '../dio_client.dart';

class SyncApi {
  static const bool _kCloudSyncViaLanHub = kCloudSyncViaLanHub;

  String _effectivePath(String cloudAbsolutePath) {
    if (!_kCloudSyncViaLanHub) return cloudAbsolutePath;
    if (!cloudAbsolutePath.startsWith('/')) {
      return '/sync/proxy/$cloudAbsolutePath';
    }
    return '/sync/proxy$cloudAbsolutePath';
  }

  Future<Dio> _dioForTenantSync() async {
    if (!_kCloudSyncViaLanHub) return DioClient.getInstance();

    final prefs = await SharedPreferences.getInstance();
    final hub = (prefs.getString('pos_server_base_url') ?? '').trim();

    const secure = FlutterSecureStorage();
    final bearer =
        (await secure.read(key: PosHubAuth.bearerStorageKey))?.trim() ?? '';

    if (hub.isEmpty || bearer.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[SyncApi] CLOUD_SYNC_VIA_NODE=true but hub URL or hub bearer missing — falling back to direct cloud Dio.',
        );
      }
      return DioClient.getInstance();
    }

    return DioClient.getSyncTransport(hubAuthorizationBearer: bearer);
  }

  /// Fetches pull/sync data. The backend is expected to support pagination via
  /// query parameters (e.g. `page`, `module`) when requesting one resource at a time;
  /// see [PullDataRepositoryImpl] and [ApiEndpoints].
  Future<Response> pullData([Map<String, dynamic>? queryParameters]) async {
    final dio = await _dioForTenantSync();
    final path = _effectivePath(ApiEndpoints.pullData);
    if (kDebugMode) {
      debugPrint(
        '[SyncApi] GET ${dio.options.baseUrl}$path'
        '${queryParameters != null && queryParameters.isNotEmpty ? ' ?$queryParameters' : ''}',
      );
    }
    return dio.get(
      path,
      queryParameters: (queryParameters == null || queryParameters.isEmpty) ? null : queryParameters,
    );
  }

  Future<Response> pushRecords(Map<String, dynamic> body) async {
    final dio = await _dioForTenantSync();
    final path = _effectivePath(ApiEndpoints.pushRecords);
    if (kDebugMode) {
      debugPrint('[SyncApi] POST ${dio.options.baseUrl}$path (push_records)');
    }
    return dio.post(
      path,
      data: body,
    );
  }
}
