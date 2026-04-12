import 'dart:math' as math;
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/presentation/sale/cart_cubit/cart_cubit.dart';

class _LoadedLine {
  _LoadedLine({
    required this.name,
    this.variantName,
    required this.quantity,
    required this.total,
    required this.discount,
    this.toppings,
  });

  final String name;
  final String? variantName;
  final int quantity;
  final double total;
  final double discount;
  final List<Map<String, dynamic>>? toppings;
}

Future<List<_LoadedLine>> _loadLines(List<CartItem> items, CartCubit cubit) async {
  final itemRepo = locator<ItemRepository>();
  final out = <_LoadedLine>[];
  for (final cartItem in items) {
    final item = await itemRepo.fetchItemByIdFromLocal(cartItem.itemId);
    ItemVariant? variant;
    if (cartItem.itemVariantId != null) {
      variant = await itemRepo.fetchVariantById(cartItem.itemVariantId!);
    }
    final toppings = cubit.getToppingsFromCartItem(cartItem);
    out.add(
      _LoadedLine(
        name: item?.name ?? 'Item #${cartItem.itemId}',
        variantName: variant?.name,
        quantity: cartItem.quantity,
        total: cartItem.total,
        discount: cartItem.discount,
        toppings: toppings,
      ),
    );
  }
  return out;
}

/// Full-screen-friendly dialog listing each cart line with toppings.
Future<void> showCartPreviewDialog(BuildContext context) async {
  final cubit = context.read<CartCubit>();
  final items = List<CartItem>.from(cubit.state.items);
  if (items.isEmpty) return;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      final mq = MediaQuery.of(ctx);
      final width = mq.size.width;
      final dialogHeight = math.min(mq.size.height * 0.72, 560.0);
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SizedBox(
          width: width > 560 ? 480 : width - 32,
          height: dialogHeight,
          child: Material(
            color: Theme.of(ctx).colorScheme.surface,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.divider),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined, color: AppColors.primaryColor, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Cart preview',
                          style: AppStyles.getBoldTextStyle(fontSize: 18, color: AppColors.textColor),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: FutureBuilder<List<_LoadedLine>>(
                    future: _loadLines(items, cubit),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final lines = snapshot.data ?? [];
                      if (lines.isEmpty) {
                        return Center(
                          child: Text(
                            'No lines to show',
                            style: AppStyles.getRegularTextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: lines.length,
                        separatorBuilder: (_, __) => Divider(height: 20, color: AppColors.divider),
                        itemBuilder: (context, i) {
                          final line = lines[i];
                          return _PreviewLineTile(line: line);
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _PreviewLineTile extends StatelessWidget {
  const _PreviewLineTile({required this.line});

  final _LoadedLine line;

  @override
  Widget build(BuildContext context) {
    final toppingsColor = AppColors.primaryColor;
    if (line.toppings != null && line.toppings!.isNotEmpty) {
      // #region agent log
      _dbgLog('cart_preview_toppings_color', {
        'toppingsCount': line.toppings!.length,
        'colorArgb': toppingsColor.toARGB32(),
      }, hypothesisId: 'H1');
      // #endregion
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          line.name,
          style: AppStyles.getSemiBoldTextStyle(fontSize: 15, color: AppColors.textColor),
        ),
        if (line.variantName != null && line.variantName!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Variant: ${line.variantName}',
              style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        const SizedBox(height: 6),
        Text(
          'Qty ${line.quantity} · Line total ₹${line.total.toStringAsFixed(2)}',
          style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.black87),
        ),
        if (line.discount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              'Discount: -₹${line.discount.toStringAsFixed(2)}',
              style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.red.shade700),
            ),
          ),
        if (line.toppings != null && line.toppings!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'Toppings',
            style: AppStyles.getSemiBoldTextStyle(fontSize: 12, color: AppColors.primaryColor),
          ),
          ...line.toppings!.map((t) {
            final name = t['name'] ?? '';
            final price = (t['price'] ?? 0.0) as num;
            final qty = (t['qty'] ?? 1) as int;
            final lineTotal = price.toDouble() * qty;
            return Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text(
                '• $name × $qty — ₹${lineTotal.toStringAsFixed(2)}',
                style: AppStyles.getRegularTextStyle(fontSize: 12, color: toppingsColor),
              ),
            );
          }),
        ],
      ],
    );
  }
}

// #region agent log
void _dbgLog(String message, Map<String, Object?> data, {String hypothesisId = 'H1'}) {
  try {
    final payload = {
      'sessionId': 'bead4f',
      'runId': 'cart-preview-toppings-color',
      'hypothesisId': hypothesisId,
      'location': 'cart_preview_dialog.dart',
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    File('debug-bead4f.log').writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append, flush: true);
  } catch (_) {}
}
// #endregion
