part of '../drift_database.dart';

class Branches extends Table {
  IntColumn get id => integer()(); // server ID

  TextColumn get branchName => text()();

  TextColumn get location => text()();

  TextColumn get contactNo => text()();

  TextColumn get email => text().nullable()();

  TextColumn get socialMedia => text().nullable()();

  TextColumn get vat => text()();

  RealColumn get vatPercent => real().nullable()();

  TextColumn get trnNumber => text().nullable()();

  TextColumn get prefixInv => text()();

  TextColumn get invoiceHeader => text()();

  TextColumn get image => text()();
  TextColumn get localImage => text().withDefault(const Constant(''))();

  DateTimeColumn get installationDate => dateTime()();

  DateTimeColumn get expiryDate => dateTime()();

  IntColumn get openingCash => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// =========================
/// DAO
/// =========================
@DriftAccessor(tables: [Branches])
class BranchesDao extends DatabaseAccessor<AppDatabase> with _$BranchesDaoMixin {
  BranchesDao(super.db);

  /// UPSERT (sync safe)
  Future<void> insertBranches(List<BranchModel> list) async {
    final companions = await Future.wait(list.map(_toCompanion));
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        branches,
        companions,
      );
    });
  }

  /// GET ALL
  Future<List<BranchModel>> getAllBranches() async {
    final data = await select(branches).get();
    return data.map(_toModel).toList();
  }

  /// GET ONE by [branchId] (server id / primary key)
  Future<BranchModel?> getBranchById(int branchId) async {
    final row = await (select(branches)..where((b) => b.id.equals(branchId))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  /// DELETE (sync)
  Future<void> deleteBranches(List<int> ids) async {
    await (delete(branches)..where((b) => b.id.isIn(ids))).go();
  }

  /// Update opening cash for a specific branch.
  Future<void> updateOpeningCash({
    required int branchId,
    required int openingCashValue,
  }) async {
    await (update(branches)..where((b) => b.id.equals(branchId))).write(
      BranchesCompanion(
        openingCash: Value(openingCashValue),
      ),
    );
  }

  /// =========================
  /// MAPPERS
  /// =========================

  Future<BranchesCompanion> _toCompanion(BranchModel b) async {
    String? localImage = await _downloadBranchImage(
      b.image,
      'Branch_${b.id}_${b.branchName}',
    );
    return BranchesCompanion(
      id: Value(b.id),
      branchName: Value(b.branchName),
      location: Value(b.location),
      contactNo: Value(b.contactNo),
      email: Value(b.email?.toString()),
      socialMedia: Value(b.socialMedia?.toString()),
      vat: Value(b.vat),
      vatPercent: Value(
        b.vatPercent != null ? double.tryParse(b.vatPercent.toString()) : null,
      ),
      trnNumber: Value(b.trnNumber?.toString()),
      prefixInv: Value(b.prefixInv),
      invoiceHeader: Value(b.invoiceHeader),
      image: Value(b.image),
      installationDate: Value(b.installationDate),
      expiryDate: Value(b.expiryDate),
      openingCash: Value(b.openingCash),
      localImage: Value(localImage ?? ""),
    );
  }

  BranchModel _toModel(Branche b) {
    return BranchModel(
      id: b.id,
      branchName: b.branchName,
      location: b.location,
      contactNo: b.contactNo,
      email: b.email,
      socialMedia: b.socialMedia,
      vat: b.vat,
      vatPercent: b.vatPercent,
      trnNumber: b.trnNumber,
      prefixInv: b.prefixInv,
      invoiceHeader: b.invoiceHeader,
      image: b.image,
      localImage: b.localImage,
      installationDate: b.installationDate,
      expiryDate: b.expiryDate,
      openingCash: b.openingCash,
    );
  }
}
