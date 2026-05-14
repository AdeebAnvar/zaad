import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/core/utils/order_display_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/presentation/dine_in_log/dine_in_reference_utils.dart';
import 'package:pos/presentation/widgets/app_standard_dialog.dart';
import 'package:pos/presentation/widgets/relative_time_text.dart';

double _effectiveOrderDiscountForDisplay(Order o) {
  final t = (o.discountType ?? '').trim().toLowerCase();
  if (o.discountAmount > 0.009) {
    if (t == 'percentage') {
      final pct = o.discountAmount.clamp(0, 100).toDouble();
      final computed = (o.totalAmount * pct / 100).clamp(0, o.totalAmount).toDouble();
      final gap = (o.totalAmount - o.finalAmount).toDouble();
      final validGap = gap > 0.009 ? gap : 0.0;
      if (validGap > 0 && (computed - validGap).abs() > 0.02) {
        return validGap;
      }
      return computed;
    }
    return o.discountAmount.clamp(0, o.totalAmount).toDouble();
  }
  final gap = o.totalAmount - o.finalAmount;
  return gap > 0.009 ? gap : 0.0;
}

String _referenceLineForOrder(Order order) {
  final raw = (order.referenceNumber ?? '').trim();
  if (raw.isEmpty) return '—';
  if ((order.orderType ?? '').trim().toLowerCase() == 'dine_in') {
    final s = DineInRefParser.stripLeadingFloorId(raw).trim();
    return s.isEmpty ? '—' : s;
  }
  return raw;
}

/// On LAN SUB (and other hub mirrors), local [itemId] may not match this device's catalog.
/// When the stored line has no snapshot [item_name], do not substitute another product's menu name.
bool _orderLineTitleShouldAvoidCatalogFallback(Order order) {
  if ((order.serverOrderId ?? '').trim().isNotEmpty) return true;
  final hm = order.hubMetadata?.trim();
  if (hm == null || hm.isEmpty) return false;
  try {
    final root = jsonDecode(hm);
    if (root is! Map<String, dynamic>) return false;
    return root.containsKey('snapshot');
  } catch (_) {
    return false;
  }
}

/// Shared order line-item dialog used by Take Away Log, Dine In Log, etc.
class OrderLogDetailsDialog extends StatelessWidget {
  const OrderLogDetailsDialog({
    super.key,
    required this.order,
    required this.itemsWithDetails,
  });

  final Order order;
  final List<Map<String, dynamic>> itemsWithDetails;

  static const double _kWideBreakpoint = 520;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: AppDialogLayout.insetPadding(context),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxW = AppDialogLayout.maxDetailContentWidth(context);
          final maxH = AppDialogLayout.maxContentHeight(context);
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Header(order: order, onClose: () => Navigator.pop(context)),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (ctx, inner) {
                              return _ScrollBody(
                                order: order,
                                itemsWithDetails: itemsWithDetails,
                                contentWidth: inner.maxWidth,
                              );
                            },
                          ),
                        ),
                        _Footer(order: order, itemsWithDetails: itemsWithDetails),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.order, required this.onClose});

  final Order order;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 12, 4, 12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order details',
                  style: AppStyles.getBoldTextStyle(fontSize: 17, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  order.invoiceNumber,
                  style: AppStyles.getMediumTextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.92)),
                ),
              ],
            ),
          ),
          _StatusChip(status: order.status),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            tooltip: 'Close',
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              hoverColor: Colors.white24,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  Color _bg() {
    final s = status.toLowerCase();
    if (s.contains('complete')) return AppColors.success.withValues(alpha: 0.2);
    if (s.contains('cancel')) return AppColors.danger.withValues(alpha: 0.18);
    if (s == 'kot' || s.contains('place')) return AppColors.warning.withValues(alpha: 0.22);
    return Colors.white.withValues(alpha: 0.18);
  }

  Color _fg() {
    final s = status.toLowerCase();
    if (s.contains('complete')) return const Color(0xFF2E7D32);
    if (s.contains('cancel')) return AppColors.danger;
    if (s == 'kot' || s.contains('place')) return const Color(0xFFE65100);
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, right: 2),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _bg(),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status.toUpperCase(),
          style: AppStyles.getSemiBoldTextStyle(fontSize: 11, color: _fg()),
        ),
      ),
    );
  }
}

