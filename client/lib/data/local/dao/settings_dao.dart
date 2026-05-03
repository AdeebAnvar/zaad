part of '../drift_database.dart';

class Settings extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();

  TextColumn get currency => text()();
  TextColumn get decimalPoint => text()();
  TextColumn get dateFormat => text()();
  TextColumn get timeFormat => text()();
  TextColumn get unitPrice => text()();
  TextColumn get stockCheck => text()();
  TextColumn get stockShow => text()();
  TextColumn get settleCheckPending => text()();
  TextColumn get deliverySale => text()();
  TextColumn get apiKey => text()();
  TextColumn get customProduct => text()();
  TextColumn get language => text()();
  TextColumn get staffPin => text()();
  TextColumn get barcode => text()();
  TextColumn get drawerPassword => text()();
  TextColumn get paybackPassword => text()();
  TextColumn get purchase => text()();
  TextColumn get production => text()();
  TextColumn get minimumStock => text()();
  TextColumn get wastageUsage => text()();
  TextColumn get wastageUsageZeroStock => text()();
  TextColumn get customizeItem => text()();
  TextColumn get printType => text()();
  TextColumn get printLink => text()();
  TextColumn get mainPrintType => text()();
  TextColumn get mainPrintDetail => text()();
  TextColumn get printImageInBill => text()();
  TextColumn get printBranchNameInBill => text()();
  TextColumn get dineInTableOrderCount => text()();
  TextColumn get variation => text()();
  TextColumn get qtyReducePassword => text()();
  TextColumn get counterLoginLimit => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// =========================
/// DAO
/// =========================
@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// INSERT / UPDATE (single row)
  Future<void> saveSettings(SettingsModel s) async {
    await into(settings).insertOnConflictUpdate(_toCompanion(s));
  }

  /// GET SETTINGS
  Future<SettingsModel?> getSettings() async {
    final result = await select(settings).getSingleOrNull();
    if (result == null) return null;
    return _toModel(result);
  }

  /// CLEAR (optional)
  Future<void> clearSettings() async {
    await delete(settings).go();
  }

  /// =========================
  /// MAPPERS
  /// =========================

  SettingsCompanion _toCompanion(SettingsModel s) {
    return SettingsCompanion(
      id: const Value(1),
      currency: Value(s.currency),
      decimalPoint: Value(s.decimalPoint),
      dateFormat: Value(s.dateFormat),
      timeFormat: Value(s.timeFormat),
      unitPrice: Value(s.unitPrice),
      stockCheck: Value(s.stockCheck),
      stockShow: Value(s.stockShow),
      settleCheckPending: Value(s.settleCheckPending),
      deliverySale: Value(s.deliverySale),
      apiKey: Value(s.apiKey),
      customProduct: Value(s.customProduct),
      language: Value(s.language),
      staffPin: Value(s.staffPin),
      barcode: Value(s.barcode),
      drawerPassword: Value(s.drawerPassword),
      paybackPassword: Value(s.paybackPassword),
      purchase: Value(s.purchase),
      production: Value(s.production),
      minimumStock: Value(s.minimumStock),
      wastageUsage: Value(s.wastageUsage),
      wastageUsageZeroStock: Value(s.wastageUsageZeroStock),
      customizeItem: Value(s.customizeItem),
      printType: Value(s.printType),
      printLink: Value(s.printLink),
      mainPrintType: Value(s.mainPrintType),
      mainPrintDetail: Value(s.mainPrintDetail),
      printImageInBill: Value(s.printImageInBill),
      printBranchNameInBill: Value(s.printBranchNameInBill),
      dineInTableOrderCount: Value(s.dineInTableOrderCount),
      variation: Value(s.variation),
      qtyReducePassword: Value(s.qtyReducePassword),
      counterLoginLimit: Value(s.counterLoginLimit),
    );
  }

  SettingsModel _toModel(Setting s) {
    return SettingsModel(
      currency: s.currency,
      decimalPoint: s.decimalPoint,
      dateFormat: s.dateFormat,
      timeFormat: s.timeFormat,
      unitPrice: s.unitPrice,
      stockCheck: s.stockCheck,
      stockShow: s.stockShow,
      settleCheckPending: s.settleCheckPending,
      deliverySale: s.deliverySale,
      apiKey: s.apiKey,
      customProduct: s.customProduct,
      language: s.language,
      staffPin: s.staffPin,
      barcode: s.barcode,
      drawerPassword: s.drawerPassword,
      paybackPassword: s.paybackPassword,
      purchase: s.purchase,
      production: s.production,
      minimumStock: s.minimumStock,
      wastageUsage: s.wastageUsage,
      wastageUsageZeroStock: s.wastageUsageZeroStock,
      customizeItem: s.customizeItem,
      printType: s.printType,
      printLink: s.printLink,
      mainPrintType: s.mainPrintType,
      mainPrintDetail: s.mainPrintDetail,
      printImageInBill: s.printImageInBill,
      printBranchNameInBill: s.printBranchNameInBill,
      dineInTableOrderCount: s.dineInTableOrderCount,
      variation: s.variation,
      qtyReducePassword: s.qtyReducePassword,
      counterLoginLimit: s.counterLoginLimit,
    );
  }
}
