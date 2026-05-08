import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Applies optional relaxed TLS validation on the shared [Dio] instance.
///
/// When [allow] is true, all server certificates are accepted (`badCertificateCallback`
/// always returns true). **Insecure** — only for debug or controlled environments;
/// use [DioClient.prefAllowInsecureTls] / fixing CA chain on the server for production.
void applyRelaxedTlsIfEnabled(Dio dio, {required bool allow}) {
  dio.httpClientAdapter = IOHttpClientAdapter(
    createHttpClient: () {
      final client = HttpClient();
      if (allow) {
        client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      }
      return client;
    },
  );
}
