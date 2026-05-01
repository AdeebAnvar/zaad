import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/domain/models/api/dio_client.dart';

class ImageUtils {
  /// Turns API image fields into a downloadable [http/https] URL.
  /// Server payloads are often path-only (e.g. `/storage/...`); [baseUrl] is the app API base (from prefs).
  static String? resolveToAbsoluteImageUrl(
    String imageRef, {
    String? baseUrlOverride,
  }) {
    final r = imageRef.trim();
    if (r.isEmpty) return null;
    if (r.startsWith('//')) {
      return Uri.parse('https:$r').toString();
    }
    final parsed = Uri.tryParse(r);
    if (parsed != null &&
        parsed.hasScheme &&
        (parsed.scheme == 'http' || parsed.scheme == 'https') &&
        parsed.host.isNotEmpty) {
      return parsed.toString();
    }
    final base = (baseUrlOverride ?? '').trim();
    if (base.isEmpty) {
      return null;
    }
    return Uri.parse(base).resolve(r).toString();
  }

  /// Downloads to app media directory. [fileName] may include an extension, e.g. `item_12.jpg`.
  static Future<String?> downloadImage(String url, String fileName) async {
    try {
      final raw = url.trim();
      if (raw.isEmpty) return null;

      final prefs = await SharedPreferences.getInstance();
      final baseFromPrefs = prefs.getString('baseUrl') ?? '';
      final absolute = resolveToAbsoluteImageUrl(
        raw,
        baseUrlOverride: baseFromPrefs,
      );
      if (absolute == null) {
        if (kDebugMode) {
          debugPrint('ImageUtils: cannot resolve image URL (relative path without baseUrl?): $raw');
        }
        return null;
      }

      final dir = await AppDirectories.media();

      final extFromUrl = p.extension(Uri.parse(absolute).path);
      final String diskName;
      if (p.extension(fileName).isNotEmpty) {
        diskName = fileName;
      } else {
        diskName = extFromUrl.isNotEmpty ? '$fileName$extFromUrl' : '$fileName.webp';
      }
      final outPath = p.join(dir.path, diskName);
      final file = File(outPath);

      if (await file.exists()) {
        final len = await file.length();
        if (len > 0) {
          return outPath;
        }
        await file.delete();
      }

      final dio = await DioClient.getInstance();
      final response = await dio.getUri<List<int>>(
        Uri.parse(absolute),
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          maxRedirects: 5,
          validateStatus: (s) => s != null && s >= 200 && s < 300,
        ),
      );

      if (response.data == null || response.data!.isEmpty) {
        if (kDebugMode) {
          debugPrint('ImageUtils: empty body for $absolute (HTTP ${response.statusCode})');
        }
        return null;
      }

      await file.writeAsBytes(response.data!, flush: true);
      return outPath;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('ImageUtils downloadImage failed: $e');
        debugPrintStack(stackTrace: st);
      }
      return null;
    }
  }
}
