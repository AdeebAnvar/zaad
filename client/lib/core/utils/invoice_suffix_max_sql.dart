import 'package:drift/drift.dart';

/// Fast MAX(suffix) for branch-scoped invoices without loading every matching row.
///
/// Supports `PREFIX-branchId-###` and legacy `PREFIX###` (no extra dashes).
Future<int> maxInvoiceNumericSuffixForPrefixOnTable({
  required DatabaseAccessor<GeneratedDatabase> accessor,
  required String tableName,
  required String invoiceColumn,
  required String prefix,
  required int branchId,
}) async {
  final currentHead = '$prefix-$branchId-';
  final currentMax = await _maxSuffixAfterHead(
    accessor: accessor,
    tableName: tableName,
    invoiceColumn: invoiceColumn,
    branchId: branchId,
    head: currentHead,
    likePattern: '$currentHead%',
  );

  final legacyMax = await _maxLegacySuffix(
    accessor: accessor,
    tableName: tableName,
    invoiceColumn: invoiceColumn,
    prefix: prefix,
    branchId: branchId,
  );

  return currentMax > legacyMax ? currentMax : legacyMax;
}

Future<int> _maxSuffixAfterHead({
  required DatabaseAccessor<GeneratedDatabase> accessor,
  required String tableName,
  required String invoiceColumn,
  required int branchId,
  required String head,
  required String likePattern,
}) async {
  // substr is 1-based; numeric part starts immediately after [head].
  final rows = await accessor.customSelect(
    'SELECT MAX(CAST(substr($invoiceColumn, ?) AS INTEGER)) AS m '
    'FROM $tableName '
    'WHERE branch_id = ? AND $invoiceColumn LIKE ?',
    variables: [
      Variable.withInt(head.length + 1),
      Variable.withInt(branchId),
      Variable.withString(likePattern),
    ],
  ).get();
  if (rows.isEmpty) return 0;
  return rows.first.read<int?>('m') ?? 0;
}

Future<int> _maxLegacySuffix({
  required DatabaseAccessor<GeneratedDatabase> accessor,
  required String tableName,
  required String invoiceColumn,
  required String prefix,
  required int branchId,
}) async {
  final prefixLen = prefix.length;
  final rows = await accessor.customSelect(
    'SELECT MAX(CAST(substr($invoiceColumn, ?) AS INTEGER)) AS m '
    'FROM $tableName '
    'WHERE branch_id = ? '
    'AND $invoiceColumn LIKE ? '
    "AND $invoiceColumn NOT LIKE '%-%'",
    variables: [
      Variable.withInt(prefixLen + 1),
      Variable.withInt(branchId),
      Variable.withString('$prefix%'),
    ],
  ).get();
  if (rows.isEmpty) return 0;
  return rows.first.read<int?>('m') ?? 0;
}
