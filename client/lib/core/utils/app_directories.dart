import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Centralized app-managed folders under Documents (same root as backups/exports):
/// - Documents/ZaadPOS/local   -> sqlite / schema marker
/// - Documents/ZaadPOS/media   -> downloaded images
/// - Documents/ZaadPOS/backup  -> SQLite file backups (`BackupService`)
/// - Documents/ZaadPOS/exports -> XLSX exports (`ExportService`)
class AppDirectories {
  AppDirectories._();

  static const String appFolderName = 'ZaadPOS';
  static const String _legacyAppFolderName = 'zaad pos';
  static const String localFolderName = 'local';
  static const String mediaFolderName = 'media';

  /// Merges the old `Documents/zaad pos` tree into `Documents/ZaadPOS` once, then
  /// deletes the legacy folder so only one POS root remains.
  static Future<void> migrateLegacyLayoutIfNeeded() async {
    final docs = await getApplicationDocumentsDirectory();
    final legacy = Directory(p.join(docs.path, _legacyAppFolderName));
    final modern = Directory(p.join(docs.path, appFolderName));

    if (!await legacy.exists()) return;

    Future<void> copyMerge(Directory from, Directory to) async {
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

    if (!await modern.exists()) {
      try {
        await legacy.rename(modern.path);
      } catch (_) {
        await modern.create(recursive: true);
        await copyMerge(Directory(p.join(legacy.path, localFolderName)), Directory(p.join(modern.path, localFolderName)));
        await copyMerge(Directory(p.join(legacy.path, mediaFolderName)), Directory(p.join(modern.path, mediaFolderName)));
        try {
          await legacy.delete(recursive: true);
        } catch (_) {}
      }
      return;
    }

    await copyMerge(Directory(p.join(legacy.path, localFolderName)), Directory(p.join(modern.path, localFolderName)));
    await copyMerge(Directory(p.join(legacy.path, mediaFolderName)), Directory(p.join(modern.path, mediaFolderName)));
    try {
      await legacy.delete(recursive: true);
    } catch (_) {}
  }

  static Future<Directory> appRoot() async {
    final docs = await getApplicationDocumentsDirectory();
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
}

