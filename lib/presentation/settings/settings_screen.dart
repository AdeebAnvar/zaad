import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/repository/settings_repository.dart';
import 'package:pos/domain/models/settings_model.dart';
import 'package:pos/presentation/widgets/app_dropdown_field.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

/// Maps Drift / [SettingsModel] fields to visible labels; third element reads value; fourth = obscure.
typedef _FieldDef = (String id, String label, String Function(SettingsModel) get, bool obscure);

const List<_FieldDef> _kSettingsFieldDefs = [
  ('currency', 'Currency', _gCurrency, false),
  ('decimalPoint', 'Decimal point', _gDecimalPoint, false),
  ('dateFormat', 'Date format', _gDateFormat, false),
  ('timeFormat', 'Time format', _gTimeFormat, false),
  ('unitPrice', 'Unit price', _gUnitPrice, false),
  ('stockCheck', 'Stock check', _gStockCheck, false),
  ('stockShow', 'Stock show in sale page', _gStockShow, false),
  ('settleCheckPending', 'Settle check pending', _gSettleCheckPending, false),
  ('deliverySale', 'Delivery sale', _gDeliverySale, false),
  ('apiKey', 'API key', _gApiKey, true),
  ('customProduct', 'Custom product', _gCustomProduct, false),
  ('language', 'Language', _gLanguage, false),
  ('staffPin', 'Staff PIN', _gStaffPin, true),
  ('barcode', 'Barcode', _gBarcode, false),
  ('drawerPassword', 'Drawer password', _gDrawerPassword, true),
  ('paybackPassword', 'Payback password', _gPaybackPassword, true),
  ('purchase', 'Purchase and suppliers', _gPurchase, false),
  ('production', 'Production', _gProduction, false),
  ('minimumStock', 'Minimum stock alert', _gMinimumStock, false),
  ('wastageUsage', 'Wastage usage', _gWastageUsage, false),
  ('wastageUsageZeroStock', 'Wastage usage (zero stock)', _gWastageUsageZeroStock, false),
  ('customizeItem', 'Customize item', _gCustomizeItem, false),
  ('printType', 'Print type', _gPrintType, false),
  ('printLink', 'Print link', _gPrintLink, false),
  ('mainPrintType', 'Main print type', _gMainPrintType, false),
  ('mainPrintDetail', 'Main print detail', _gMainPrintDetail, false),
  ('printImageInBill', 'Print logo in bill', _gPrintImageInBill, false),
  ('printBranchNameInBill', 'Print branch name in bill', _gPrintBranchNameInBill, false),
  ('dineInTableOrderCount', 'Dine-in table order count', _gDineInTableOrderCount, false),
  ('variation', 'Variation', _gVariation, false),
  ('qtyReducePassword', 'Qty reduce password', _gQtyReducePassword, true),
  ('counterLoginLimit', 'Counter login limit', _gCounterLoginLimit, false),
];

String _gCurrency(SettingsModel s) => s.currency;
String _gDecimalPoint(SettingsModel s) => s.decimalPoint;
String _gDateFormat(SettingsModel s) => s.dateFormat;
String _gTimeFormat(SettingsModel s) => s.timeFormat;
String _gUnitPrice(SettingsModel s) => s.unitPrice;
String _gStockCheck(SettingsModel s) => s.stockCheck;
String _gStockShow(SettingsModel s) => s.stockShow;
String _gSettleCheckPending(SettingsModel s) => s.settleCheckPending;
String _gDeliverySale(SettingsModel s) => s.deliverySale;
String _gApiKey(SettingsModel s) => s.apiKey;
String _gCustomProduct(SettingsModel s) => s.customProduct;
String _gLanguage(SettingsModel s) => s.language;
String _gStaffPin(SettingsModel s) => s.staffPin;
String _gBarcode(SettingsModel s) => s.barcode;
String _gDrawerPassword(SettingsModel s) => s.drawerPassword;
String _gPaybackPassword(SettingsModel s) => s.paybackPassword;
String _gPurchase(SettingsModel s) => s.purchase;
String _gProduction(SettingsModel s) => s.production;
String _gMinimumStock(SettingsModel s) => s.minimumStock;
String _gWastageUsage(SettingsModel s) => s.wastageUsage;
String _gWastageUsageZeroStock(SettingsModel s) => s.wastageUsageZeroStock;
String _gCustomizeItem(SettingsModel s) => s.customizeItem;
String _gPrintType(SettingsModel s) => s.printType;
String _gPrintLink(SettingsModel s) => s.printLink;
String _gMainPrintType(SettingsModel s) => s.mainPrintType;
String _gMainPrintDetail(SettingsModel s) => s.mainPrintDetail;
String _gPrintImageInBill(SettingsModel s) => s.printImageInBill;
String _gPrintBranchNameInBill(SettingsModel s) => s.printBranchNameInBill;
String _gDineInTableOrderCount(SettingsModel s) => s.dineInTableOrderCount;
String _gVariation(SettingsModel s) => s.variation;
String _gQtyReducePassword(SettingsModel s) => s.qtyReducePassword;
String _gCounterLoginLimit(SettingsModel s) => s.counterLoginLimit;

