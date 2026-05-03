import 'package:pos/data/local/drift_database.dart';
import 'package:pos/domain/models/customer_model.dart';

/// Local POS view of a customer: [CustomerCreatedUpdated] (API row shape) plus
/// local Drift id and sync flag. Does not change domain model classes.
class PosCustomer {
  const PosCustomer({
    required this.localId,
    required this.row,
    required this.isSynced,
  });

  /// [Customer.id] (Drift). Use `0` for inserts.
  final int localId;
  final CustomerCreatedUpdated row;
  final bool isSynced;

  int get id => localId;

  String get name => row.customerName;
  String? get phone {
    final n = row.customerNumber.trim();
    return n.isEmpty ? null : row.customerNumber;
  }

  String? get email {
    final e = row.customerEmail.trim();
    return e.isEmpty ? null : row.customerEmail;
  }

  String? get gender {
    final g = row.customerGender.trim();
    return g.isEmpty ? null : row.customerGender;
  }

  String? get address {
    final a = row.customerAddress.trim();
    return a.isEmpty ? null : row.customerAddress;
  }

  String? get cardNo {
    final c = row.cardNo.trim();
    return c.isEmpty ? null : row.cardNo;
  }

  DateTime get createdAt => row.createdAt;

  DateTime get updatedAt => row.updatedAt;

  /// Server-side id as string, for `customers.server_id`.
  String? get serverIdStr => row.id > 0 ? row.id.toString() : null;

  factory PosCustomer.fromDrift(Customer c) {
    return PosCustomer(
      localId: c.id,
      isSynced: c.isSynced,
      row: customerRowFromDrift(c),
    );
  }

  /// New or edited customer to persist; [localId] 0 = insert.
  factory PosCustomer.fromRow({
    required CustomerCreatedUpdated row,
    int localId = 0,
    bool isSynced = false,
  }) {
    return PosCustomer(localId: localId, row: row, isSynced: isSynced);
  }

  /// Placeholder for [firstWhere] / autocomplete when no DB row is selected.
  factory PosCustomer.placeholder({
    String name = '',
    String phone = '',
    String email = '',
  }) {
    final t = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return PosCustomer(
      localId: 0,
      isSynced: true,
      row: CustomerCreatedUpdated(
        id: 0,
        uuid: '',
        branchId: 0,
        customerName: name,
        customerNumber: phone,
        customerEmail: email,
        customerAddress: '',
        customerGender: '',
        cardNo: '',
        createdAt: t,
        updatedAt: t,
        deletedAt: null,
      ),
    );
  }
}

/// Maps a Drift [Customer] row to [CustomerCreatedUpdated] (API field names).
CustomerCreatedUpdated customerRowFromDrift(Customer c) {
  final sid = int.tryParse(c.serverId ?? '');
  return CustomerCreatedUpdated(
    id: sid ?? c.id,
    uuid: c.recordUuid ?? '',
    branchId: c.branchId ?? 0,
    customerName: c.name,
    customerNumber: (c.phone != null && c.phone!.isNotEmpty)
        ? c.phone!
        : (c.customerNumber ?? ''),
    customerEmail: c.email ?? '',
    customerAddress: c.address ?? '',
    customerGender: c.gender ?? '',
    cardNo: c.cardNo ?? '',
    createdAt: c.createdAt,
    updatedAt: c.updatedAt,
    deletedAt: null,
  );
}
