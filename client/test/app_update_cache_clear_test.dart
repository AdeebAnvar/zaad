import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pos/core/utils/app_update_cache_clear.dart';

void main() {
  group('AppUpdateCacheClear', () {
    test('packageVersionLabel includes build number', () {
      final info = PackageInfo(
        appName: 'pos',
        packageName: 'com.example.pos',
        version: '1.2.3',
        buildNumber: '99',
      );
      expect(AppUpdateCacheClear.packageVersionLabel(info), '1.2.3+99');
    });

    test('shouldClearCaches only when prior version differs', () {
      expect(
        AppUpdateCacheClear.shouldClearCaches(lastSeen: null, current: '1.0.0+1'),
        isFalse,
      );
      expect(
        AppUpdateCacheClear.shouldClearCaches(lastSeen: '', current: '1.0.0+1'),
        isFalse,
      );
      expect(
        AppUpdateCacheClear.shouldClearCaches(lastSeen: '1.0.0+1', current: '1.0.0+1'),
        isFalse,
      );
      expect(
        AppUpdateCacheClear.shouldClearCaches(lastSeen: '1.0.0+1', current: '1.0.0+2'),
        isTrue,
      );
      expect(
        AppUpdateCacheClear.shouldClearCaches(lastSeen: '1.0.0+54', current: '1.0.1+54'),
        isTrue,
      );
    });
  });
}
