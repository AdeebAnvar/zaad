import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/presentation/dine_in_log/dine_in_log_cubit.dart';
import 'package:pos/presentation/widgets/app_snackbar.dart';
import 'package:pos/presentation/widgets/app_standard_dialog.dart';
import 'package:pos/presentation/widgets/custom_button.dart';

/// Pick lines to move to a new bill (same table reference).
Future<void> showDineInSplitBillUi(BuildContext context, Order order) async {
  final cartRepo = locator<CartRepository>();
  final items = await cartRepo.getCartItemsByCartId(order.cartId);
  if (!context.mounted) return;
  if (items == null || items.length < 2) {
    showAppSnackBar(context, 'Need at least two lines to split', isError: true);
    return;
  }

  await showAppAdaptiveSheetOrDialog<void>(
    context: context,
    breakpoint: 900,
    title: Text('Split bill', style: AppStyles.getSemiBoldTextStyle(fontSize: 18)),
    dialogActions: (dCtx) => [
      TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Close')),
    ],
    child: BlocProvider.value(
      value: context.read<DineInLogCubit>(),
      child: _SplitBillBody(order: order, cartItems: items),
    ),
  );
}

class _SplitBillBody extends StatefulWidget {
  const _SplitBillBody({required this.order, required this.cartItems});

  final Order order;
  final List<CartItem> cartItems;

  @override
  State<_SplitBillBody> createState() => _SplitBillBodyState();
}

class _SplitBillBodyState extends State<_SplitBillBody> {
  final _itemRepo = locator<ItemRepository>();
  final Set<int> _selected = {};
  bool _busy = false;
  Map<int, String>? _labels;

  @override
  void initState() {
    super.initState();
    _loadLabels();
  }

  Future<void> _loadLabels() async {
    final map = <int, String>{};
    for (final r in widget.cartItems) {
      final item = await _itemRepo.fetchItemByIdFromLocal(r.itemId);
      var name = item?.name ?? 'Item #${r.itemId}';
      if (r.itemVariantId != null) {
        final v = await _itemRepo.fetchVariantById(r.itemVariantId!);
        if (v != null) name = '$name · ${v.name}';
      }
      map[r.id] = '$name  ·  ×${r.quantity}  ·  ${RuntimeAppSettings.money(r.total)}';
    }
    if (mounted) setState(() => _labels = map);
  }

  bool get _valid {
    final n = widget.cartItems.length;
    return _selected.isNotEmpty && _selected.length < n;
  }

  Future<void> _confirm() async {
    if (!_valid || _busy) return;
    setState(() => _busy = true);
    final cubit = context.read<DineInLogCubit>();
    final err = await cubit.splitDineInBill(
      sourceOrderId: widget.order.id,
      cartItemIdsToMove: _selected.toList(),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      Navigator.of(context).pop();
      showAppSnackBar(context, 'Bill split. New receipt created.');
    } else {
      showAppSnackBar(context, err, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final labels = _labels;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Invoice ${widget.order.invoiceNumber}',
            style: AppStyles.getMediumTextStyle(fontSize: 14, color: AppColors.hintFontColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Tick lines to move to a new bill. Order-level discounts are cleared; totals follow lines.',
            style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.textColor),
          ),
          const SizedBox(height: 12),
          if (labels == null)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: widget.cartItems.map((r) {
                final checked = _selected.contains(r.id);
                return CheckboxListTile(
                  value: checked,
                  onChanged: _busy
                      ? null
                      : (v) {
                          setState(() {
                            if (v == true) {
                              _selected.add(r.id);
                            } else {
                              _selected.remove(r.id);
                            }
                          });
                        },
                  title: Text(
                    labels[r.id] ?? 'Line #${r.id}',
                    style: AppStyles.getRegularTextStyle(fontSize: 14),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          CustomButton(
            width: double.infinity,
            onPressed: (_busy || !_valid || labels == null) ? null : _confirm,
            text: _busy ? 'Please wait…' : 'Split bill',
          ),
        ],
      ),
    );
  }
}

/// Merge another open bill at the same table into [target].
Future<void> showDineInMergeBillUi(
  BuildContext context,
  Order target,
  List<Order> candidates,
) async {
  if (candidates.isEmpty) {
    await showAppMessageDialog(
      context,
      title: 'Merge bill',
      message: 'No other open bills (KOT / placed) at this table to merge.',
    );
    return;
  }

  await showAppAdaptiveSheetOrDialog<void>(
    context: context,
    breakpoint: 900,
    title: Text('Merge into ${target.invoiceNumber}',
        style: AppStyles.getSemiBoldTextStyle(fontSize: 18)),
    dialogActions: (dCtx) => [
      TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Close')),
    ],
    child: BlocProvider.value(
      value: context.read<DineInLogCubit>(),
      child: _MergeBillBody(target: target, candidates: candidates),
    ),
  );
}

class _MergeBillBody extends StatefulWidget {
  const _MergeBillBody({required this.target, required this.candidates});

  final Order target;
  final List<Order> candidates;

  @override
  State<_MergeBillBody> createState() => _MergeBillBodyState();
}

class _MergeBillBodyState extends State<_MergeBillBody> {
  int? _sourceId;
  bool _busy = false;

  Future<void> _confirm() async {
    final sid = _sourceId;
    if (sid == null || _busy) return;
    setState(() => _busy = true);
    final cubit = context.read<DineInLogCubit>();
    final err = await cubit.mergeDineInBill(
      targetOrderId: widget.target.id,
      sourceOrderId: sid,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      Navigator.of(context).pop();
      showAppSnackBar(context, 'Bills merged into ${widget.target.invoiceNumber}.');
    } else {
      showAppSnackBar(context, err, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'All lines and payments from the selected bill move into ${widget.target.invoiceNumber}. The other bill is removed.',
            style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.textColor),
          ),
          const SizedBox(height: 12),
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: widget.candidates.map((o) {
              return RadioListTile<int>(
                value: o.id,
                groupValue: _sourceId,
                onChanged: _busy ? null : (v) => setState(() => _sourceId = v),
                title: Text(
                  o.invoiceNumber,
                  style: AppStyles.getMediumTextStyle(fontSize: 15),
                ),
                subtitle: Text(
                  '${RuntimeAppSettings.money(o.finalAmount)} · ${o.status}',
                  style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.hintFontColor),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          CustomButton(
            width: double.infinity,
            onPressed: (_busy || _sourceId == null) ? null : _confirm,
            text: _busy ? 'Please wait…' : 'Merge into this bill',
          ),
        ],
      ),
    );
  }
}