class _ScrollBody extends StatelessWidget {
  const _ScrollBody({
    required this.order,
    required this.itemsWithDetails,
    required this.contentWidth,
  });

  final Order order;
  final List<Map<String, dynamic>> itemsWithDetails;
  final double contentWidth;

  bool get _wide => contentWidth >= OrderLogDetailsDialog._kWideBreakpoint;

  @override
  Widget build(BuildContext context) {
    final pad = contentWidth < 400 ? 12.0 : 14.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad, 12, pad, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(icon: Icons.info_outline_rounded, label: 'Order information'),
          const SizedBox(height: 6),
          _InfoSurface(
            child: _OrderInfoBlock(order: order, wide: _wide),
          ),
          if (_hasCustomer(order)) ...[
            const SizedBox(height: 12),
            _SectionTitle(icon: Icons.person_outline_rounded, label: 'Customer'),
            const SizedBox(height: 6),
            _InfoSurface(child: _CustomerBlock(order: order, wide: _wide)),
          ],
          const SizedBox(height: 12),
          _SectionTitle(icon: Icons.restaurant_menu_rounded, label: 'Line items'),
          const SizedBox(height: 6),
          ...itemsWithDetails.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _ItemCard(order: order, data: d),
              )),
        ],
      ),
    );
  }

  static bool _hasCustomer(Order order) {
    return order.customerName != null ||
        order.customerPhone != null ||
        order.customerEmail != null ||
        order.customerGender != null;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.primaryColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppStyles.getSemiBoldTextStyle(fontSize: 14, color: AppColors.textColor),
          ),
        ),
      ],
    );
  }
}

class _InfoSurface extends StatelessWidget {
  const _InfoSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
      ),
      child: child,
    );
  }
}

class _OrderInfoBlock extends StatelessWidget {
  const _OrderInfoBlock({required this.order, required this.wide});

  final Order order;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _kv('Order type', orderTypeShortLabel(order)),
      _kv('Receipt no.', order.invoiceNumber),
      _kv('Reference', _referenceLineForOrder(order)),
      if (order.deliveryPartner != null && order.deliveryPartner!.trim().isNotEmpty)
        _kv('Delivery partner', order.deliveryPartner!),
      if (order.driverName != null && order.driverName!.trim().isNotEmpty) _kv('Driver', order.driverName!),
      _kvWidget(
        'Date',
        RelativeTimeText(
          at: order.createdAt,
          style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.textColor),
        ),
      ),
    ];

    if (wide) {
      final mid = (rows.length / 2).ceil();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows.sublist(0, mid))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rows.sublist(mid),
            ),
          ),
        ],
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows);
  }

  Widget _kv(String k, String v) => _KeyValueRow(label: k, value: v);

  Widget _kvWidget(String k, Widget v) => _KeyValueRow(label: k, valueWidget: v);
}

class _CustomerBlock extends StatelessWidget {
  const _CustomerBlock({required this.order, required this.wide});

  final Order order;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      if (order.customerName != null) _KeyValueRow(label: 'Name', value: order.customerName!),
      if (order.customerPhone != null) _KeyValueRow(label: 'Phone', value: order.customerPhone!),
      if (order.customerEmail != null) _KeyValueRow(label: 'Email', value: order.customerEmail!),
      if (order.customerGender != null) _KeyValueRow(label: 'Gender', value: order.customerGender!),
    ];
    if (rows.isEmpty) {
      return Text('—', style: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.hintFontColor));
    }
    if (wide && rows.length > 1) {
      final mid = (rows.length / 2).ceil();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(children: rows.sublist(0, mid))),
          const SizedBox(width: 14),
          Expanded(child: Column(children: rows.sublist(mid))),
        ],
      );
    }
    return Column(children: rows);
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, this.value, this.valueWidget})
      : assert(value != null || valueWidget != null);

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: AppStyles.getMediumTextStyle(fontSize: 11, color: AppColors.hintFontColor),
          ),
          Expanded(
            child: valueWidget ??
                Text(
                  value!,
                  style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.textColor),
                ),
          ),
        ],
      ),
    );
  }
}

