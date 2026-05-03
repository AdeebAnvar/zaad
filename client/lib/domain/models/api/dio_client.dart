import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  static Dio? _dio;

  static const String _authHeaderKey = 'X-Auth-Key';
  static const String _authHeaderValue = 'd0ff75bf-77e6-4032-a7d4-9061ddd89752';

  static String _trimTrailingSlash(String s) =>
      s.replaceFirst(RegExp(r'/+$'), '');

  static void _maybeAttachLogger(Dio dio) {
    final hasPrettyLogger = dio.interceptors.any(
      (interceptor) => interceptor is PrettyDioLogger,
    );
    if (hasPrettyLogger) return;
    if (kReleaseMode) return;
    dio.interceptors.add(
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        compact: true,
        maxWidth: 90,
      ),
    );
  }

  /// When `--dart-define=CLOUD_SYNC_VIA_NODE=true`, pull/push [SyncApi] targets the LAN hub
  /// (`/sync/proxy/…`) instead of hitting the tenant URL in prefs — Node performs cloud IO.
  ///
  /// The hub protects `/sync/**` routes with the usual `Authorization: Bearer` — pass
  /// [hubAuthorizationBearer] (plain token or prefixed with `Bearer `).
  static Future<Dio> getSyncTransport({
    String? overrideBaseUrl,
    String? hubAuthorizationBearer,
  }) async {
    if (overrideBaseUrl != null && overrideBaseUrl.isNotEmpty) {
      return getInstance(overrideBaseUrl: overrideBaseUrl);
    }

    const tunnel = bool.fromEnvironment('CLOUD_SYNC_VIA_NODE', defaultValue: false);
    if (!tunnel) return getInstance();

    final prefs = await SharedPreferences.getInstance();
    final tunnelBase = (prefs.getString('pos_server_base_url') ?? '').trim();
    if (tunnelBase.isEmpty) {
      return getInstance();
    }

    final dio = Dio(
      BaseOptions(
        baseUrl: _trimTrailingSlash(tunnelBase),
        headers: {_authHeaderKey: _authHeaderValue},
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    final b = hubAuthorizationBearer?.trim();
    if (b != null && b.isNotEmpty) {
      dio.options.headers['Authorization'] =
          b.startsWith('Bearer ') ? b : 'Bearer $b';
    }

    _maybeAttachLogger(dio);
    return dio;
  }

  static Future<Dio> getInstance({String? overrideBaseUrl}) async {
    _dio ??= Dio();
    if (overrideBaseUrl != null) {
      _dio!.options.baseUrl = overrideBaseUrl;
    } else {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String baseUrl = prefs.getString('baseUrl') ?? "";
      _dio!.options.baseUrl = baseUrl;
    }
    _dio!.options.headers = {_authHeaderKey: _authHeaderValue};
    _dio!.options.connectTimeout = const Duration(seconds: 30);
    _dio!.options.receiveTimeout = const Duration(seconds: 30);

    _maybeAttachLogger(_dio!);

    return _dio!;
  }
}
