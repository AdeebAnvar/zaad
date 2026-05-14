import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/presentation/day_closing/day_closing_summary.dart';
import 'package:pos/presentation/widgets/app_standard_dialog.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_outlined_button.dart';

double _parseNonNegativeAmount(String raw) {
  final v = double.tryParse(raw.trim()) ?? 0.0;
  return v < 0 ? 0.0 : v;
}

/// Day-close cash reconciliation: expected (system) + excess − short = actual.
Future<DayClosingCloseCashReconciliation?> showDayClosingReconciliationDialog(
  BuildContext context, {
  required double expectedCashSaleAfterDiscount,
}) {
  return showDialog<DayClosingCloseCashReconciliation?>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        insetPadding: AppDialogLayout.insetPadding(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: AppDialogLayout.maxContentWidth(context)),
          child: _DayClosingReconciliationBody(
            expectedCashSaleAfterDiscount: expectedCashSaleAfterDiscount,
          ),
        ),
      );
    },
  );
}

class _DayClosingReconciliationBody extends StatefulWidget {
  const _DayClosingReconciliationBody({required this.expectedCashSaleAfterDiscount});

  final double expectedCashSaleAfterDiscount;

  @override
  State<_DayClosingReconciliationBody> createState() => _DayClosingReconciliationBodyState();
}

class _DayClosingReconciliationBodyState extends State<_DayClosingReconciliationBody> {
  late final TextEditingController _excessCtrl;
  late final TextEditingController _shortCtrl;

  static const _green = Color(0xFF28A745);
  static const _red = Color(0xFFDC3545);

  @override
  void initState() {
    super.initState();
    _excessCtrl = TextEditingController(text: '0');
    _shortCtrl = TextEditingController(text: '0');
    _excessCtrl.addListener(_onFieldChanged);
    _shortCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _excessCtrl.removeListener(_onFieldChanged);
    _shortCtrl.removeListener(_onFieldChanged);
    _excessCtrl.dispose();
    _shortCtrl.dispose();
    super.dispose();
  }

  double get _excess => _parseNonNegativeAmount(_excessCtrl.text);
  double get _short => _parseNonNegativeAmount(_shortCtrl.text);

  double get _actual => widget.expectedCashSaleAfterDiscount + _excess - _short;

  Widget _readOnlyAmountField(String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
      ),
      child: Text(
        value,
        style: AppStyles.getSemiBoldTextStyle(fontSize: 15, color: AppColors.textColor),
      ),
    );
  }

  Widget _amountInput({
    required String label,
    required TextEditingController controller,
    required Color labelColor,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.getSemiBoldTextStyle(fontSize: 13, color: labelColor),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor.withValues(alpha: 0.65)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor.withValues(alpha: 0.65)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor, width: 1.5),
            ),
          ),
          style: AppStyles.getSemiBoldTextStyle(fontSize: 15, color: AppColors.textColor),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Day Closing Reconciliation',
                  style: AppStyles.getBoldTextStyle(fontSize: 18, color: AppColors.textColor),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: AppColors.hintFontColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Expected Cash Sale',
            style: AppStyles.getSemiBoldTextStyle(fontSize: 13, color: AppColors.textColor),
          ),
          const SizedBox(height: 6),
          _readOnlyAmountField(RuntimeAppSettings.money(widget.expectedCashSaleAfterDiscount)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _amountInput(
                  label: 'Excess (+)',
                  controller: _excessCtrl,
                  labelColor: _green,
                  borderColor: _green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _amountInput(
                  label: 'Short (-)',
                  controller: _shortCtrl,
                  labelColor: _red,
                  borderColor: _red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Actual Cash Sale (Total)',
            style: AppStyles.getSemiBoldTextStyle(fontSize: 13, color: AppColors.textColor),
          ),
          const SizedBox(height: 6),
          _readOnlyAmountField(RuntimeAppSettings.money(_actual)),
          const SizedBox(height: 22),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 12,
            runSpacing: 8,
            children: [
              CustomOutlinedButton(
                width: 100,
                text: 'Cancel',
                onPressed: () => Navigator.pop(context),
              ),
              CustomButton(
                hugContent: true,
                text: 'Confirm & Close Day',
                onPressed: () {
                  Navigator.pop(
                    context,
                    DayClosingCloseCashReconciliation(
                      expectedCashSaleAfterDiscount: widget.expectedCashSaleAfterDiscount,
                      manualExcess: _excess,
                      manualShort: _short,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
