import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/core/utils/order_display_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/presentation/widgets/app_standard_dialog.dart';
import 'package:pos/presentation/widgets/relative_time_text.dart';

/// Shared order line-item dialog used by Take Away Log, Dine In Log, etc.
class OrderLogDetailsDialog extends StatelessWidget {
  const OrderLogDetailsDialog({
    super.key,
    required this.order,
    required this.itemsWithDetails,
  });

  final Order order;
  final List<Map<String, dynamic>> itemsWithDetails;

  static const double _kWideBreakpoint = 560;

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
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryColor.withValues(alpha: 0.12),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
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
                        _Footer(order: order),
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
      padding: EdgeInsets.fromLTRB(20, 18, 8, 18),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                  style: AppStyles.getBoldTextStyle(fontSize: 20, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  order.invoiceNumber,
                  style: AppStyles.getMediumTextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.92)),
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
      padding: const EdgeInsets.only(top: 2, right: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    final pad = contentWidth < 400 ? 16.0 : 22.0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(pad, 18, pad, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(icon: Icons.info_outline_rounded, label: 'Order information'),
          const SizedBox(height: 10),
          _InfoSurface(
            child: _OrderInfoBlock(order: order, wide: _wide),
          ),
          if (_hasCustomer(order)) ...[
            const SizedBox(height: 22),
            _SectionTitle(icon: Icons.person_outline_rounded, label: 'Customer'),
            const SizedBox(height: 10),
            _InfoSurface(child: _CustomerBlock(order: order, wide: _wide)),
          ],
          const SizedBox(height: 22),
          _SectionTitle(icon: Icons.restaurant_menu_rounded, label: 'Line items'),
          const SizedBox(height: 12),
          ...itemsWithDetails.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ItemCard(data: d),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppStyles.getSemiBoldTextStyle(fontSize: 15, color: AppColors.textColor),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(14),
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
      _kv('Reference', order.referenceNumber ?? '—'),
      if (order.deliveryPartner != null && order.deliveryPartner!.trim().isNotEmpty)
        _kv('Delivery partner', order.deliveryPartner!),
      if (order.driverName != null && order.driverName!.trim().isNotEmpty) _kv('Driver', order.driverName!),
      _kvWidget(
        'Date',
        RelativeTimeText(
          at: order.createdAt,
          style: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.textColor),
        ),
      ),
    ];

    if (wide) {
      final mid = (rows.length / 2).ceil();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows.sublist(0, mid))),
          const SizedBox(width: 20),
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
          const SizedBox(width: 20),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LayoutBuilder(
        builder: (context, c) {
          final stack = c.maxWidth < 340;
          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppStyles.getMediumTextStyle(fontSize: 12, color: AppColors.hintFontColor),
                ),
                const SizedBox(height: 4),
                valueWidget ??
                    Text(
                      value!,
                      style: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.textColor),
                    ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: math.min(130, c.maxWidth * 0.38),
                child: Text(
                  label,
                  style: AppStyles.getMediumTextStyle(fontSize: 12, color: AppColors.hintFontColor),
                ),
              ),
              Expanded(
                child: valueWidget ??
                    Text(
                      value!,
                      style: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.textColor),
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.data});

  final Map<String, dynamic> data;

  List<Map<String, dynamic>>? _decodeToppings(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) return decoded.cast<Map<String, dynamic>>();
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cartItem = data['cartItem'] as CartItem;
    final item = data['item'] as Item?;
    final variant = data['variant'] as ItemVariant?;
    final topping = data['topping'] as ItemTopping?;

    final unitPrice = variant?.price ?? item?.price ?? 0;
    final hasDiscount = cartItem.discount > 0;
    final toppingsData = _decodeToppings(cartItem.notes);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item?.name ?? 'Unknown item',
                  style: AppStyles.getSemiBoldTextStyle(fontSize: 15, color: AppColors.textColor),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '× ${cartItem.quantity}',
                  style: AppStyles.getSemiBoldTextStyle(fontSize: 13, color: AppColors.primaryColor),
                ),
              ),
            ],
          ),
          if (variant != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                variant.name,
                style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.hintFontColor),
              ),
            ),
          if (topping != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Topping: ${topping.name} (+${RuntimeAppSettings.money(topping.price)})',
                style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.primaryColor),
              ),
            ),
          if (toppingsData != null && toppingsData.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                toppingsData.map((t) => '${t['name'] ?? ''} ×${t['qty'] ?? 1}').join(', '),
                style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.primaryColor),
              ),
            ),
          if (cartItem.notes != null &&
              cartItem.notes!.isNotEmpty &&
              (toppingsData == null || toppingsData.isEmpty))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Note: ${cartItem.notes}',
                style: AppStyles.getMediumTextStyle(fontSize: 12, color: AppColors.warning),
              ),
            ),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.8)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                RuntimeAppSettings.money(unitPrice),
                style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.hintFontColor),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasDiscount)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        cartItem.discountType == 'percentage'
                            ? '${cartItem.discount}% off'
                            : '${RuntimeAppSettings.money(cartItem.discount)} off',
                        style: AppStyles.getMediumTextStyle(fontSize: 11, color: AppColors.success),
                      ),
                    ),
                  Text(
                    RuntimeAppSettings.money(cartItem.total),
                    style: AppStyles.getBoldTextStyle(fontSize: 16, color: AppColors.primaryColor),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = order.discountAmount > 0;
    final total = order.finalAmount > 0 ? order.finalAmount : order.totalAmount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F7),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.9))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasDiscount) ...[
              _TotalLine(
                label: 'Subtotal',
                amount: order.totalAmount,
                emphasize: false,
              ),
              const SizedBox(height: 6),
              _TotalLine(
                label: 'Discount',
                amount: -order.discountAmount,
                emphasize: false,
                discount: true,
              ),
              const SizedBox(height: 10),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hasDiscount ? 'Final amount' : 'Total',
                    style: AppStyles.getSemiBoldTextStyle(fontSize: 15, color: Colors.white),
                  ),
                  Text(
                    RuntimeAppSettings.money(total),
                    style: AppStyles.getBoldTextStyle(fontSize: 18, color: Colors.white),
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
