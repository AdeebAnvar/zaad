import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted MRU strings for KOT reference autocomplete (kitchen / table refs).
class KotReferenceRecents {
  KotReferenceRecents._();

  /// SharedPreferences key — cleared automatically after each app update.
  static const String prefsKey = 'pos_kot_reference_recents';

  static const String _prefsKey = prefsKey;

  /// How many refs we persist (first = most recently used).
  static const int _maxStored = 30;

  static List<String> loadSync(SharedPreferences prefs) {
    final raw = prefs.getStringList(_prefsKey);
    if (raw == null || raw.isEmpty) return [];
    final out = <String>[];
    final seenLower = <String>{};
    for (final r in raw) {
      final t = r.trim();
      if (t.isEmpty) continue;
      final k = t.toLowerCase();
      if (seenLower.add(k)) out.add(t);
      if (out.length >= _maxStored) break;
    }
    return out;
  }

  static Future<void> _persist(SharedPreferences prefs, List<String> list) =>
      prefs.setStringList(_prefsKey, list);

  /// Persists [reference] to the MRU list shown in the KOT reference dropdown.
  ///
  /// Call only from explicit UI (e.g. "Save to list"); do not invoke on every bill save.
  static Future<void> clearAll(SharedPreferences prefs) => prefs.remove(_prefsKey);

  static void savePinnedReference(String reference) {
    final t = reference.trim();
    if (t.isEmpty) return;
    final g = GetIt.instance;
    if (!g.isRegistered<SharedPreferences>()) return;
    final prefs = g<SharedPreferences>();
    final list = List<String>.from(prefs.getStringList(_prefsKey) ?? []);
    list.removeWhere((e) => e.trim().toLowerCase() == t.toLowerCase());
    list.insert(0, t);
    if (list.length > _maxStored) list.removeRange(_maxStored, list.length);
    unawaited(_persist(prefs, list));
  }
}
