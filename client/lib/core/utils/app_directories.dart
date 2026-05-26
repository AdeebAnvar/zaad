import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// App-managed folders under **user-visible Documents/ZaadPOS** when possible:
/// - …/ZaadPOS/local   -> sqlite (`pos.sqlite`)
/// - …/ZaadPOS/media   -> images + `sales_backup.xlsx`
/// - …/ZaadPOS/backup  -> SQLite copies (`BackupService`)
/// - …/ZaadPOS/exports -> reserved for future XLSX exports
///
/// **Windows**: same as before — path_provider’s application documents (your `Documents` folder).
/// **Android**: system **Documents** (`/storage/emulated/0/Documents/ZaadPOS`) when storage access
/// allows it; otherwise falls back to the internal app directory (legacy behavior).
/// Deleting the **ZaadPOS** folder removes local DB/backups/exports/media for the next run (new DB).
class AppDirectories {
  AppDirectories._();

  /// **Temporary (≈2 days):** skip public `Documents/ZaadPOS` on Android and use internal
  /// app storage only. Many OEMs block SQLite there without "All files access".
  /// Set to `false` when rolling out the full public-Documents flow again.
  static const bool temporaryForceAndroidInternalStorage = true;

  static const MethodChannel _androidStorageChannel = MethodChannel('com.example.pos_app/storage');

  /// Set by [_ensureAndroidCanUsePublicDocuments] after file + SQLite probes under public Documents.
  static bool? _androidPublicDocumentsOk;

  static const String appFolderName = 'ZaadPOS';
  static const String _legacyAppFolderName = 'zaad pos';
  static const String _windowsParentCacheFileName = 'data_parent_path.txt';
  static const String localFolderName = 'local';
  static const String mediaFolderName = 'media';
  static const String backupFolderName = 'backup';
  static const String exportsFolderName = 'exports';

  static Future<void> _copyMergeFilesOnly(Directory from, Directory to) async {
    if (!await from.exists()) return;
    if (!await to.exists()) await to.create(recursive: true);
    await for (final entity in from.list(recursive: true)) {
      if (entity is! File) continue;
      final rel = p.relative(entity.path, from: from.path);
      final dest = File(p.join(to.path, rel));
      if (await dest.exists()) continue;
      await dest.parent.create(recursive: true);
      await entity.copy(dest.path);
    }
  }

  /// One-time merge of old `Documents/zaad pos` → `Documents/ZaadPOS` on the **internal**
  /// Android path (where legacy builds stored data). Must run before [migrateAndroidInternalToPublicDocumentsIfNeeded].
  static Future<void> migrateLegacyLayoutIfNeeded() async {
    if (!Platform.isAndroid) return;

    final docs = await getApplicationDocumentsDirectory();
    final legacy = Directory(p.join(docs.path, _legacyAppFolderName));
    final modern = Directory(p.join(docs.path, appFolderName));

    if (!await legacy.exists()) return;

    if (!await modern.exists()) {
      try {
        await legacy.rename(modern.path);
      } catch (_) {
        await modern.create(recursive: true);
        await _copyMergeFilesOnly(Directory(p.join(legacy.path, localFolderName)), Directory(p.join(modern.path, localFolderName)));
        await _copyMergeFilesOnly(Directory(p.join(legacy.path, mediaFolderName)), Directory(p.join(modern.path, mediaFolderName)));
        try {
          await legacy.delete(recursive: true);
        } catch (_) {}
      }
      return;
    }

    await _copyMergeFilesOnly(Directory(p.join(legacy.path, localFolderName)), Directory(p.join(modern.path, localFolderName)));
    await _copyMergeFilesOnly(Directory(p.join(legacy.path, mediaFolderName)), Directory(p.join(modern.path, mediaFolderName)));
    try {
      await legacy.delete(recursive: true);
    } catch (_) {}
  }

  static Future<String?> _androidPublicDocumentsPathRaw() async {
    try {
      return await _androidStorageChannel.invokeMethod<String>('publicDocumentsPath');
    } catch (_) {
      return null;
    }
  }

