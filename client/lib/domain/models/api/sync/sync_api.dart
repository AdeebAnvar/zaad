import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api_endpoints.dart';
import '../dio_client.dart';

class SyncApi {
  Future<Response> pullData([Map<String, dynamic>? queryParameters]) async {
    final dio = await DioClient.getInstance();
    final path = ApiEndpoints.pullData;
    final hasQuery = queryParameters != null && queryParameters.isNotEmpty;
    final requestPath = hasQuery ? '$path?${_buildQueryString(queryParameters)}' : path;
    if (kDebugMode) {
      debugPrint(
        '[SyncApi] GET ${dio.options.baseUrl}$path'
        '${queryParameters != null && queryParameters.isNotEmpty ? ' ?$queryParameters' : ''}',
      );
    }
    return dio.get(requestPath);
  }

  Future<Response> pushRecords(Map<String, dynamic> body) async {
    final dio = await DioClient.getInstance();
    final path = ApiEndpoints.pushRecords;
    if (kDebugMode) {
      final expenseCount =
          body['expenses'] is List ? (body['expenses'] as List).length : 0;
      debugPrint(
        '[SyncApi] POST ${dio.options.baseUrl}$path (push_records) expenses=$expenseCount',
      );
    }
    // Explicit JSON so `expenses[]` null fields are never dropped by serializers.
    return dio.post<String>(
      path,
      data: jsonEncode(body),
      options: Options(
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
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

  /// Build query manually so spaces are encoded as `%20` (not `+`).
  String _buildQueryString(Map<String, dynamic> params) {
    final pairs = <String>[];
    params.forEach((key, value) {
      if (value == null) return;
      final encodedKey = Uri.encodeQueryComponent(key);
      final encodedValue = Uri.encodeQueryComponent(value.toString());
      pairs.add('$encodedKey=$encodedValue');
    });
    return pairs.join('&');
  }
}
