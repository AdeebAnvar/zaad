import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// App-managed folders under **user-visible Documents/ZaadPOS** when possible:
/// - …/ZaadPOS/local   -> sqlite (`pos.sqlite`)
/// - …/ZaadPOS/media   -> images + `sales_backup.xlsx`
/// - …/ZaadPOS/backup  -> `latest.db` + up to 2 dated copies (`BackupService`, pruned on startup)
/// - …/ZaadPOS/exports -> XLSX exports (`ExportService`)
///
/// **Windows**: same as before — path_provider’s application documents (your `Documents` folder).
/// **Android**: system **Documents** (`/storage/emulated/0/Documents/ZaadPOS`) when storage access
/// allows it; otherwise falls back to the internal app directory (legacy behavior).
/// Deleting the **ZaadPOS** folder removes local DB/backups/exports/media for the next run (new DB).
class AppDirectories {
  AppDirectories._();

  static const MethodChannel _androidStorageChannel = MethodChannel('com.example.pos_app/storage');

  static const String appFolderName = 'ZaadPOS';
  static const String _legacyAppFolderName = 'zaad pos';
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

  static Future<void> _ensureAndroidCanUsePublicDocuments() async {
    if (!Platform.isAndroid) return;
    final raw = await _androidPublicDocumentsPathRaw();
    if (raw == null || raw.isEmpty) return;

    Future<bool> probe() async {
      final probeFile = File(p.join(raw, '.zaadpos_probe_${DateTime.now().microsecondsSinceEpoch}'));
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

    if (await probe()) return;

    final m = await Permission.manageExternalStorage.request();
    if (m.isGranted && await probe()) return;

    final s = await Permission.storage.request();
    if (s.isGranted && await probe()) return;

    if (kDebugMode) {
      debugPrint('[AppDirectories] Public Documents not writable; using internal app storage.');
    }
  }

  /// Copies **internal** `…/app_flutter/ZaadPOS` → **public** `Documents/ZaadPOS`, then removes the internal tree.
  static Future<void> migrateAndroidInternalToPublicDocumentsIfNeeded() async {
    if (!Platform.isAndroid) return;

    await _ensureAndroidCanUsePublicDocuments();

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

  static Future<Directory> _documentsParentForZaadPos() async {
    if (Platform.isWindows) {
      return getApplicationDocumentsDirectory();
    }
    if (Platform.isAndroid) {
      await _ensureAndroidCanUsePublicDocuments();
      final raw = await _androidPublicDocumentsPathRaw();
      if (raw != null && raw.isNotEmpty) {
        final d = Directory(raw);
        if (await d.exists()) {
          return d;
        }
        try {
          await d.create(recursive: true);
          return d;
        } catch (_) {
          /* fall through */
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
