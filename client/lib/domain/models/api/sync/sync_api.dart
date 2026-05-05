import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api_endpoints.dart';
import '../dio_client.dart';

class SyncApi {
  Future<Response> pullData([Map<String, dynamic>? queryParameters]) async {
    final dio = await DioClient.getInstance();
    final path = ApiEndpoints.pullData;
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
    final dio = await DioClient.getInstance();
    final path = ApiEndpoints.pushRecords;
    if (kDebugMode) {
      debugPrint('[SyncApi] POST ${dio.options.baseUrl}$path (push_records)');
    }
    return dio.post(
      path,
      data: body,
    );
  }

  /// Company identity for MAIN (users, branches, settings). Successful responses are mirrored
  /// to LAN SUBs by [DioClient] → [HubApiMirrorPublisher] as `API_MIRROR` (bootstrap path).
  Future<Response> fetchBootstrap() async {
    final dio = await DioClient.getInstance();
    final path = ApiEndpoints.getCompanyData;
    if (kDebugMode) {
      debugPrint('[SyncApi] GET ${dio.options.baseUrl}$path (bootstrap → LAN mirror)');
    }
    return dio.get(path);
  }
}
