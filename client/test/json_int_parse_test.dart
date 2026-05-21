import 'package:flutter_test/flutter_test.dart';
import 'package:pos/core/utils/json_int_parse.dart';

void main() {
  group('parseIntLoose', () {
    test('parses int, num, and numeric strings', () {
      expect(parseIntLoose(2), 2);
      expect(parseIntLoose(2.4), 2);
      expect(parseIntLoose('42'), 42);
      expect(parseIntLoose('42.9'), 43);
    });

    test('returns null for empty or invalid', () {
      expect(parseIntLoose(null), isNull);
      expect(parseIntLoose(''), isNull);
      expect(parseIntLoose('abc'), isNull);
    });
  });

  group('branchIdFromUserJson', () {
    test('reads snake_case, camelCase, and nested branch', () {
      expect(branchIdFromUserJson({'branch_id': 2}), 2);
      expect(branchIdFromUserJson({'branchId': '2'}), 2);
      expect(branchIdFromUserJson({'branch': {'id': 2}}), 2);
      expect(branchIdFromUserJson({'branch': {'branch_id': 3}}), 3);
    });

    test('returns 0 when missing or invalid', () {
      expect(branchIdFromUserJson({}), 0);
      expect(branchIdFromUserJson({'branch_id': 0}), 0);
      expect(branchIdFromUserJson({'branch_id': '-1'}), 0);
    });
  });

  group('resolveMirroredOrderBranchId', () {
    test('prefers snapshot over session', () {
      expect(
        resolveMirroredOrderBranchId(snap: {'branch_id': 2}, sessionBranchId: 1),
        2,
      );
      expect(
        resolveMirroredOrderBranchId(
          snap: const {},
          flutterSnap: {'branchId': 3},
          sessionBranchId: 1,
        ),
        3,
      );
    });

    test('uses session when snapshot has no branch', () {
      expect(
        resolveMirroredOrderBranchId(snap: const {}, sessionBranchId: 2),
        2,
      );
    });

    test('returns 0 when no valid branch anywhere', () {
      expect(
        resolveMirroredOrderBranchId(snap: const {}, sessionBranchId: 0),
        0,
      );
      expect(resolveMirroredOrderBranchId(snap: const {}), 0);
    });

    test('ignores session when snapshot branch is explicit', () {
      expect(
        resolveMirroredOrderBranchId(
          snap: {'branch_id': '2'},
          flutterSnap: {'branchId': 1},
          sessionBranchId: 1,
        ),
        2,
      );
    });
  });
}
