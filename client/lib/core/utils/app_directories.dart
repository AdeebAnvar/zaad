import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Centralized app-managed folders under Documents:
/// - Documents/zaad pos/local  -> sqlite/db/meta files
/// - Documents/zaad pos/media  -> downloaded images/media
class AppDirectories {
  AppDirectories._();

  static const String appFolderName = 'zaad pos';
  static const String localFolderName = 'local';
  static const String mediaFolderName = 'media';

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

