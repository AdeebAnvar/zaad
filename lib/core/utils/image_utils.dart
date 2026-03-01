import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:path_provider/path_provider.dart';

class ImageUtils {
  static Future<String?> downloadImage(String url, String fileName) async {
    HttpClient? client;

    try {
      if (url.isEmpty) return null;
      
      final dir = await getApplicationDocumentsDirectory();
      
      // Extract file extension from URL if available
      String extension = p.extension(Uri.parse(url).path);
      if (extension.isEmpty) {
        extension = '.webp'; // Default extension for logos
      }
      
      final path = p.join(dir.path, '$fileName$extension');
      final file = File(path);

      if (await file.exists()) {
        return path;
      }

      client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) {
        print('Image download failed: HTTP ${response.statusCode}');
        return null;
      }

      await response.pipe(file.openWrite());
      return path;
    } catch (e) {
      print('Image download failed: $e');
      return null;
    } finally {
      client?.close(force: true);
    }
  }
}
