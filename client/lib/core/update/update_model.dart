import 'dart:convert';

/// Remote manifest at [kDefaultVersionManifestUrl].
class RemoteUpdateManifest {
  RemoteUpdateManifest({
    required this.version,
    required this.installerDownloadUrl,
  });

  /// Semantic version published by ops (e.g. `1.0.1`).
  final String version;

  /// Direct download URL for the Windows Inno Setup installer.
  final String installerDownloadUrl;

  static RemoteUpdateManifest? tryParseBody(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;
      final map = decoded.cast<String, dynamic>();
      final v = map['version']?.toString().trim();
      final u = map['url']?.toString().trim();
      if (v == null || v.isEmpty || u == null || u.isEmpty) return null;
      final uri = Uri.tryParse(u);
      if (uri == null || !uri.hasScheme) return null;
      return RemoteUpdateManifest(version: v, installerDownloadUrl: u);
    } catch (_) {
      return null;
    }
  }

  @override
  String toString() => 'RemoteUpdateManifest($version)';
}

enum UpdateInstallerValidation {
  ok,
  emptyFile,
  sizeMismatch,
  notPeExecutable,
  ioError,
}

/// Production-style semantic version comparison (numeric segments, pragmatic).
///
/// Supports `major.minor.patch` with optional `-pre` / `+meta` tails ignored for ordering.
class VersionCompare {
  const VersionCompare._();

  /// Returns negative if [a] < [b], positive if [a] > [b], zero if equal.
  static int compare(String a, String b) {
    final ta = tokenize(normalize(stripTail(a.trim())));
    final tb = tokenize(normalize(stripTail(b.trim())));
    final len = ta.length > tb.length ? ta.length : tb.length;
    for (var i = 0; i < len; i++) {
      final na = i < ta.length ? ta[i] : 0;
      final nb = i < tb.length ? tb[i] : 0;
      if (na != nb) return na - nb;
    }
    return 0;
  }

  static bool isNewerThan({required String remote, required String current}) {
    return compare(remote, current) > 0;
  }

  static String normalize(String v) => v.startsWith('v') || v.startsWith('V')
      ? v.substring(1)
      : v;

  /// Drops common prerelease/metadata suffix before numeric compare.
  static String stripTail(String v) {
    final cut = RegExp(r'[-+]').firstMatch(v);
    if (cut == null) return v;
    return v.substring(0, cut.start);
  }

  static List<int> tokenize(String v) {
    return v.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
  }
}