const List<String> _kYesNo = ['YES', 'NO'];

const Map<String, List<String>> _kDropdownOptionsByField = {
  'dateFormat': ['yyyy-mm-dd', 'mm-dd-yyyy', 'dd-mm-yyyy'],
  'timeFormat': ['HOUR:MINUTE:SECOND', 'HOUR:MINUTE:AM/PM'],
  'unitPrice': _kYesNo,
  'staffPin': _kYesNo,
  'stockCheck': _kYesNo,
  'stockShow': _kYesNo,
  'settleCheckPending': _kYesNo,
  'deliverySale': _kYesNo,
  'barcode': _kYesNo,
  'purchase': _kYesNo,
  'production': _kYesNo,
  'minimumStock': _kYesNo,
  'wastageUsage': _kYesNo,
  'printType': ['direct', 'popup'],
  'mainPrintType': ['usb', 'lan'],
  'printImageInBill': _kYesNo,
  'printBranchNameInBill': _kYesNo,
};

String? _normalizeDropdownValue(String fieldId, String raw) {
  final options = _kDropdownOptionsByField[fieldId];
  if (options == null) return null;
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return options.first;
  for (final o in options) {
    if (o.toLowerCase() == trimmed.toLowerCase()) {
      return o;
    }
  }
  return options.first;
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _settingsLoaded = false;
  SettingsModel? _settingsModel;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final d in _kSettingsFieldDefs) {
      _controllers[d.$1] = TextEditingController();
    }
    _loadSettings();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final s = await locator<SettingsRepository>().getSettingsFromLocal();
    if (!mounted) return;
    setState(() {
      _settingsModel = s;
      for (final d in _kSettingsFieldDefs) {
        _controllers[d.$1]!.text = s != null ? d.$3(s) : '';
      }
      _settingsLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Settings',
      body: !_settingsLoaded
          ? const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : Center(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  if (_settingsModel == null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'No server settings in local storage yet. Run sync after login.',
                        style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.hintFontColor),
                      ),
                    ),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 10.0;
                      const minItemWidth = 240.0;
                      final columns = (constraints.maxWidth / minItemWidth).floor().clamp(1, 4);
                      final itemWidth = (constraints.maxWidth - (spacing * (columns - 1))) / columns;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: _kSettingsFieldDefs
                            .map(
                              (d) => SizedBox(
                                width: itemWidth,
                                child: _kDropdownOptionsByField.containsKey(d.$1)
                                    ? AppDropdownField<String>(
                                        labelText: d.$2,
                                        value: _normalizeDropdownValue(
                                          d.$1,
                                          _controllers[d.$1]!.text,
                                        ),
                                        items: _kDropdownOptionsByField[d.$1]!
                                            .map(
                                              (v) => DropdownMenuItem<String>(
                                                value: v,
                                                child: Text(v),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (v) {
                                          if (v == null) return;
                                          setState(() {
                                            _controllers[d.$1]!.text = v;
                                          });
                                        },
                                      )
                                    : CustomTextField(
                                        showAsUpperLabel: true,
                                        labelText: d.$2,
                                        controller: _controllers[d.$1],
                                        obscureText: d.$4,
                                      ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