  static Future<bool> _probeWritableFile(String parentPath) async {
    final probeFile = File(p.join(parentPath, '.zaadpos_probe_${DateTime.now().microsecondsSinceEpoch}'));
    try {
      await probeFile.writeAsString('1', flush: true);
      final ok = await probeFile.exists();
      try {
        await probeFile.delete();
      } catch (_) {}
      return ok;
    } catch (_) {
      try {
        await probeFile.delete();
      } catch (_) {}
      return false;
    }
  }

  static Future<bool> _probeSqliteInDirectory(Directory dir) async {
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final testPath = p.join(dir.path, '.zaadpos_sqlite_probe');
      final db = sqlite.sqlite3.open(testPath);
      try {
        db.execute('PRAGMA user_version = 1;');
      } finally {
        db.dispose();
      }
      final f = File(testPath);
      if (await f.exists()) {
        await f.delete();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Whether the app is using (or can use) public Documents/ZaadPOS for SQLite.
  static Future<bool> get androidPublicDocumentsReady async {
    if (!Platform.isAndroid) return false;
    await _ensureAndroidCanUsePublicDocuments();
    return _androidPublicDocumentsOk == true;
  }

  /// Drops in-memory Android public-Documents probe (e.g. after an app update cache sweep).
  static void clearRuntimeProbeCache() {
    _androidPublicDocumentsOk = null;
  }

  /// Clears the cached probe result and re-checks after the user grants storage.
  static Future<bool> requestAndroidPublicStorageAccess() async {
    if (!Platform.isAndroid) return false;
    _androidPublicDocumentsOk = null;
    await _requestAndroidStoragePermissions();
    await _ensureAndroidCanUsePublicDocuments();
    return _androidPublicDocumentsOk == true;
  }

  static Future<void> _requestAndroidStoragePermissions() async {
    if (!Platform.isAndroid) return;

    // Android 11+ — "All files access" (opens system settings when needed).
    final manage = await Permission.manageExternalStorage.status;
    if (!manage.isGranted) {
      await Permission.manageExternalStorage.request();
    }

    // Android 10 and below, and some OEM paths.
    final storage = await Permission.storage.status;
    if (!storage.isGranted) {
      await Permission.storage.request();
    }
  }

  static Future<void> _ensureAndroidCanUsePublicDocuments() async {
    if (!Platform.isAndroid) return;
    if (_androidPublicDocumentsOk != null) return;

    if (temporaryForceAndroidInternalStorage) {
      _androidPublicDocumentsOk = false;
      if (kDebugMode) {
        debugPrint('[AppDirectories] temporaryForceAndroidInternalStorage: using internal app storage.');
      }
      return;
    }

    final raw = await _androidPublicDocumentsPathRaw();
    if (raw == null || raw.isEmpty) {
      _androidPublicDocumentsOk = false;
      return;
    }

    Future<bool> probePublicTree() async {
      if (!await _probeWritableFile(raw)) return false;
      final localProbeDir = Directory(p.join(raw, appFolderName, localFolderName));
      return _probeSqliteInDirectory(localProbeDir);
    }

    if (await probePublicTree()) {
      _androidPublicDocumentsOk = true;
      return;
    }

    await _requestAndroidStoragePermissions();

    if (await probePublicTree()) {
      _androidPublicDocumentsOk = true;
      return;
    }

    _androidPublicDocumentsOk = false;
    if (kDebugMode) {
      debugPrint('[AppDirectories] Public Documents not writable for SQLite; using internal app storage.');
    }
  }

  /// Copies **internal** `…/app_flutter/ZaadPOS` → **public** `Documents/ZaadPOS`, then removes the internal tree.
  static Future<void> migrateAndroidInternalToPublicDocumentsIfNeeded() async {
    if (!Platform.isAndroid) return;

    await _ensureAndroidCanUsePublicDocuments();
    if (_androidPublicDocumentsOk != true) return;

    final raw = await _androidPublicDocumentsPathRaw();
    if (raw == null || raw.isEmpty) return;

    final publicParent = Directory(raw);
    if (!await publicParent.exists()) {
      try {
        await publicParent.create(recursive: true);
      } catch (_) {
        return;
      }
    }

    final internalDocs = await getApplicationDocumentsDirectory();
    final internalRoot = Directory(p.join(internalDocs.path, appFolderName));
    if (!await internalRoot.exists()) return;

    final publicRoot = Directory(p.join(publicParent.path, appFolderName));
    if (!await publicRoot.exists()) {
      await publicRoot.create(recursive: true);
    }

    await _copyMergeFilesOnly(internalRoot, publicRoot);

    final internalDb = File(p.join(internalRoot.path, localFolderName, 'pos.sqlite'));
    final publicDb = File(p.join(publicRoot.path, localFolderName, 'pos.sqlite'));
    if (await internalDb.exists() && !await publicDb.exists()) {
      if (kDebugMode) {
        debugPrint('[AppDirectories] SQLite did not copy to public Documents; keeping internal ZaadPOS.');
      }
      return;
    }

    try {
      await internalRoot.delete(recursive: true);
    } catch (_) {
      if (kDebugMode) {
        debugPrint('[AppDirectories] Could not delete internal ZaadPOS after migration (ignored).');
      }
    }
  }

  /// When public Documents is not SQLite-safe but a prior build left `pos.sqlite` there,
  /// copy it back to internal storage so the app can open the DB again.
  static Future<void> recoverAndroidDbFromPublicIfNeeded() async {
    if (!Platform.isAndroid) return;
    await _ensureAndroidCanUsePublicDocuments();
    if (_androidPublicDocumentsOk == true) return;

    final raw = await _androidPublicDocumentsPathRaw();
    if (raw == null || raw.isEmpty) return;

    final publicDb = File(p.join(raw, appFolderName, localFolderName, 'pos.sqlite'));
    if (!await publicDb.exists()) return;

    final internalLocal = Directory(
      p.join((await getApplicationDocumentsDirectory()).path, appFolderName, localFolderName),
    );
    if (!await internalLocal.exists()) {
      await internalLocal.create(recursive: true);
    }
    final internalDb = File(p.join(internalLocal.path, 'pos.sqlite'));
    if (await internalDb.exists()) return;

    try {
      await publicDb.copy(internalDb.path);
      if (kDebugMode) {
        debugPrint('[AppDirectories] Recovered pos.sqlite from public Documents to internal storage.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AppDirectories] Could not recover pos.sqlite to internal: $e');
      }
    }
  }

  /// Windows may report Documents under a missing OneDrive drive (e.g. `D:\Onedrive\Documents`).
  /// Probe writable locations and cache the first one that works.
  static Future<Directory> _windowsWritableDocumentsParent() async {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    Directory? cacheRoot;
    Directory? cachedParentFromFile;
    if (localAppData != null && localAppData.isNotEmpty) {
      cacheRoot = Directory(p.join(localAppData, appFolderName));
      try {
        await cacheRoot.create(recursive: true);
        final cacheFile = File(p.join(cacheRoot.path, _windowsParentCacheFileName));
        if (await cacheFile.exists()) {
          final cachedPath = (await cacheFile.readAsString()).trim();
          if (cachedPath.isNotEmpty) {
            cachedParentFromFile = Directory(cachedPath);
          }
        }
      } catch (_) {
        /* try fresh resolution */
      }
    }

    // Fast path: last known good folder (avoids hanging on missing OneDrive Documents).
    if (cachedParentFromFile != null && await cachedParentFromFile.exists()) {
      final cachedBytes = await _existingPosSqliteBytes(cachedParentFromFile);
      if (cachedBytes > 0) {
        if (kDebugMode) {
          debugPrint(
            '[AppDirectories] Windows data parent (cached, $cachedBytes bytes): ${cachedParentFromFile.path}',
          );
        }
        return cachedParentFromFile;
      }
      if (await _probeZaadPosDataTree(cachedParentFromFile)) {
        return cachedParentFromFile;
      }
    }

    final seen = <String>{};
    final candidates = <Directory>[];

    Future<void> addCandidate(Directory? dir) async {
      if (dir == null) return;
      if (!await dir.exists()) return;
      final key = p.normalize(dir.path).toLowerCase();
      if (seen.contains(key)) return;
      seen.add(key);
      candidates.add(dir);
    }

    final userProfile = Platform.environment['USERPROFILE'];
    if (userProfile != null && userProfile.isNotEmpty) {
      await addCandidate(Directory(p.join(userProfile, 'Documents')));
    }

    if (localAppData != null && localAppData.isNotEmpty) {
      await addCandidate(Directory(localAppData));
    }

    try {
      await addCandidate(await getApplicationSupportDirectory());
    } catch (_) {}

    // path_provider Documents last — can block on broken OneDrive redirect.
    try {
      await addCandidate(await getApplicationDocumentsDirectory());
    } catch (_) {}

    final withExistingDb = await _windowsParentWithLargestExistingDb(candidates);
    if (withExistingDb != null) {
      if (kDebugMode) {
        final bytes = await _existingPosSqliteBytes(withExistingDb);
        debugPrint(
          '[AppDirectories] Windows data parent (existing pos.sqlite, $bytes bytes): ${withExistingDb.path}',
        );
      }
      if (cacheRoot != null) {
        try {
          await File(p.join(cacheRoot.path, _windowsParentCacheFileName))
              .writeAsString(withExistingDb.path, flush: true);
        } catch (_) {}
      }
      return withExistingDb;
    }

    for (final parent in candidates) {
      if (!await _probeZaadPosDataTree(parent)) continue;
      if (kDebugMode) {
        debugPrint('[AppDirectories] Windows data parent (new): ${parent.path}');
      }
      if (cacheRoot != null) {
        try {
          await File(p.join(cacheRoot.path, _windowsParentCacheFileName))
              .writeAsString(parent.path, flush: true);
        } catch (_) {}
      }
      return parent;
    }

    throw PathNotFoundException(
      p.join('Documents', appFolderName),
      const OSError('The system cannot find the path specified', 2),
    );
  }

  static Future<bool> _probeZaadPosDataTree(Directory parent) async {
    final localDir = Directory(p.join(parent.path, appFolderName, localFolderName));
    return _probeSqliteInDirectory(localDir);
  }

  static File _posSqliteFileUnderParent(Directory parent) =>
      File(p.join(parent.path, appFolderName, localFolderName, 'pos.sqlite'));

  /// Bytes of an existing on-disk DB, or 0 when missing/empty.
  static Future<int> _existingPosSqliteBytes(Directory parent) async {
    final dbFile = _posSqliteFileUnderParent(parent);
    if (!await dbFile.exists()) return 0;
    try {
      return await dbFile.length();
    } catch (_) {
      return 0;
    }
  }

  /// Prefer the parent that already holds the largest [pos.sqlite] so invoice/order
  /// history is not lost when Windows picks a fresh writable folder (e.g. OneDrive path change).
  static Future<Directory?> _windowsParentWithLargestExistingDb(
    List<Directory> candidates,
  ) async {
    Directory? bestParent;
    var bestBytes = 0;
    for (final parent in candidates) {
      final bytes = await _existingPosSqliteBytes(parent);
      if (bytes <= bestBytes) continue;
      if (!await _probeZaadPosDataTree(parent)) continue;
      bestBytes = bytes;
      bestParent = parent;
    }
    return bestParent;
  }

  static Future<Directory> _documentsParentForZaadPos() async {
    if (Platform.isWindows) {
      return _windowsWritableDocumentsParent();
    }
    if (Platform.isAndroid) {
      await _ensureAndroidCanUsePublicDocuments();
      if (_androidPublicDocumentsOk == true) {
        final raw = await _androidPublicDocumentsPathRaw();
        if (raw != null && raw.isNotEmpty) {
          final d = Directory(raw);
          if (!await d.exists()) {
            try {
              await d.create(recursive: true);
            } catch (_) {
              return getApplicationDocumentsDirectory();
            }
          }
          return d;
        }
      }
    }
    return getApplicationDocumentsDirectory();
  }

  static Future<Directory> appRoot() async {
    final docs = await _documentsParentForZaadPos();
    final root = Directory(p.join(docs.path, appFolderName));
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  static Future<Directory> local() async {
    final root = await appRoot();
    final localDir = Directory(p.join(root.path, localFolderName));
    if (!await localDir.exists()) {
      await localDir.create(recursive: true);
    }
    return localDir;
  }

  static Future<Directory> media() async {
    final root = await appRoot();
    final mediaDir = Directory(p.join(root.path, mediaFolderName));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir;
  }

  static Future<Directory> backupDir() async {
    final root = await appRoot();
    final dir = Directory(p.join(root.path, backupFolderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<Directory> exportsDir() async {
    final root = await appRoot();
    final dir = Directory(p.join(root.path, exportsFolderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
