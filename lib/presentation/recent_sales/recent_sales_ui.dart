import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/presentation/recent_sales/recent_sales_cubit.dart';
import 'package:pos/presentation/widgets/auto_complete_textfield.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';

class RecentSalesScreen extends StatelessWidget {
  const RecentSalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RecentSalesCubit(locator<OrderRepository>()),
      child: CustomScaffold(
        title: 'Recent Sales',
        body: BlocBuilder<RecentSalesCubit, RecentSalesState>(
          builder: (context, state) {
            if (state is RecentSalesLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is RecentSalesError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<RecentSalesCubit>().loadOrders(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is RecentSalesLoaded) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 768;
                  return Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: () => context.read<RecentSalesCubit>().refreshOrders(),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMobile) const _FilterBar(),
                                if (!isMobile) const SizedBox(height: 16),
                                if (state.orders.isEmpty)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: Text(
                                        'No sales found',
                                        style: TextStyle(fontSize: 16, color: Colors.grey),
                                      ),
                                    ),
                                  )
                                else
                                  LayoutBuilder(builder: (context, constraints) {
                                    final width = constraints.maxWidth;

                                    final columns = width >= 1200
                                        ? 3
                                        : width >= 700
                                            ? 2
                                            : 1;

                                    const spacing = 16.0;

                                    final cardWidth = (width - (columns - 1) * spacing) / columns;

                                    return Wrap(
                                      spacing: spacing,
                                      runSpacing: spacing,
                                      children: state.orders.map((order) {
                                        return SizedBox(
                                          width: cardWidth,
                                          child: RecentSaleCard(order: order),
                                        );
                                      }).toList(),
                                    );
                                  }),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (isMobile)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: FloatingActionButton(
                            onPressed: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              builder: (_) => DraggableScrollableSheet(
                                initialChildSize: 0.6,
                                minChildSize: 0.4,
                                maxChildSize: 0.9,
                                expand: false,
                                builder: (_, scrollController) => SingleChildScrollView(
                                  controller: scrollController,
                                  child: const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: _FilterBar(),
                                  ),
                                ),
                              ),
                            ),
                            backgroundColor: AppColors.primaryColor,
                            child: const Icon(Icons.filter_list, color: Colors.white),
                            tooltip: 'Filters',
                          ),
                        ),
                    ],
                  );
                },
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _FilterBar extends StatefulWidget {
  const _FilterBar();

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  final _invoiceController = TextEditingController();
  final _referenceController = TextEditingController();
  final _statusController = TextEditingController();
  final _orderTypeController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _statusOptions = ['All', 'placed', 'completed', 'cancelled'];
  final List<String> _orderTypeOptions = ['All', 'Take Away', 'Dine In', 'Delivery'];
  final List<String> _paymentMethodOptions = ['All', 'Cash', 'Card', 'Credit', 'Online'];

  @override
  void dispose() {
    _invoiceController.dispose();
    _referenceController.dispose();
    _statusController.dispose();
    _orderTypeController.dispose();
    _paymentMethodController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _applyFilters() {
    final cubit = context.read<RecentSalesCubit>();
    cubit.filterOrders(
      invoiceNumber: _invoiceController.text.trim().isEmpty ? null : _invoiceController.text.trim(),
      referenceNumber: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
      status: _statusController.text.isEmpty || _statusController.text == 'All' ? null : _statusController.text,
      orderType: _orderTypeController.text.isEmpty || _orderTypeController.text == 'All' ? null : _orderTypeController.text,
      paymentMethod: _paymentMethodController.text.isEmpty || _paymentMethodController.text == 'All' ? null : _paymentMethodController.text,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  void _clearFilters() {
    setState(() {
      _invoiceController.clear();
      _referenceController.clear();
      _statusController.clear();
      _orderTypeController.clear();
      _paymentMethodController.clear();
      _startDate = null;
      _endDate = null;
    });
    context.read<RecentSalesCubit>().loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          )
        ],
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 200,
            child: CustomTextField(
              controller: _invoiceController,
              labelText: 'Receipt No.',
            ),
          ),
          SizedBox(
            width: 200,
            child: CustomTextField(
              controller: _referenceController,
              labelText: 'Reference No.',
            ),
          ),
          SizedBox(
            width: 160,
            child: AutoCompleteTextField<String>(
              defaultText: 'Select Status',
              displayStringFunction: (v) => v,
              items: _statusOptions,
              onSelected: (v) {
                setState(() {
                  _statusController.text = v;
                });
              },
              controller: _statusController,
            ),
          ),
          SizedBox(
            width: 160,
            child: AutoCompleteTextField<String>(
              defaultText: 'Order Type',
              displayStringFunction: (v) => v,
              items: _orderTypeOptions,
              onSelected: (v) {
                setState(() {
                  _orderTypeController.text = v;
                });
              },
              controller: _orderTypeController,
            ),
          ),
          SizedBox(
            width: 160,
            child: AutoCompleteTextField<String>(
              defaultText: 'Payment Method',
              displayStringFunction: (v) => v,
              items: _paymentMethodOptions,
              onSelected: (v) {
                setState(() {
                  _paymentMethodController.text = v;
                });
              },
              controller: _paymentMethodController,
            ),
          ),
          SizedBox(
            width: 180,
            child: InkWell(
              onTap: () => _selectDate(context, true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _startDate == null ? 'Start Date' : DateFormat('dd-MM-yyyy').format(_startDate!),
                        style: TextStyle(
                          color: _startDate == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 180,
            child: InkWell(
              onTap: () => _selectDate(context, false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _endDate == null ? 'End Date' : DateFormat('dd-MM-yyyy').format(_endDate!),
                        style: TextStyle(
                          color: _endDate == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          CustomButton(
            width: 120,
            onPressed: _applyFilters,
            text: 'Filter',
          ),
          CustomButton(
            width: 120,
            onPressed: _clearFilters,
            text: 'Clear',
            backgroundColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}

class RecentSaleCard extends StatefulWidget {
  final Order order;
  const RecentSaleCard({super.key, required this.order});

  @override
  State<RecentSaleCard> createState() => _RecentSaleCardState();
}

class _RecentSaleCardState extends State<RecentSaleCard> {
  bool _hovered = false;

  // Determine order type based on order properties
  // For now, we'll default to TAKE AWAY, but this can be enhanced
  String _getOrderType() {
    // TODO: Implement logic to determine order type from cart or other fields
    // For now, defaulting to TAKE AWAY
    return 'TAKE AWAY';
  }

  IconData _getOrderTypeIcon() {
    final type = _getOrderType();
    switch (type) {
      case 'DELIVERY':
        return Icons.local_shipping;
      case 'DINE IN':
        return Icons.restaurant;
      case 'TAKE AWAY':
      default:
        return Icons.shopping_bag;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = widget.order;
    final orderType = _getOrderType();

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -8 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hovered ? 0.25 : 0.08),
              blurRadius: _hovered ? 22 : 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(orderType),
              const SizedBox(height: 14),
              _infoRow(order),
              const SizedBox(height: 14),
              _netTotal(order),
              // if (order.cardAmount > 0) ...[
              //   const SizedBox(height: 8),
              //   _onlinePayment(order),
              // ],
              const SizedBox(height: 14),
              _actions(context, order),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String orderType) {
    final order = widget.order;
    final formattedDate = DateFormat('dd-MM-yyyy HH:mm:ss').format(order.createdAt);

    return Row(
      children: [
        _tag(orderType),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Counter',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formattedDate,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tag(String orderType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2F3A56),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getOrderTypeIcon(), size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            orderType,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(Order order) {
    final orderType = _getOrderType();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _infoBlock('Receipt No', order.invoiceNumber),
            const SizedBox(width: 24),
            if (orderType == 'TAKE AWAY')
              _infoBlock('Ref. No', order.referenceNumber ?? '-')
            else if (orderType == 'DINE IN')
              _infoBlock('Table', '-') // TODO: Get table info from cart
            else if (orderType == 'DELIVERY')
              _infoBlock('Driver', '-'), // TODO: Get driver info from cart
          ],
        ),
        if (orderType == 'DELIVERY') ...[
          const SizedBox(height: 8),
          _infoBlock('Customer', order.customerName ?? '-'),
        ],
        if (order.status.isNotEmpty) ...[
          const SizedBox(height: 8),
          _infoBlock('Status', order.status.toUpperCase()),
        ],
      ],
    );
  }

  Widget _infoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _netTotal(Order order) {
    final total = order.finalAmount > 0 ? order.finalAmount : order.totalAmount;

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Net Total',
            style: AppStyles.getMediumTextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Text(
            '₹ ${total.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _onlinePayment(Order order) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Text(
            'Online: ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '₹ ${order.cardAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.green.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context, Order order) {
    return Row(
      children: [
        _icon(
          Icons.remove_red_eye_outlined,
          tooltip: 'View',
          onTap: () => _handleView(context, order),
        ),
        _icon(Icons.print_outlined, tooltip: 'Print'),
        _icon(
          Icons.edit_outlined,
          tooltip: 'Edit',
          onTap: () => _handleEdit(context, order),
        ),
      ],
    );
  }

  Widget _icon(
    IconData icon, {
    required String tooltip,
    Color bg = AppColors.primaryColor,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: onTap == null ? Colors.grey.shade300 : bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _handleView(BuildContext context, Order order) async {
    // Load order details similar to takeaway log
    final cartRepo = locator<CartRepository>();
    final itemRepo = locator<ItemRepository>();

    final cartItems = await cartRepo.getCartItemsByCartId(order.cartId);
    if (cartItems == null || cartItems.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No items found for this order')),
        );
      }
      return;
    }

    // Load item details for each cart item including toppings
    final List<Map<String, dynamic>> itemsWithDetails = [];
    for (final cartItem in cartItems) {
      final item = await itemRepo.fetchItemByIdFromLocal(cartItem.itemId);
      ItemVariant? variant;
      if (cartItem.itemVariantId != null) {
        variant = await itemRepo.fetchVariantById(cartItem.itemVariantId!);
      }
      ItemTopping? topping;
      if (cartItem.itemToppingId != null) {
        topping = await itemRepo.fetchToppingById(cartItem.itemToppingId!);
      }
      itemsWithDetails.add({
        'cartItem': cartItem,
        'item': item,
        'variant': variant,
        'topping': topping,
      });
    }

    // Show order details dialog
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => _OrderDetailsDialog(
          order: order,
          itemsWithDetails: itemsWithDetails,
        ),
      );
    }
  }

  void _handleEdit(BuildContext context, Order order) {
    Navigator.pushNamed(
      context,
      '/counter',
      arguments: {'orderId': order.id},
    ).then((_) {
      // Refresh orders after returning from edit
      if (context.mounted) {
        context.read<RecentSalesCubit>().refreshOrders();
      }
    });
  }
}

// Order Details Dialog
class _OrderDetailsDialog extends StatelessWidget {
  final Order order;
  final List<Map<String, dynamic>> itemsWithDetails;

  const _OrderDetailsDialog({
    required this.order,
    required this.itemsWithDetails,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          width: width > 1000
              ? 760
              : width > 700
                  ? 640
                  : width * 0.96,
          constraints: const BoxConstraints(maxHeight: 720),
          decoration: BoxDecoration(
            color: Colors.white,
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
        _infoRow('Receipt No', order.invoiceNumber),
        _infoRow('Reference No', order.referenceNumber ?? 'N/A'),
        _infoRow('Status', order.status),
        _infoRow(
          'Date',
          DateFormat('dd-MM-yyyy HH:mm').format(order.createdAt),
        ),
      ],
    );
  }

  bool _hasCustomerDetails() {
    return order.customerName != null || order.customerPhone != null || order.customerEmail != null || order.customerGender != null;
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
                      cartItem.discountType == 'percentage' ? '${cartItem.discount}% OFF' : '₹ ${cartItem.discount.toStringAsFixed(2)} OFF',
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