/// Matches receipt logic: for `percentage` lines, [CartItem.discount] is usually the **money** saved, not the rate.
String _orderLogLineDiscountOffText(CartItem cartItem, double listUnitPrice) {
  final d = cartItem.discount;
  final dt = (cartItem.discountType ?? '').trim().toLowerCase();
  if (d <= 0) return '';
  final gross = listUnitPrice * cartItem.quantity;
  final saving = (gross - cartItem.total).clamp(0.0, double.infinity);
  if (dt == 'percentage' && gross > 0.009) {
    double pct;
    if (d <= 100) {
      final implied = gross * d / 100.0;
      pct = (implied - saving).abs() < 0.03 ? d : (saving / gross * 100.0);
    } else {
      pct = saving / gross * 100.0;
    }
    final clamped = pct.clamp(0.0, 100.0);
    final s = clamped % 1 == 0 ? clamped.round().toString() : clamped.toStringAsFixed(2);
    return '$s% off';
  }
  return '${RuntimeAppSettings.money(d)} off';
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.order, required this.data});

  final Order order;
  final Map<String, dynamic> data;

  List<Map<String, dynamic>>? _decodeToppings(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
      if (decoded is Map) {
        final t = decoded['toppings'];
        if (t is List) return t.cast<Map<String, dynamic>>();
      }
    } catch (_) {}
    return null;
  }

  String? _lineNoteFromCartNotes(String? notes) {
    if (notes == null || notes.isEmpty) return null;
    final t = notes.trimLeft();
    if (t.startsWith('[')) return null;
    if (t.startsWith('{')) {
      try {
        final d = jsonDecode(notes);
        if (d is Map) {
          final n = d['lineNote'];
          if (n is String && n.trim().isNotEmpty) return n.trim();
        }
      } catch (_) {
        return null;
      }
      return null;
    }
    return notes.trim();
  }

  @override
  Widget build(BuildContext context) {
    final cartItem = data['cartItem'] as CartItem;
    final item = data['item'] as Item?;
    final variant = data['variant'] as ItemVariant?;
    final topping = data['topping'] as ItemTopping?;

    final catalogName = (item?.name ?? '').trim();
    final snapName = cartItem.itemName.trim();
    // Snapshot name is what was sold (hub / other terminal). Local [itemId] can point at a different
    // catalog row on LAN SUB devices, which previously made the title look like a "random" item.
    final avoidCatalog = _orderLineTitleShouldAvoidCatalogFallback(order);
    final displayName = snapName.isNotEmpty
        ? snapName
        : avoidCatalog
            ? 'Item'
            : (catalogName.isNotEmpty ? catalogName : 'Unknown item');

    final hasDiscount = cartItem.discount > 0;
    final derivedUnit = cartItem.quantity > 0 ? cartItem.total / cartItem.quantity : 0.0;
    final catalogUnit = variant?.price ?? item?.price ?? 0;
    final unitPrice = !hasDiscount
        ? derivedUnit
        : (catalogUnit > 0.001 ? catalogUnit : derivedUnit);
    final toppingsData = _decodeToppings(cartItem.notes);
    final lineNote = _lineNoteFromCartNotes(cartItem.notes);

    final hasMetaLines =
        variant != null || topping != null || (toppingsData != null && toppingsData.isNotEmpty) || (lineNote != null && lineNote.isNotEmpty);
    final showPriceFooter = hasDiscount;
    final showQtyHint = cartItem.quantity > 1 && !hasMetaLines && !hasDiscount;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: AppStyles.getSemiBoldTextStyle(fontSize: 14, color: AppColors.textColor),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '× ${cartItem.quantity}',
                  style: AppStyles.getSemiBoldTextStyle(fontSize: 12, color: AppColors.primaryColor),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  RuntimeAppSettings.money(cartItem.total),
                  style: AppStyles.getBoldTextStyle(fontSize: 14, color: AppColors.primaryColor),
                ),
              ),
            ],
          ),
          if (variant != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                variant.name,
                style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.hintFontColor),
              ),
            ),
          if (topping != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Topping: ${topping.name} (+${RuntimeAppSettings.money(topping.price)})',
                style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.primaryColor),
              ),
            ),
          if (toppingsData != null && toppingsData.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                toppingsData.map((t) => '${t['name'] ?? ''} ×${t['qty'] ?? 1}').join(', '),
                style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.primaryColor),
              ),
            ),
          if (lineNote != null && lineNote.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Note: $lineNote',
                style: AppStyles.getMediumTextStyle(fontSize: 11, color: AppColors.warning),
              ),
            ),
          if (showQtyHint)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${RuntimeAppSettings.money(unitPrice)} ea · × ${cartItem.quantity}',
                style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.hintFontColor),
              ),
            ),
          if (showPriceFooter) ...[
            Divider(height: 14, thickness: 1, color: AppColors.divider.withValues(alpha: 0.8)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    '${RuntimeAppSettings.money(unitPrice)} ea · ×${cartItem.quantity}',
                    style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.hintFontColor),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (hasDiscount)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          _orderLogLineDiscountOffText(cartItem, unitPrice.toDouble()),
                          style: AppStyles.getMediumTextStyle(fontSize: 11, color: AppColors.success),
                        ),
                      ),
                    Text(
                      RuntimeAppSettings.money(cartItem.total),
                      style: AppStyles.getBoldTextStyle(fontSize: 13, color: AppColors.primaryColor),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.order,
    required this.itemsWithDetails,
  });

  final Order order;
  final List<Map<String, dynamic>> itemsWithDetails;

  static double _linesSum(List<Map<String, dynamic>> items) {
    var s = 0.0;
    for (final d in items) {
      final ci = d['cartItem'] as CartItem?;
      if (ci != null) s += ci.total;
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveDiscount = _effectiveOrderDiscountForDisplay(order);
    final hasDiscount = effectiveDiscount > 0.009;
    final total = order.finalAmount > 0 ? order.finalAmount : order.totalAmount;
    final linesSum = _linesSum(itemsWithDetails);
    final hasLines = itemsWithDetails.isNotEmpty;
    final billedSubtotal = order.totalAmount;
    final gapToBilled = hasLines ? (billedSubtotal - linesSum) : 0.0;
    final showGap = hasLines && gapToBilled.abs() > 0.02;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F7),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.9))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasLines) ...[
              _TotalLine(
                label: 'Subtotal (line items)',
                amount: linesSum,
                emphasize: false,
              ),
              if (showGap) ...[
                const SizedBox(height: 4),
                _TotalLine(
                  label: gapToBilled > 0.02 ? 'Other (fees / unlisted lines)' : 'Adjustment',
                  amount: gapToBilled,
                  emphasize: false,
                ),
              ],
              const SizedBox(height: 6),
            ],
            if (hasDiscount) ...[
              if (!hasLines) ...[
                _TotalLine(
                  label: 'Subtotal',
                  amount: order.totalAmount,
                  emphasize: false,
                ),
                const SizedBox(height: 4),
              ],
              _TotalLine(
                label: 'Discount',
                amount: -effectiveDiscount,
                emphasize: false,
                discount: true,
              ),
              const SizedBox(height: 6),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hasDiscount ? 'Final amount' : 'Total',
                    style: AppStyles.getSemiBoldTextStyle(fontSize: 14, color: Colors.white),
                  ),
                  Text(
                    RuntimeAppSettings.money(total),
                    style: AppStyles.getBoldTextStyle(fontSize: 17, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({
    required this.label,
    required this.amount,
    required this.emphasize,
    this.discount = false,
  });

  final String label;
  final double amount;
  final bool emphasize;
  final bool discount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppStyles.getRegularTextStyle(
            fontSize: 14,
            color: AppColors.hintFontColor,
          ),
        ),
        Text(
          RuntimeAppSettings.money(amount.abs()),
          style: AppStyles.getMediumTextStyle(
            fontSize: 14,
            color: discount ? AppColors.success : AppColors.textColor,
          ),
        ),
      ],
    );
  }
}
