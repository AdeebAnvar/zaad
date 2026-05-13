import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/cloud_sync_prerequisites.dart';
import '../../../core/network/dio_bad_api_status_interceptor.dart';
import '../../../core/network/local_hub_settings.dart';
import '../../../core/sync/hub_api_mirror_publisher.dart';

class DioClient {
  static Dio? _dio;
  static bool _lanSubBlockInterceptorAdded = false;
  static bool _apiMirrorInterceptorAdded = false;
  static bool _badApiStatusInterceptorAdded = false;

  static const String _authHeaderKey = 'X-Auth-Key';
  static const String _authHeaderValue = 'd0ff75bf-77e6-4032-a7d4-9061ddd89752';

  static String _trimTrailingSlash(String s) => s.replaceFirst(RegExp(r'/+$'), '');

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

  static Future<Dio> getInstance({String? overrideBaseUrl}) async {
    _dio ??= Dio();
    if (overrideBaseUrl != null) {
      _dio!.options.baseUrl = _trimTrailingSlash(overrideBaseUrl);
    } else {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('baseUrl') ?? '';

      _dio!.options.baseUrl = _trimTrailingSlash(baseUrl);
    }
    _dio!.options.headers = {_authHeaderKey: _authHeaderValue};
    _dio!.options.connectTimeout = const Duration(seconds: 30);
    _dio!.options.receiveTimeout = const Duration(seconds: 30);

    _maybeAttachLogger(_dio!);
    _attachLanSubTenantBlocker(_dio!);
    _attachApiMirrorInterceptor(_dio!);
    _attachBadApiStatusInterceptor(_dio!);

    return _dio!;
  }

  /// Broadcast successful JSON tenant responses from MAIN → hub → SUB DB applier.
  static void _maybeScheduleApiMirror(Response<dynamic> response) {
    if (response.statusCode == null || response.statusCode! < 200 || response.statusCode! >= 300) {
      return;
    }
    if (!GetIt.instance.isRegistered<LocalHubSettings>()) return;
    final hub = GetIt.instance<LocalHubSettings>();
    if (hub.blocksTenantCloudRest) {
      return;
    }
    if (hub.publishHubWsUrlOrLoopback.isEmpty) {
      return;
    }
    final data = response.data;
    if (data is! Map && data is! List) return;
    HubApiMirrorPublisher.scheduleMirror(
      path: response.requestOptions.path,
      method: response.requestOptions.method,
      statusCode: response.statusCode ?? 200,
      body: data,
    );
  }

  static void _attachApiMirrorInterceptor(Dio dio) {
    if (_apiMirrorInterceptorAdded) return;
    _apiMirrorInterceptorAdded = true;
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          Future.microtask(() => _maybeScheduleApiMirror(response));
          handler.next(response);
        },
      ),
    );
  }

  static void _attachBadApiStatusInterceptor(Dio dio) {
    if (_badApiStatusInterceptorAdded) return;
    _badApiStatusInterceptorAdded = true;
    dio.interceptors.add(DioBadApiStatusInterceptor.instance);
  }

  static void _attachLanSubTenantBlocker(Dio dio) {
    if (_lanSubBlockInterceptorAdded) return;
    _lanSubBlockInterceptorAdded = true;
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          if (LocalHubSettings.readIsHubSub(prefs)) {
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.cancel,
                error: TenantCloudDisabledOnLanSubException(),
                message: 'Tenant HTTP blocked: LAN SUB terminal (use MAIN hub WebSocket only).',
              ),
            );
          }
          handler.next(options);
        },
      ),
    );
  }
}
