import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pos/domain/models/api/network_exceptions.dart';

/// Single-line summary for logging (no headers).
String describePrimarySupportLine(Object error) => _describePrimaryError(error);

/// Message for the login “Could not connect” dialog: API/tenant errors stay readable;
/// other failures still get full support detail including stack.
String userFacingConnectErrorMessage(Object error, StackTrace stack) {
  if (error is NetworkExceptions) {
    final m = error.message.trim();
    if (m.isNotEmpty) {
      return m;
    }
    return describeErrorForSupportDialog(error, stack);
  }
  return describeErrorForSupportDialog(error, stack);
}

/// Multi-line text for support / field debugging (release-safe: no auth headers).
String describeErrorForSupportDialog(Object error, StackTrace stack) {
  final primary = _describePrimaryError(error);
  final stackStr = stack.toString();
  final lines = stackStr.split('\n');
  const maxFrames = kReleaseMode ? 14 : 40;
  final truncated = lines.length > maxFrames
      ? '${lines.take(maxFrames).join('\n')}\n… (${lines.length - maxFrames} more frames)'
      : stackStr;
  return '$primary\n\n$truncated'.trim();
}

String _describePrimaryError(Object error) {
  if (error is NetworkExceptions) {
    return 'NetworkExceptions: ${error.message}';
  }
  if (error is DioException) {
    final buf = StringBuffer('DioException [${error.type.name}]');
    final m = error.message?.trim();
    if (m != null && m.isNotEmpty) {
      buf.write(': $m');
    }
    final code = error.response?.statusCode;
    if (code != null) {
      buf.write('; HTTP $code');
    }
    try {
      buf.write('; ${error.requestOptions.method} ${error.requestOptions.uri}');
    } catch (_) {
      /* ignore */
    }
    return buf.toString();
  }
  return '${error.runtimeType}: $error';
}

// #region agent log
const _kAgentIngest =
    'http://127.0.0.1:7778/ingest/b57793d3-e555-4b7c-82b0-d86317abb97e';
const _kAgentSession = 'a7a4bd';

/// Fire-and-forget: logs connect failures for local debug ingest + optional workspace NDJSON.
void agentLogConnectToServerFailure({
  required String hypothesisId,
  required String primaryLine,
  required String errorRuntimeType,
  required bool includeStack,
}) {
  final payload = <String, Object?>{
    'sessionId': _kAgentSession,
    'runId': kReleaseMode ? 'release' : 'debug',
    'hypothesisId': hypothesisId,
    'location': 'login_screen_cubit.dart:connectToServer',
    'message': 'connectToServer catch',
    'data': <String, Object?>{
      'primaryLine': primaryLine,
      'errorRuntimeType': errorRuntimeType,
      'includeStack': includeStack,
    },
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  final line = jsonEncode(payload);

  Future<void>.microtask(() async {
    try {
      final client = HttpClient();
      final req = await client.postUrl(Uri.parse(_kAgentIngest));
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      req.headers.set('X-Debug-Session-Id', _kAgentSession);
      req.write(line);
      await req.close();
      client.close(force: true);
    } catch (_) {
      /* ingest optional */
    }
    for (final path in const ['debug-a7a4bd.log', '../debug-a7a4bd.log']) {
      try {
        await File(path).writeAsString('$line\n', mode: FileMode.append);
        break;
      } catch (_) {
        /* try next cwd-relative path */
      }
    }
  });
}
// #endregion agent log
