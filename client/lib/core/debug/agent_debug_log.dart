import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// Debug-mode NDJSON: workspace file + optional ingest (physical device: pass
/// `--dart-define=AGENT_LOG_HOST=<PC_LAN_IP>` so POST reaches Cursor ingest).
// #region agent log
void agentDebugLog({
  required String hypothesisId,
  required String location,
  required String message,
  Map<String, Object?>? data,
}) {
  final payload = <String, Object?>{
    'sessionId': 'c75079',
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data ?? const <String, Object?>{},
  };
  final line = jsonEncode(payload);

  var dir = Directory.current;
  var wrote = false;
  for (var i = 0; i < 8 && !wrote; i++) {
    try {
      File(p.join(dir.path, 'debug-c75079.log')).writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
      wrote = true;
    } catch (_) {}
    if (!dir.parent.path.endsWith(dir.path)) {
      dir = dir.parent;
    } else {
      break;
    }
  }
  if (!wrote) {
    for (final rel in <String>['debug-c75079.log', '../debug-c75079.log', '../../debug-c75079.log']) {
      try {
        File(rel).writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
        break;
      } catch (_) {}
    }
  }

  const host = String.fromEnvironment('AGENT_LOG_HOST', defaultValue: '127.0.0.1');
  unawaited(
    http
        .post(
          Uri.parse('http://$host:7778/ingest/b57793d3-e555-4b7c-82b0-d86317abb97e'),
          headers: const <String, String>{
            'Content-Type': 'application/json',
            'X-Debug-Session-Id': 'c75079',
          },
          body: line,
        )
        .timeout(const Duration(milliseconds: 900))
        .then((_) {}, onError: (_) {}),
  );
}

// #endregion
