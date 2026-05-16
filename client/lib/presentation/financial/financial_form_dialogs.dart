import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/repository/financial_record_repository.dart';
import 'package:pos/domain/models/financial_record_type.dart';
import 'package:pos/presentation/financial/financial_form_theme.dart';
import 'package:pos/presentation/financial/financial_records_state.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';
import 'package:pos/presentation/widgets/log_filter_shell.dart';

Future<bool> showFinancialCreateDialog({
  required BuildContext context,
  required FinancialFormConfig config,
  required List<ExpenseCategoryOption> categories,
  required List<PaymentMethodOption> paymentMethods,
  required Future<void> Function(NewFinancialRecordInput input) onSave,
}) async {
  return await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierLabel: config.createDialogTitle,
        barrierColor: Colors.black.withValues(alpha: 0.35),
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (dialogContext, __, ___) => FinancialFormTheme.wrap(
          dialogContext,
          _FinancialCreateDialog(
            config: config,
            categories: categories,
            paymentMethods: paymentMethods,
            onSave: onSave,
          ),
        ),
        transitionBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
      ) ??
      false;
}

class _FinancialCreateDialog extends StatefulWidget {
  const _FinancialCreateDialog({
    required this.config,
    required this.categories,
    required this.paymentMethods,
    required this.onSave,
  });

  final FinancialFormConfig config;
  final List<ExpenseCategoryOption> categories;
  final List<PaymentMethodOption> paymentMethods;
  final Future<void> Function(NewFinancialRecordInput input) onSave;

  @override
  State<_FinancialCreateDialog> createState() => _FinancialCreateDialogState();
}

class _FinancialCreateDialogState extends State<_FinancialCreateDialog> {
  ExpenseCategoryOption? _category;
  PaymentMethodOption? _payment;
  final _companyName = TextEditingController();
  final _companyTrn = TextEditingController();
  final _invoiceNo = TextEditingController();
  final _description = TextEditingController();
  final _beforeVat = TextEditingController();
  final _vat = TextEditingController();
  final _finalAmount = TextEditingController();
  final _staffName = TextEditingController();
  final _days = TextEditingController();
  final _amount = TextEditingController();
  DateTime? _joiningDate;
  DateTime? _exitDate;
  bool _saving = false;

  @override
  void dispose() {
    _companyName.dispose();
    _companyTrn.dispose();
    _invoiceNo.dispose();
    _description.dispose();
    _beforeVat.dispose();
    _vat.dispose();
    _finalAmount.dispose();
    _staffName.dispose();
    _days.dispose();
    _amount.dispose();
    super.dispose();
  }

  void _recalcFinal() {
    final b = double.tryParse(_beforeVat.text.trim()) ?? 0;
    final v = double.tryParse(_vat.text.trim()) ?? 0;
    final sum = b + v;
    if (sum > 0) {
      _finalAmount.text = sum.toStringAsFixed(2);
    }
  }

