import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/core/utils/image_utils.dart';
import 'package:pos/core/utils/kot_reference_recents.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clears ephemeral UI/cache data when the installed app [PackageInfo] version changes.
///
/// **Does not** wipe SQLite (see [AppStartup.ensureCompatibleLocalData] for schema bumps).
/// KOT reference dropdown suggestions ([KotReferenceRecents]) are the main fix for
/// "mystery" reference strings surviving APK / Windows installer updates.
class AppUpdateCacheClear {
  AppUpdateCacheClear._();

  static const String versionFileName = 'app_package_version.txt';

  /// `1.0.0+54` style label (version + build number).
  static String packageVersionLabel(PackageInfo info) => '${info.version}+${info.buildNumber}';

  /// True when [lastSeen] is set and differs from [current] (i.e. user updated the app).
  static bool shouldClearCaches({required String? lastSeen, required String current}) {
    final prev = lastSeen?.trim();
    if (prev == null || prev.isEmpty) return false;
    return prev != current.trim();
  }

  /// Call once per cold start from [main] (after [SharedPreferences] is available).
  static Future<void> runOnColdStartIfNeeded() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = packageVersionLabel(info);

      final localDir = await AppDirectories.local();
      final versionFile = File(p.join(localDir.path, versionFileName));

      String? lastSeen;
      if (await versionFile.exists()) {
        try {
          lastSeen = (await versionFile.readAsString()).trim();
        } catch (_) {
          lastSeen = null;
        }
      }

      if (shouldClearCaches(lastSeen: lastSeen, current: current)) {
        await _clearEphemeralCaches();
        if (kDebugMode) {
          debugPrint('[AppUpdateCacheClear] cleared caches ($lastSeen → $current)');
        }
      }

      try {
        await versionFile.writeAsString(current);
      } catch (_) {}
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AppUpdateCacheClear] skipped: $e\n$st');
      }
    }
  }

  static Future<void> _clearEphemeralCaches() async {
    await _clearKotReferenceRecents();
    TenantImageUrlCache.invalidate();
    AppDirectories.clearRuntimeProbeCache();
    await _clearPathProviderCacheDirs();
  }

  static Future<void> _clearKotReferenceRecents() async {
    try {
      if (GetIt.instance.isRegistered<SharedPreferences>()) {
        await KotReferenceRecents.clearAll(GetIt.instance<SharedPreferences>());
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      await KotReferenceRecents.clearAll(prefs);
    } catch (_) {}
  }

  static Future<void> _clearPathProviderCacheDirs() async {
    for (final dir in await _cacheDirectories()) {
      try {
        if (!await dir.exists()) continue;
        await for (final entity in dir.list()) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {}
        }
      } catch (_) {}
    }
  }

  static Future<List<Directory>> _cacheDirectories() async {
    final out = <Directory>[];
    try {
      out.add(await getTemporaryDirectory());
    } catch (_) {}
    try {
      out.add(await getApplicationCacheDirectory());
    } catch (_) {}
    return out;
  }
}
