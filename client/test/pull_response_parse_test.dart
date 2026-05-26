import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/sync/pull_response_parse.dart';

void main() {
  test('parsePullPageFromRaw fills missing resources and parses success', () {
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

    final pull = parsePullPageFromRaw(raw);

    expect(pull.success, isTrue);
    expect(pull.message, 'ok');
    expect(pull.data.item.createdUpdated, isEmpty);
    expect(pull.data.offers.createdUpdated, isEmpty);
  });

  test('extractApiDriverMap reads driver before inject placeholder', () {
    final raw = <String, dynamic>{
      'data': <String, dynamic>{
        'driver': <String, dynamic>{
          'created_updated': <dynamic>[
            <String, dynamic>{
              'id': 7,
              'driver_name': 'Ali',
              'driver_phone': '050',
              'branch_id': 1,
            },
          ],
          'deleted': <dynamic>[],
          'pagination': <String, dynamic>{
            'current_page': 1,
            'last_page': 1,
            'per_page': 15,
            'total': 1,
            'has_more': false,
          },
        },
      },
    };

    final driver = extractApiDriverMap(raw);
    expect(driver, isNotNull);
    expect(driver!.createdUpdated, hasLength(1));
    expect(driver.createdUpdated.first.driverName, 'Ali');
  });
}
