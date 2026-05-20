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

/// Day-close reconciliation: expected (system) + excess − short = actual, per payment channel.
Future<DayClosingCloseReconciliation?> showDayClosingReconciliationDialog(
  BuildContext context, {
  required DayClosingSummary summary,
}) {
  return showDialog<DayClosingCloseReconciliation?>(
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
          child: _DayClosingReconciliationBody(summary: summary),
        ),
      );
    },
  );
}

class _DayClosingReconciliationBody extends StatefulWidget {
  const _DayClosingReconciliationBody({required this.summary});

  final DayClosingSummary summary;

  @override
  State<_DayClosingReconciliationBody> createState() => _DayClosingReconciliationBodyState();
}

class _ChannelFields {
  _ChannelFields({
    required this.label,
    required this.expected,
    required this.excessCtrl,
    required this.shortCtrl,
  });

  final String label;
  final double expected;
  final TextEditingController excessCtrl;
  final TextEditingController shortCtrl;

  double get excess => _parseNonNegativeAmount(excessCtrl.text);
  double get short => _parseNonNegativeAmount(shortCtrl.text);
  double get actual => expected + excess - short;
}

class _DayClosingReconciliationBodyState extends State<_DayClosingReconciliationBody> {
  static const _green = Color(0xFF28A745);
  static const _red = Color(0xFFDC3545);

  late final List<_ChannelFields> _channels;

  @override
  void initState() {
    super.initState();
    final s = widget.summary;
    _channels = [
      _ChannelFields(
        label: 'CASH',
        expected: s.cashSaleAfterDiscount,
        excessCtrl: TextEditingController(text: '0'),
        shortCtrl: TextEditingController(text: '0'),
      ),
      _ChannelFields(
        label: 'CARD',
        expected: s.cardSale,
        excessCtrl: TextEditingController(text: '0'),
        shortCtrl: TextEditingController(text: '0'),
      ),
      _ChannelFields(
        label: 'CREDIT',
        expected: s.creditSale,
        excessCtrl: TextEditingController(text: '0'),
        shortCtrl: TextEditingController(text: '0'),
      ),
      _ChannelFields(
        label: 'ONLINE',
        expected: s.onlineSale,
        excessCtrl: TextEditingController(text: '0'),
        shortCtrl: TextEditingController(text: '0'),
      ),
    ];
    for (final ch in _channels) {
      ch.excessCtrl.addListener(_onFieldChanged);
      ch.shortCtrl.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    for (final ch in _channels) {
      ch.excessCtrl.removeListener(_onFieldChanged);
      ch.shortCtrl.removeListener(_onFieldChanged);
      ch.excessCtrl.dispose();
      ch.shortCtrl.dispose();
    }
    super.dispose();
  }

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

  Widget _channelSection(_ChannelFields ch) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            ch.label,
            style: AppStyles.getBoldTextStyle(fontSize: 14, color: AppColors.textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Expected ${ch.label} Sale',
            style: AppStyles.getSemiBoldTextStyle(fontSize: 12, color: AppColors.hintFontColor),
          ),
          const SizedBox(height: 4),
          _readOnlyAmountField(RuntimeAppSettings.money(ch.expected)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _amountInput(
                  label: '${ch.label} Excess (+)',
                  controller: ch.excessCtrl,
                  labelColor: _green,
                  borderColor: _green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _amountInput(
                  label: '${ch.label} Short (-)',
                  controller: ch.shortCtrl,
                  labelColor: _red,
                  borderColor: _red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Actual ${ch.label} Sale',
            style: AppStyles.getSemiBoldTextStyle(fontSize: 12, color: AppColors.hintFontColor),
          ),
          const SizedBox(height: 4),
          _readOnlyAmountField(RuntimeAppSettings.money(ch.actual)),
        ],
      ),
    );
  }

  DayClosingCloseReconciliation _buildResult() {
    final cash = _channels[0];
    final card = _channels[1];
    final credit = _channels[2];
    final online = _channels[3];
    return DayClosingCloseReconciliation(
      cashExpected: cash.expected,
      cashExcess: cash.excess,
      cashShort: cash.short,
      cardExpected: card.expected,
      cardExcess: card.excess,
      cardShort: card.short,
      creditExpected: credit.expected,
      creditExcess: credit.excess,
      creditShort: credit.short,
      onlineExpected: online.expected,
      onlineExcess: online.excess,
      onlineShort: online.short,
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
          const SizedBox(height: 4),
          Text(
            'Enter excess or short for each payment type. Actual = expected + excess − short.',
            style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.hintFontColor),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: (MediaQuery.sizeOf(context).height * 0.52).clamp(240.0, 520.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final ch in _channels) _channelSection(ch),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
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
                onPressed: () => Navigator.pop(context, _buildResult()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
