import 'dart:async';

import 'package:flutter/services.dart';
/// Fires [onIdle] after [idleAfter] with no calls to [bump], until [resetTimer] or [dispose].
class IdleMonitorService {
  IdleMonitorService({required this.idleAfter, required this.onIdle});

  /// Five minutes without operator interaction before unattended install.
  static const Duration defaultPosIdle = Duration(minutes: 5);

  final Duration idleAfter;
  final VoidCallback onIdle;

  Timer? _timer;
  KeyEventCallback? _keyboardHook;
  bool _disposed = false;

  void attachKeyboardListener() {
    if (_keyboardHook != null) return;
    _keyboardHook = _onHardwareKeyEvent;
    HardwareKeyboard.instance.addHandler(_keyboardHook!);
  }

  void detachKeyboardListener() {
    final hook = _keyboardHook;
    if (hook == null) return;
    HardwareKeyboard.instance.removeHandler(hook);
    _keyboardHook = null;
  }

  bool _onHardwareKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      bump();
    }
    return false;
  }

  /// User interacted with the POS (pointer taps, barcode scan, keyboard, payment pad, etc.).
  void bump() {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(idleAfter, () {
      if (_disposed) return;
      onIdle();
    });
  }

  /// Cancels idle countdown without firing.
  void resetTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    detachKeyboardListener();
  }
}
