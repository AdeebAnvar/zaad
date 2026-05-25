import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// Debug-mode NDJSON only. **No-op in release** — sync disk writes here caused
/// UI freezes on busy branches (every screen / hub event).
// #region agent log
void agentDebugLog({
  required String hypothesisId,
  required String location,
  required String message,
  Map<String, Object?>? data,
}) {
  if (!kDebugMode) return;

  final payload = <String, Object?>{
    'sessionId': 'a1dec1',
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data ?? const <String, Object?>{},
  };
  _AgentDebugLogSink.instance.enqueue(jsonEncode(payload));
}

class _AgentDebugLogSink {
  _AgentDebugLogSink._();
  static final _AgentDebugLogSink instance = _AgentDebugLogSink._();

  Future<void> _queue = Future<void>.value();

  void enqueue(String line) {
    _queue = _queue.then((_) => _appendLine(line));
  }

  Future<void> _appendLine(String line) async {
    var dir = Directory.current;
    for (var i = 0; i < 8; i++) {
      try {
        final file = File(p.join(dir.path, 'debug-a1dec1.log'));
        await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
        return;
      } catch (_) {}
      if (!dir.parent.path.endsWith(dir.path)) {
        dir = dir.parent;
      } else {
        break;
      }
    }
    for (final rel in <String>['debug-a1dec1.log', '../debug-a1dec1.log', '../../debug-a1dec1.log']) {
      try {
        final file = File(rel);
        await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
        return;
      } catch (_) {}
    }

    if (!kDebugMode) return;
    const host = String.fromEnvironment('AGENT_LOG_HOST', defaultValue: '127.0.0.1');
    try {
      await http
          .post(
            Uri.parse('http://$host:7778/ingest/b57793d3-e555-4b7c-82b0-d86317abb97e'),
            headers: const <String, String>{
              'Content-Type': 'application/json',
              'X-Debug-Session-Id': 'a1dec1',
            },
            body: line,
          )
          .timeout(const Duration(milliseconds: 900));
    } catch (_) {}
  }
}
// #endregion
