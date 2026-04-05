import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos/core/utils/order_display_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/presentation/widgets/app_standard_dialog.dart';

/// Shared order line-item dialog used by Take Away Log, Dine In Log, etc.
class OrderLogDetailsDialog extends StatelessWidget {
  const OrderLogDetailsDialog({
    super.key,
    required this.order,
    required this.itemsWithDetails,
  });

  final Order order;
  final List<Map<String, dynamic>> itemsWithDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: AppDialogLayout.insetPadding(context),
      child: Center(
        child: Container(
          width: AppDialogLayout.maxDetailContentWidth(context),
          constraints: BoxConstraints(maxHeight: AppDialogLayout.maxContentHeight(context)),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(blurRadius: 40, color: Colors.black26),
            ],
          ),
          child: Column(
            children: [
              _header(context),
              const Divider(height: 1),
              Expanded(child: _content()),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Order Details',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  Widget _content() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Order Information'),
          _orderInfo(),
          if (_hasCustomerDetails()) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _sectionTitle('Customer Details'),
            _customerInfo(),
          ],
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          _sectionTitle('Items'),
          const SizedBox(height: 12),
          ...itemsWithDetails.map(_itemCard),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _orderInfo() {
    return Column(
      children: [
        _infoRow('Order type', orderTypeShortLabel(order)),
        _infoRow('Receipt No', order.invoiceNumber),
        _infoRow('Reference No', order.referenceNumber ?? 'N/A'),
        if (order.deliveryPartner != null && order.deliveryPartner!.trim().isNotEmpty)
          _infoRow('Delivery partner', order.deliveryPartner!),
        if (order.driverName != null && order.driverName!.trim().isNotEmpty)
          _infoRow('Driver', order.driverName!),
        _infoRow('Status', order.status),
        _infoRow(
          'Date',
          DateFormat('dd-MM-yyyy HH:mm').format(order.createdAt),
        ),
      ],
    );
  }

  bool _hasCustomerDetails() {
    return order.customerName != null ||
        order.customerPhone != null ||
        order.customerEmail != null ||
        order.customerGender != null;
  }

  Widget _customerInfo() {
    return Column(
      children: [
        if (order.customerName != null) _infoRow('Name', order.customerName!),
        if (order.customerPhone != null) _infoRow('Phone', order.customerPhone!),
        if (order.customerEmail != null) _infoRow('Email', order.customerEmail!),
        if (order.customerGender != null) _infoRow('Gender', order.customerGender!),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _itemCard(Map<String, dynamic> data) {
    final cartItem = data['cartItem'] as CartItem;
    final item = data['item'] as Item?;
    final variant = data['variant'] as ItemVariant?;
    final topping = data['topping'] as ItemTopping?;

    final unitPrice = variant?.price ?? item?.price ?? 0;
    final hasDiscount = cartItem.discount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item?.name ?? 'Unknown Item',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'x${cartItem.quantity}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          if (variant != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Variant: ${variant.name}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          if (topping != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Topping: ${topping.name} (+₹${topping.price.toStringAsFixed(2)})',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          if (cartItem.notes?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Note: ${cartItem.notes}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹ ${unitPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (hasDiscount)
                    Text(
                      cartItem.discountType == 'percentage'
                          ? '${cartItem.discount}% OFF'
                          : '₹ ${cartItem.discount.toStringAsFixed(2)} OFF',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    '₹ ${cartItem.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    final hasDiscount = order.discountAmount > 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 16,
            color: Colors.black12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (hasDiscount) ...[
            _totalRow('Subtotal', order.totalAmount),
            const SizedBox(height: 6),
            _totalRow(
              'Discount',
              -order.discountAmount,
              highlight: true,
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
          ],
          _totalRow(
            hasDiscount ? 'Final Amount' : 'Total Amount',
            order.finalAmount > 0 ? order.finalAmount : order.totalAmount,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _totalRow(
    String label,
    double amount, {
    bool bold = false,
    bool highlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 18 : 16,
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: highlight ? Colors.green.shade700 : null,
          ),
        ),
        Text(
          '₹ ${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: bold ? 18 : 16,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: highlight ? Colors.green.shade700 : null,
          ),
        ),
      ],
    );
  }
}
