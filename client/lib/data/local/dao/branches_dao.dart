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

  /// Branch-wide default opening balance (from server / user edit); survives day close.
  IntColumn get defaultOpeningCash => integer().withDefault(const Constant(0))();

  /// Last pickup token from server bootstrap / COMPANY_SNAPSHOT (`last_token_no`).
  IntColumn get lastTokenNo => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// =========================
/// DAO
/// =========================
@DriftAccessor(tables: [Branches])
class BranchesDao extends DatabaseAccessor<AppDatabase>
    with _$BranchesDaoMixin {
  BranchesDao(super.db);

  /// UPSERT (sync safe)
  Future<void> insertBranches(List<BranchModel> list,
      {bool downloadRemoteImages = true}) async {
    final companions = await Future.wait(
      list.map(
          (b) => _toCompanion(b, downloadRemoteImages: downloadRemoteImages)),
    );
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        branches,
        companions,
      );
    });
  }

  /// Preserved opening balances without Drift row mapping (safe on legacy NULL columns).
  Future<Map<int, int>> getPreservedOpeningCashByBranchId() async {
    final rows = await customSelect(
      '''
      SELECT id,
             CASE
               WHEN COALESCE(default_opening_cash, 0) > 0 THEN default_opening_cash
               WHEN COALESCE(opening_cash, 0) > 0 THEN opening_cash
               ELSE 0
             END AS effective
      FROM branches
      ''',
      readsFrom: {branches},
    ).get();
    return {for (final row in rows) row.read<int>('id'): row.read<int>('effective')};
  }

  /// GET ALL
  Future<List<BranchModel>> getAllBranches() async {
    final data = await select(branches).get();
    return data.map(_toModel).toList();
  }

  /// GET ONE by [branchId] (server id / primary key)
  Future<BranchModel?> getBranchById(int branchId) async {
    final row = await (select(branches)..where((b) => b.id.equals(branchId)))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  /// DELETE (sync)
  Future<void> deleteBranches(List<int> ids) async {
    await (delete(branches)..where((b) => b.id.isIn(ids))).go();
  }

  /// Keeps the highest known pickup token for LAN SUB seeding via COMPANY_SNAPSHOT.
  Future<void> setLastTokenNoIfHigher(int branchId, int tokenNo) async {
    if (tokenNo <= 0) return;
    final row = await (select(branches)..where((b) => b.id.equals(branchId)))
        .getSingleOrNull();
    if (row == null) return;
    final existing = row.lastTokenNo ?? 0;
    if (tokenNo <= existing) return;
    await (update(branches)..where((b) => b.id.equals(branchId))).write(
      BranchesCompanion(lastTokenNo: Value(tokenNo)),
    );
  }

  /// Save opening cash and keep it as the branch default (drawer + day closing).
  Future<void> setBranchOpeningBalance({
    required int branchId,
    required int amount,
  }) async {
    await (update(branches)..where((b) => b.id.equals(branchId))).write(
      BranchesCompanion(
        openingCash: Value(amount),
        defaultOpeningCash: Value(amount),
      ),
    );
  }

  /// =========================
  /// MAPPERS
  /// =========================

  Future<BranchesCompanion> _toCompanion(BranchModel b,
      {required bool downloadRemoteImages}) async {
    String localImage = '';
    if (downloadRemoteImages && b.image.trim().isNotEmpty) {
      localImage = await _downloadBranchImage(
              b.image, 'Branch_${b.id}_${b.branchName}') ??
          '';
    } else {
      localImage = b.localImage;
    }
    final existingRow = await customSelect(
      '''
      SELECT COALESCE(default_opening_cash, 0) AS default_opening_cash,
             COALESCE(opening_cash, 0) AS opening_cash,
             last_token_no
      FROM branches WHERE id = ?
      ''',
      variables: [Variable.withInt(b.id)],
      readsFrom: {branches},
    ).getSingleOrNull();
    final existingDefault = existingRow?.read<int>('default_opening_cash') ?? 0;
    final existingOpening = existingRow?.read<int>('opening_cash') ?? 0;
    final resolvedBalance = existingDefault > 0
        ? existingDefault
        : (existingOpening > 0
            ? existingOpening
            : (b.defaultOpeningCash ?? b.openingCash ?? 0));
    final incomingToken = b.lastTokenNo ?? 0;
    final existingToken = existingRow?.read<int?>('last_token_no') ?? 0;
    final resolvedToken = incomingToken > (existingToken ?? 0)
        ? incomingToken
        : (existingToken ?? 0);

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
      openingCash: Value(resolvedBalance),
      defaultOpeningCash: Value(resolvedBalance),
      localImage: Value(localImage),
      lastTokenNo: resolvedToken > 0 ? Value(resolvedToken) : const Value.absent(),
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
      defaultOpeningCash: b.defaultOpeningCash,
      lastTokenNo: b.lastTokenNo,
    );
  }
}
