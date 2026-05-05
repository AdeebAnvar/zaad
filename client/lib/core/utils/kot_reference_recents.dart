import 'dart:async';

import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted MRU strings for KOT reference autocomplete (kitchen / table refs).
class KotReferenceRecents {
  KotReferenceRecents._();

  static const String _prefsKey = 'pos_kot_reference_recents';

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

  /// Prefer [prefsOrdered] MRU order, append distinct [dbOrdered] refs not already present.
  static List<String> mergePrefsAndDistinctDb(List<String> prefsOrdered, List<String> dbOrdered) {
    final out = <String>[];
    final seenLower = <String>{};
    void take(String raw) {
      final t = raw.trim();
      if (t.isEmpty) return;
      final k = t.toLowerCase();
      if (!seenLower.contains(k)) {
        seenLower.add(k);
        out.add(t);
      }
    }

    for (final p in prefsOrdered) {
      take(p);
    }
    for (final d in dbOrdered) {
      take(d);
    }

    while (out.length > 48) out.removeLast();
    return out;
  }

  static Future<void> _persist(SharedPreferences prefs, List<String> list) =>
      prefs.setStringList(_prefsKey, list);

  /// Fire-and-forget; safe if [SharedPreferences] is not registered yet.
  static void recordBestEffort(String reference) {
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