  Future<void> _pickDate({required bool joining}) async {
    final initial = joining ? (_joiningDate ?? DateTime.now()) : (_exitDate ?? DateTime.now());
    final picked = await showLogFilterDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (joining) {
        _joiningDate = picked;
      } else {
        _exitDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (_saving) return;
    final type = widget.config.type;

    if (_payment == null) {
      CustomSnackBar.showWarning(message: 'Select payment type');
      return;
    }

    late final NewFinancialRecordInput input;

    if (type == FinancialRecordType.expense) {
      if (_category == null) {
        CustomSnackBar.showWarning(message: 'Select expense category');
        return;
      }
      final finalAmt = double.tryParse(_finalAmount.text.trim());
      if (finalAmt == null || finalAmt <= 0) {
        CustomSnackBar.showWarning(message: 'Enter final amount');
        return;
      }
      input = NewFinancialRecordInput(
        type: type,
        expenseCategoryId: _category!.id,
        expenseCategoryName: _category!.name,
        expenseCategorySlug: _category!.slug,
        paymentMethodId: _payment!.id,
        paymentMethodName: _payment!.name,
        companyName: _companyName.text.trim(),
        companyTrn: _companyTrn.text.trim(),
        invoiceNo: _invoiceNo.text.trim(),
        description: _description.text.trim(),
        amountBeforeVat: double.tryParse(_beforeVat.text.trim()) ?? 0,
        vatAmount: double.tryParse(_vat.text.trim()) ?? 0,
        finalAmount: finalAmt,
      );
    } else if (type == FinancialRecordType.salary) {
      if (_staffName.text.trim().isEmpty) {
        CustomSnackBar.showWarning(message: 'Enter staff name');
        return;
      }
      final finalAmt = double.tryParse(_amount.text.trim());
      if (finalAmt == null || finalAmt <= 0) {
        CustomSnackBar.showWarning(message: 'Enter amount');
        return;
      }
      input = NewFinancialRecordInput(
        type: type,
        paymentMethodId: _payment!.id,
        paymentMethodName: _payment!.name,
        staffName: _staffName.text.trim(),
        joiningDate: _joiningDate,
        exitDate: _exitDate,
        days: int.tryParse(_days.text.trim()),
        description: _description.text.trim(),
        finalAmount: finalAmt,
      );
    } else {
      if (_description.text.trim().isEmpty) {
        CustomSnackBar.showWarning(message: 'Enter description / source');
        return;
      }
      final finalAmt = double.tryParse(_amount.text.trim());
      if (finalAmt == null || finalAmt <= 0) {
        CustomSnackBar.showWarning(message: 'Enter amount');
        return;
      }
      input = NewFinancialRecordInput(
        type: type,
        paymentMethodId: _payment!.id,
        paymentMethodName: _payment!.name,
        description: _description.text.trim(),
        finalAmount: finalAmt,
      );
    }

    setState(() => _saving = true);
    try {
      await widget.onSave(input);
      if (!mounted) return;
      Navigator.pop(context, true);
      CustomSnackBar.showSuccess(message: 'Saved successfully');
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.showWarning(message: 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.config.type;
    return Center(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 520,
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.88),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _iconForType(type),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.config.createDialogTitle,
                          style: AppStyles.getBoldTextStyle(fontSize: 17, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (type == FinancialRecordType.expense) ...[
                          _dropdown<ExpenseCategoryOption>(
                            label: 'Expense Category',
                            hint: 'Select Expense Category',
                            value: _category,
                            items: widget.categories,
                            itemLabel: (c) => c.name,
                            onChanged: (v) => setState(() => _category = v),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _field(_companyName, label: 'Company Name')),
                              const SizedBox(width: 12),
                              Expanded(child: _field(_companyTrn, label: 'Company TRN')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _field(_description, label: 'Description', maxLines: 3),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _dropdown<PaymentMethodOption>(
                                  label: 'Payment Type',
                                  hint: 'Select Payment type',
                                  value: _payment,
                                  items: widget.paymentMethods,
                                  itemLabel: (p) => p.name,
                                  onChanged: (v) => setState(() => _payment = v),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: _field(_invoiceNo, label: 'Invoice No')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _field(
                                  _beforeVat,
                                  label: 'Total Before VAT',
                                  keyboard: TextInputType.number,
                                  onChanged: (_) => _recalcFinal(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _field(
                                  _vat,
                                  label: 'VAT Amount',
                                  keyboard: TextInputType.number,
                                  onChanged: (_) => _recalcFinal(),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _field(_finalAmount, label: 'Final Amount', keyboard: TextInputType.number),
                        ] else if (type == FinancialRecordType.salary) ...[
                          _field(_staffName, label: 'Staff Name'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _dateField(
                                  label: 'Joining Date',
                                  value: _joiningDate,
                                  onTap: () => _pickDate(joining: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _dateField(
                                  label: 'Exit Date',
                                  value: _exitDate,
                                  onTap: () => _pickDate(joining: false),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _field(_days, label: 'No. of Days', keyboard: TextInputType.number),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _field(_amount, label: 'Amount', keyboard: TextInputType.number),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _field(_description, label: 'Description', maxLines: 3),
                          const SizedBox(height: 12),
                          _dropdown<PaymentMethodOption>(
                            label: 'Payment Type',
                            hint: 'Select Payment type',
                            value: _payment,
                            items: widget.paymentMethods,
                            itemLabel: (p) => p.name,
                            onChanged: (v) => setState(() => _payment = v),
                          ),
                        ] else ...[
                          _dropdown<PaymentMethodOption>(
                            label: 'Payment Type',
                            hint: 'Select Payment type',
                            value: _payment,
                            items: widget.paymentMethods,
                            itemLabel: (p) => p.name,
                            onChanged: (v) => setState(() => _payment = v),
                          ),
                          const SizedBox(height: 12),
                          _field(_amount, label: 'Amount', keyboard: TextInputType.number),
                          const SizedBox(height: 12),
                          _field(_description, label: 'Description / Source', maxLines: 4),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryColor,
                            side: const BorderSide(color: AppColors.primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _saving ? null : () => Navigator.pop(context),
                          child: const Text('CANCEL'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _saving ? null : _submit,
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(type == FinancialRecordType.otherIncome ? 'SAVE INCOME' : 'SAVE'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForType(FinancialRecordType type) => switch (type) {
        FinancialRecordType.expense => Icons.receipt_long_outlined,
        FinancialRecordType.salary => Icons.payments_outlined,
        FinancialRecordType.otherIncome => Icons.trending_up_outlined,
      };

  Widget _field(
    TextEditingController controller, {
    required String label,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.textColor),
      inputFormatters: keyboard == TextInputType.number
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : null,
      onChanged: onChanged,
      decoration: FinancialFormTheme.fieldDecoration(label),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required VoidCallback onTap,
  }) {
    final fmt = DateFormat('dd-MM-yyyy');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: InputDecorator(
        decoration: FinancialFormTheme.fieldDecoration(label).copyWith(
          suffixIcon: Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primaryColor),
        ),
        child: Text(
          value == null ? 'dd-mm-yyyy' : fmt.format(value),
          style: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.textColor),
        ),
      ),
    );
  }

  T? _resolveDropdownValue<T>(T? selected, List<T> items) {
    if (selected == null || items.isEmpty) return null;
    for (final item in items) {
      if (item == selected) return item;
    }
    return null;
  }

  Widget _dropdown<T>({
    required String label,
    required String hint,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    final resolved = _resolveDropdownValue(value, items);
    return DropdownButtonFormField<T>(
      key: ValueKey('${label}_${resolved?.hashCode ?? 'none'}'),
      value: resolved,
      hint: Text(
        hint,
        style: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.hintFontColor),
      ),
      isExpanded: true,
      borderRadius: BorderRadius.circular(10),
      dropdownColor: Colors.white,
      iconEnabledColor: AppColors.primaryColor,
      style: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.textColor),
      decoration: FinancialFormTheme.fieldDecoration(label),
      items: items
          .map(
            (e) => DropdownMenuItem<T>(
              value: e,
              child: Text(
                itemLabel(e),
                style: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.textColor),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: items.isEmpty ? null : onChanged,
    );
  }
}
