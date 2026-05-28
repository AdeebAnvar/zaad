import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_isolate/flutter_isolate.dart';

/// Application-wide wrapper around `package:flutter_isolate`.
///
/// Android/iOS use [flutterCompute] when the plugin is available.
/// Desktop (Windows/macOS/Linux) and web use [compute] — `flutter_isolate` has no
/// native implementation there (`MissingPluginException` on `spawn_isolate`).
class AppIsolateService {
  AppIsolateService._();

  static final AppIsolateService instance = AppIsolateService._();

  bool _flutterIsolateAvailable = _platformSupportsFlutterIsolatePlugin;

  /// Only mobile targets register `com.rmawatson.flutterisolate/control`.
  static bool get _platformSupportsFlutterIsolatePlugin {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      default:
        return false;
    }
  }

  /// `flutter test` has no [FlutterIsolate] platform channel.
  static bool get _isUnitTest {
    try {
      return WidgetsBinding.instance.runtimeType.toString().contains('TestWidgets');
    } on Object {
      return false;
    }
  }

  /// Whether the last call used [flutterCompute] from `flutter_isolate`.
  bool get lastUsedFlutterIsolate => _lastUsedFlutterIsolate;
  bool _lastUsedFlutterIsolate = false;

  /// Runs [callback] with [message] on a background isolate.
  Future<T> run<T, U>(
    FutureOr<T> Function(U message) callback,
    U message,
  ) async {
    if (kIsWeb) {
      _lastUsedFlutterIsolate = false;
      return await callback(message);
    }
    if (_isUnitTest || !_flutterIsolateAvailable) {
      _lastUsedFlutterIsolate = false;
      return compute(callback, message);
    }
    try {
      _lastUsedFlutterIsolate = true;
      return await flutterCompute(callback, message);
    } on MissingPluginException catch (e) {
      debugPrint('[AppIsolate] flutter_isolate unavailable, using compute: $e');
      _flutterIsolateAvailable = false;
      _lastUsedFlutterIsolate = false;
      return compute(callback, message);
    } catch (e, st) {
      debugPrint('[AppIsolate] flutterCompute failed, using compute: $e\n$st');
      _flutterIsolateAvailable = false;
      _lastUsedFlutterIsolate = false;
      return compute(callback, message);
    }
  }

  /// Stops any lingering [FlutterIsolate] workers (call on logout).
  ///
  /// Desktop uses [compute]/short-lived isolates only — [FlutterIsolate.killAll]
  /// touches a missing/unstable plugin channel and can stall the UI on exit.
  Future<void> shutdown() async {
    if (kIsWeb || _isUnitTest || !_platformSupportsFlutterIsolatePlugin) return;
    try {
      await FlutterIsolate.killAll();
    } catch (e) {
      debugPrint('[AppIsolate] killAll: $e');
    }
  }
}
