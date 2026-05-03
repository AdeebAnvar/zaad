import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/presentation/widgets/app_standard_dialog.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_outlined_button.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';

/// Modal to collect a payment against outstanding credit — matches app POS dialog styling.
Future<void> showPayCreditBillDialog(
  BuildContext context, {
  required Order order,
  VoidCallback? onPaymentRecorded,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => _PayCreditBillDialog(
      order: order,
      onPaymentRecorded: onPaymentRecorded,
    ),
  );
}

class _PayCreditBillDialog extends StatefulWidget {
  const _PayCreditBillDialog({
    required this.order,
    this.onPaymentRecorded,
  });

  final Order order;
  final VoidCallback? onPaymentRecorded;

  @override
  State<_PayCreditBillDialog> createState() => _PayCreditBillDialogState();
}

class _PayCreditBillDialogState extends State<_PayCreditBillDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String? _paymentType;
  bool _saving = false;

  static const _types = <MapEntry<String, String>>[
    MapEntry('cash', 'Cash'),
    MapEntry('card', 'Card'),
    MapEntry('online', 'Online'),
  ];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String get _customerLine {
    final o = widget.order;
    final name = o.customerName?.trim();
    final phone = o.customerPhone?.trim();
    if (name != null && name.isNotEmpty && phone != null && phone.isNotEmpty) {
      return '$name · $phone';
    }
    if (name != null && name.isNotEmpty) return name;
    if (phone != null && phone.isNotEmpty) return phone;
    return '—';
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim().replaceAll(',', '')) ?? 0;
    if (amount <= 0) return;

    setState(() => _saving = true);
    try {
      final repo = locator<OrderRepository>();
      final fresh = await repo.getOrderById(widget.order.id);
      if (!mounted) return;
      if (fresh == null) {
        CustomSnackBar.showError(message: 'Order not found');
        return;
      }
      if (fresh.creditAmount < 0.01) {
        CustomSnackBar.showWarning(message: 'No credit balance on this order');
        Navigator.of(context).pop();
        widget.onPaymentRecorded?.call();
        return;
      }

      final pay = math.min(amount, fresh.creditAmount);
      final type = _paymentType!;

      var cash = fresh.cashAmount;
      var card = fresh.cardAmount;
      var online = fresh.onlineAmount;
      switch (type) {
        case 'cash':
          cash += pay;
          break;
        case 'card':
          card += pay;
          break;
        case 'online':
          online += pay;
          break;
      }
      final newCredit = (fresh.creditAmount - pay).clamp(0.0, double.infinity);

      final updated = fresh.copyWith(
        cashAmount: cash,
        cardAmount: card,
        onlineAmount: online,
        creditAmount: newCredit,
      );
      await repo.updateOrder(updated);

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onPaymentRecorded?.call();
      CustomSnackBar.showSuccess(
        message: 'Recorded ${RuntimeAppSettings.money(pay)} (${_labelForType(type)})',
      );
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(message: 'Could not save: $e');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _labelForType(String type) {
    return _types.firstWhere((e) => e.key == type, orElse: () => const MapEntry('', '')).value;
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.order.creditAmount;
    final maxW = AppDialogLayout.maxContentWidth(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: AppDialogLayout.insetPadding(context),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Material(
            color: Colors.white,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    color: AppColors.primaryColor,
                    child: Text(
                      'PAY CREDIT BILL',
                      textAlign: TextAlign.center,
                      style: AppStyles.getBoldTextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ).copyWith(letterSpacing: 0.8),
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _label('Customer'),
                        const SizedBox(height: 6),
                        _readOnlyField(text: _customerLine),
                        const SizedBox(height: 16),
                        _label('Balance'),
                        const SizedBox(height: 6),
                        _readOnlyField(text: RuntimeAppSettings.money(balance)),
                        const SizedBox(height: 16),
                        _label('Payment Type'),
                        const SizedBox(height: 6),
                        FormField<String>(
                          validator: (_) => _paymentType == null || _paymentType!.isEmpty ? 'Required' : null,
                          builder: (state) {
                            return InputDecorator(
                              decoration: _fieldDecoration().copyWith(
                                errorText: state.errorText,
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isExpanded: true,
                                  value: _paymentType,
                                  hint: Text(
                                    'Select Payment Type',
                                    style: AppStyles.getRegularTextStyle(
                                      fontSize: 14,
                                      color: AppColors.hintFontColor,
                                    ),
                                  ),
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                  items: _types
                                      .map(
                                        (e) => DropdownMenuItem<String>(
                                          value: e.key,
                                          child: Text(e.value),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() => _paymentType = v);
                                    state.didChange(v);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _label('Amount'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                          ],
                          decoration: _fieldDecoration().copyWith(
                            hintText: '0.00',
                          ),
                          validator: (raw) {
                            final t = raw?.trim() ?? '';
                            if (t.isEmpty) return 'Required';
                            final v = double.tryParse(t.replaceAll(',', ''));
                            if (v == null || v <= 0) return 'Enter a valid amount';
                            if (v > balance + 0.009) return 'Cannot exceed balance';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        CustomOutlinedButton(
                          text: 'CANCEL',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        CustomButton(
                          text: 'SAVE',
                          elevation: 0,
                          isLoading: _saving,
                          width: 120,
                          onPressed: _saving ? null : _onSave,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: AppStyles.getMediumTextStyle(
        fontSize: 12,
        color: AppColors.textColor.withValues(alpha: 0.85),
      ),
    );
  }

  InputDecoration _fieldDecoration() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.divider),
    );
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      filled: false,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.65)),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      errorStyle: const TextStyle(fontSize: 11),
    );
  }

  Widget _readOnlyField({required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F1F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.hintFontColor),
      ),
    );
  }
}
