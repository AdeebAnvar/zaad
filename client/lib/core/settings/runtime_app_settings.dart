import 'package:flutter/foundation.dart';
import 'package:pos/app/di.dart';
import 'package:pos/data/repository/settings_repository.dart';
import 'package:pos/domain/models/settings_model.dart';
import 'package:intl/intl.dart';

class RuntimeAppSettings {
  RuntimeAppSettings._();

  static final ValueNotifier<String> currencyCode = ValueNotifier<String>('INR');
  static SettingsModel? _settings;

  static String get currency => currencyCode.value.trim().isEmpty ? 'INR' : currencyCode.value.trim().toUpperCase();

  static int get decimalDigits {
    final raw = _settings?.decimalPoint.trim() ?? '';
    final parsed = int.tryParse(raw);
    if (parsed == null) return 2;
    return parsed.clamp(0, 6);
  }

  static bool _yesNo(String? v, {bool defaultValue = true}) {
    if (v == null || v.trim().isEmpty) return defaultValue;
    return v.trim().toUpperCase() == 'YES';
  }

  static bool get stockCheckEnabled => _yesNo(_settings?.stockCheck, defaultValue: true);
  static bool get stockShowEnabled => _yesNo(_settings?.stockShow, defaultValue: true);
  static bool get deliverySaleEnabled => _yesNo(_settings?.deliverySale, defaultValue: true);
  static bool get printImageInBillEnabled => _yesNo(_settings?.printImageInBill, defaultValue: true);
  static bool get printBranchNameInBillEnabled => _yesNo(_settings?.printBranchNameInBill, defaultValue: true);
  static String get qtyReducePassword => (_settings?.qtyReducePassword ?? '').trim();

  static String money(num amount, {int? decimals}) {
    final d = decimals ?? decimalDigits;
    return '$currency ${amount.toStringAsFixed(d)}';
  }

  static String formatDate(DateTime dt) {
    final f = (_settings?.dateFormat ?? 'dd-mm-yyyy').toLowerCase();
    final pattern = switch (f) {
      'yyyy-mm-dd' => 'yyyy-MM-dd',
      'mm-dd-yyyy' => 'MM-dd-yyyy',
      _ => 'dd-MM-yyyy',
    };
    return DateFormat(pattern).format(dt);
  }

  static String formatTime(DateTime dt) {
    final f = (_settings?.timeFormat ?? 'HOUR:MINUTE:SECOND').toUpperCase();
    final pattern = f == 'HOUR:MINUTE:AM/PM' ? 'hh:mm a' : 'HH:mm:ss';
    return DateFormat(pattern).format(dt);
  }

  static String formatDateTime(DateTime dt) {
    return '${formatDate(dt)} ${formatTime(dt)}';
  }

  static Future<void> refreshFromLocalSettings() async {
    try {
      final s = await locator<SettingsRepository>().getSettingsFromLocal();
      if (s != null) {
        _settings = s;
      }
      if (s != null && s.currency.trim().isNotEmpty) {
        currencyCode.value = s.currency.trim().toUpperCase();
      }
    } catch (_) {
      // Keep default fallback.
    }
  }
}

