import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/isolate/app_isolate_service.dart';
import 'package:pos/core/sync/pull_response_parse.dart';

@pragma('vm:entry-point')
int _doubleValue(int n) => n * 2;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppIsolateService', () {
    test('run executes callback off UI thread', () async {
      final result = await AppIsolateService.instance.run(_doubleValue, 21);
      expect(result, 42);
    });

    test('run parses pull page via parsePullPageFromRaw', () async {
      final raw = <String, dynamic>{
        'success': true,
        'message': 'ok',
        'data': <String, dynamic>{
          'category': <String, dynamic>{
            'created_updated': <dynamic>[],
            'deleted': <dynamic>[],
            'pagination': <String, dynamic>{
              'current_page': 1,
              'last_page': 1,
              'per_page': 15,
              'total': 0,
              'has_more': false,
            },
          },
        },
      };

      final pull = await AppIsolateService.instance.run(parsePullPageFromRaw, raw);
      expect(pull.success, isTrue);
      expect(pull.data.kitchens.createdUpdated, isEmpty);
    });
  });
}
