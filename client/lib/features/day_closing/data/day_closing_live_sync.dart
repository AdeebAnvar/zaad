import 'dart:async';

import 'package:flutter/foundation.dart';

/// Notifies [DayClosingScreen] to reload when the branch checkpoint changes (local submit or LAN hub).
class DayClosingLiveSync {
  DayClosingLiveSync();

  final ValueNotifier<int> revision = ValueNotifier<int>(0);
  Timer? _debounce;
  static const int _debounceMs = 200;

  void notifyDayClosingChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: _debounceMs), () {
      revision.value = revision.value + 1;
    });
  }
}
