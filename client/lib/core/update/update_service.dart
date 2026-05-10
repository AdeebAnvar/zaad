import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

import 'update_model.dart';

/// Central URL for POS update metadata (hosted on GitHub).
const String kDefaultVersionManifestUrl = 'https://raw.githubusercontent.com/AdeebAnvar/zaad/refs/heads/master/version.json';
final s = 'ds';

/// Installs update bundles under `C:\\zaad\\updates\\` (fixed path per rollout policy).
const String kWindowsUpdatesDirectory = r'C:\zaad\updates';

class UpdateServiceException implements Exception {
  UpdateServiceException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => cause == null ? 'UpdateServiceException: $message' : 'UpdateServiceException: $message ($cause)';
}

/// Stateless network + filesystem helpers — safe to use as singleton.
class UpdateService {
  UpdateService({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// Fast manifest fetch using plain `package:http`.
  ///
  /// Throwing on malformed JSON preserves calling-site control (no swallowing faults).
  Future<RemoteUpdateManifest> fetchManifest({String url = kDefaultVersionManifestUrl, Duration timeout = const Duration(seconds: 20)}) async {
    if (!Platform.isWindows) {
      throw UpdateServiceException('Updates are only supported on Windows');
    }
    try {
      final uri = Uri.parse(url);
      final resp = await _http.get(uri).timeout(timeout);
      if (resp.statusCode != 200) {
        throw UpdateServiceException('Manifest HTTP ${resp.statusCode}');
      }
      final manifest = RemoteUpdateManifest.tryParseBody(resp.body);
      if (manifest == null) {
        throw UpdateServiceException('Invalid manifest JSON');
      }
      return manifest;
    } on SocketException catch (e) {
      throw UpdateServiceException('Network error while fetching manifest', e);
    } on HttpException catch (e) {
      throw UpdateServiceException('HTTP error while fetching manifest', e);
    } on FormatException catch (e) {
      throw UpdateServiceException('Invalid manifest encoding', e);
    } on TimeoutException catch (e, st) {
      throw UpdateServiceException('Manifest request timed out', '$e\n$st');
    }
  }

  /// Download installer to [targetPath] with atomic replace via `.partial` temp.
  ///
  /// [onProgress] receives `received` and `total` (total may be -1 if unknown).
  Future<void> downloadInstaller({
    required String downloadUrl,
    required String targetPath,
    void Function(int received, int total)? onProgress,
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(minutes: 30),
    CancelToken? cancelToken,
  }) async {
    if (!Platform.isWindows) {
      throw UpdateServiceException('Updates are only supported on Windows');
    }
    final dir = Directory(File(targetPath).parent.path);
    try {
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    } on FileSystemException catch (e) {
      throw UpdateServiceException('Cannot create update directory: ${dir.path}', e);
    }

    final partialPath = '$targetPath.partial';
    final partialFile = File(partialPath);
    if (await partialFile.exists()) {
      try {
        await partialFile.delete();
      } catch (_) {
        /* replaced by overwrite */
      }
    }

    final dio = Dio(
      BaseOptions(
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        followRedirects: true,
        maxRedirects: 5,
        responseType: ResponseType.stream,
        validateStatus: (s) => s != null && s >= 200 && s < 400,
      ),
    );

    try {
      await dio.download(
        downloadUrl,
        partialPath,
        cancelToken: cancelToken,
        deleteOnError: true,
        onReceiveProgress: (received, total) {
          onProgress?.call(received, total);
        },
      );
    } on DioException catch (e) {
      try {
        if (await partialFile.exists()) await partialFile.delete();
      } catch (_) {}
      throw UpdateServiceException('Download failed: ${e.message}', e);
    }

    final expectedLen = await _fileLength(partialPath);
    if (expectedLen <= 0) {
      try {
        await partialFile.delete();
      } catch (_) {}
      throw UpdateServiceException('Downloaded file is empty (partial or truncated)');
    }

    final validation = await validateWindowsInstallerFile(partialPath, expectedContentLength: expectedLen);
    if (validation != UpdateInstallerValidation.ok) {
      try {
        await partialFile.delete();
      } catch (_) {}
      throw UpdateServiceException('Installer validation failed: $validation');
    }

    final dest = File(targetPath);
    try {
      if (await dest.exists()) {
        await dest.delete();
      }
      await partialFile.rename(targetPath);
    } on FileSystemException catch (e) {
      throw UpdateServiceException('Cannot finalize installer to $targetPath', e);
    }
  }

  static Future<int> _fileLength(String path) async {
    try {
      return await File(path).length();
    } catch (_) {
      return -1;
    }
  }

  /// PE executables start with `MZ`. Size [expectedContentLength] may come from HTTP; pass -1 to skip.
  static Future<UpdateInstallerValidation> validateWindowsInstallerFile(
    String path, {
    int expectedContentLength = -1,
  }) async {
    try {
      final f = File(path);
      if (!await f.exists()) return UpdateInstallerValidation.ioError;
      final len = await f.length();
      if (len < 2) return UpdateInstallerValidation.emptyFile;
      if (expectedContentLength > 0 && len != expectedContentLength) {
        return UpdateInstallerValidation.sizeMismatch;
      }
      final raf = await f.open();
      try {
        final head = await raf.read(2);
        if (head.length < 2 || head[0] != 0x4D || head[1] != 0x5A) {
          return UpdateInstallerValidation.notPeExecutable;
        }
      } finally {
        await raf.close();
      }
      return UpdateInstallerValidation.ok;
    } on FileSystemException {
      return UpdateInstallerValidation.ioError;
    }
  }
}
