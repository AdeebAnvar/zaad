import 'package:flutter/material.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/presentation/widgets/app_standard_dialog.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';

const List<String> kLogPaymentTypesStandard = ['CREDIT', 'CASH', 'CARD'];
const List<String> kLogPaymentTypesWithOnline = ['ONLINE', 'CASH', 'CARD', 'CREDIT'];

/// Primary payment slug for a log row (single-tender display).
String paymentTypeSlugFromOrder(
  Order order, {
  bool includeOnline = false,
  String fallback = 'CREDIT',
}) {
  final entries = <MapEntry<String, double>>[
    MapEntry('CASH', order.cashAmount),
    MapEntry('CARD', order.cardAmount),
    MapEntry('CREDIT', order.creditAmount),
    if (includeOnline) MapEntry('ONLINE', order.onlineAmount),
  ];
  entries.sort((a, b) => b.value.compareTo(a.value));
  if (entries.isNotEmpty && entries.first.value > 0.009) {
    return entries.first.key;
  }
  return includeOnline && fallback == 'CREDIT' ? 'ONLINE' : fallback;
}

/// Compact payment-type dropdown for take-away, dine-in, delivery, and driver logs.
class LogPaymentTypeDropdown extends StatefulWidget {
  const LogPaymentTypeDropdown({
    super.key,
    required this.order,
    required this.onPaymentTypeChanged,
    this.includeOnline = false,
    this.confirmBeforeChange = true,
    this.label = 'Payment',
  });

  final Order order;
  final Future<void> Function(String paymentType) onPaymentTypeChanged;
  final bool includeOnline;
  final bool confirmBeforeChange;
  final String label;

  @override
  State<LogPaymentTypeDropdown> createState() => _LogPaymentTypeDropdownState();
}

class _LogPaymentTypeDropdownState extends State<LogPaymentTypeDropdown> {
  late String _paymentType;
  int _revision = 0;

  List<String> get _options =>
      widget.includeOnline ? kLogPaymentTypesWithOnline : kLogPaymentTypesStandard;

  @override
  void initState() {
    super.initState();
    _syncFromOrder();
  }

  @override
  void didUpdateWidget(covariant LogPaymentTypeDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.order.id != oldWidget.order.id ||
        widget.order.cashAmount != oldWidget.order.cashAmount ||
        widget.order.cardAmount != oldWidget.order.cardAmount ||
        widget.order.creditAmount != oldWidget.order.creditAmount ||
        widget.order.onlineAmount != oldWidget.order.onlineAmount) {
      _syncFromOrder();
    }
  }

  void _syncFromOrder() {
    _paymentType = paymentTypeSlugFromOrder(
      widget.order,
      includeOnline: widget.includeOnline,
      fallback: widget.includeOnline ? 'ONLINE' : 'CREDIT',
    );
  }

  InputDecoration _compactDecoration(BuildContext context) {
    return CustomFormFieldDecoration.dropdownDecoration(context).copyWith(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }

  @override
  Widget build(BuildContext context) {
    final valid = _options.contains(_paymentType) ? _paymentType : _options.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.hintFontColor),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          key: ValueKey<String>('log_pay_${widget.order.id}_$_revision'),
          isExpanded: true,
          isDense: true,
          initialValue: valid,
          style: AppStyles.getRegularTextStyle(fontSize: 13).copyWith(fontWeight: FontWeight.w500),
          iconEnabledColor: AppColors.textColor,
          dropdownColor: Colors.white,
          decoration: _compactDecoration(context),
          items: _options
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(
                    s,
                    style: AppStyles.getRegularTextStyle(fontSize: 13)
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) => _onSelected(v, valid),
        ),
      ],
    );
  }

  Future<void> _onSelected(String? v, String current) async {
    if (v == null || v == current) return;

    if (widget.confirmBeforeChange) {
      final confirmed = await showAppConfirmDialog(
        context,
        title: 'Confirm Payment Type Change',
        message: 'Change payment type to "$v"?',
      );
      if (!mounted) return;
      if (confirmed != true) {
        setState(() => _revision++);
        return;
      }
    }

    await widget.onPaymentTypeChanged(v);
  }
}
