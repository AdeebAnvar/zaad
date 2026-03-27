import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/delivery_partner_repository.dart';
import 'package:pos/data/repository/driver_repository.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/presentation/delivery_log/delivery_log_cubit.dart';
import 'package:pos/presentation/delivery_log/delivery_log_ui.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';

class DriverLogScreen extends StatefulWidget {
  const DriverLogScreen({super.key});

  @override
  State<DriverLogScreen> createState() => _DriverLogScreenState();
}

class _DriverLogScreenState extends State<DriverLogScreen> {
  final _searchController = TextEditingController();
  final Set<int> _selectedOrderIds = <int>{};

  List<Order> _orders = [];
  List<Driver> _drivers = [];
  int? _filterDriverId;
  bool _loading = true;
  bool _bulkUpdating = false;
  String _bulkPaymentType = 'CREDIT';

  static const List<String> _paymentOptionsNormal = ['CREDIT', 'CASH', 'CARD'];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final orderRepo = locator<OrderRepository>();
    final driverRepo = locator<DriverRepository>();
    final drivers = await driverRepo.getAll();
    var orders = await orderRepo.getDeliveryOrdersWithDriver();
    orders = orders
        .where((o) => o.deliveryPartner?.toUpperCase() == 'NORMAL')
        .where((o) => !_isArchivedStatus(o.status))
        .toList();
    if (!mounted) return;
    setState(() {
      _drivers = drivers;
      _orders = orders;
      _selectedOrderIds.removeWhere((id) => !_orders.any((o) => o.id == id));
      _loading = false;
    });
  }

  List<Order> get _filteredOrders {
    var list = _orders;
    if (_filterDriverId != null) {
      list = list.where((o) => o.driverId == _filterDriverId).toList();
    }
    final q = _searchController.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where((o) =>
              o.invoiceNumber.toLowerCase().contains(q) ||
              (o.customerPhone ?? '').toLowerCase().contains(q) ||
              (o.driverName ?? '').toLowerCase().contains(q))
          .toList();
    }
    return list.where((o) => !_isArchivedStatus(o.status)).toList();
  }

  double get _totalAmount => _filteredOrders.fold<double>(0, (s, o) => s + o.finalAmount);

  bool get _allFilteredSelected {
    final f = _filteredOrders;
    if (f.isEmpty) return false;
    return f.every((o) => _selectedOrderIds.contains(o.id));
  }

  static bool _isArchivedStatus(String status) {
    final s = status.trim().toLowerCase();
    return s == 'delivered' || s == 'completed' || s == 'cancelled';
  }

  static String _displayStatus(String status) {
    final s = status.trim().toLowerCase();
    if (s == 'assigned' || s == 'dispatched') return 'Out for delivery';
    if (s == 'delivered' || s == 'completed') return 'Delivered';
    if (s == 'cancelled') return 'Cancelled';
    return 'Out for delivery';
  }

  Future<bool> _confirm({required String title, required String message}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  void _toggleSelection(int orderId, bool selected) {
    setState(() {
      if (selected) {
        _selectedOrderIds.add(orderId);
      } else {
        _selectedOrderIds.remove(orderId);
      }
    });
  }

  void _toggleSelectAllVisible(bool selected) {
    final ids = _filteredOrders.map((e) => e.id);
    setState(() {
      if (selected) {
        _selectedOrderIds.addAll(ids);
      } else {
        _selectedOrderIds.removeAll(ids);
      }
    });
  }

  Future<void> _updatePaymentType(Order order, String paymentType) async {
    final repo = locator<OrderRepository>();
    final updated = order.copyWith(
      cashAmount: paymentType == 'CASH' ? order.finalAmount : 0,
      cardAmount: paymentType == 'CARD' ? order.finalAmount : 0,
      creditAmount: paymentType == 'CREDIT' ? order.finalAmount : 0,
      onlineAmount: paymentType == 'ONLINE' ? order.finalAmount : 0,
    );
    await repo.updateOrder(updated);
    await _reload();
  }

  Future<void> _bulkUpdatePayment() async {
    final selectedOrders = _filteredOrders.where((o) => _selectedOrderIds.contains(o.id)).toList();
    if (selectedOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select orders first')));
      return;
    }
    final ok = await _confirm(
      title: 'Bulk payment update',
      message: 'Update payment type to "$_bulkPaymentType" for ${selectedOrders.length} selected orders?',
    );
    if (!ok || !mounted) return;

    setState(() => _bulkUpdating = true);
    try {
      final repo = locator<OrderRepository>();
      for (final order in selectedOrders) {
        final updated = order.copyWith(
          cashAmount: _bulkPaymentType == 'CASH' ? order.finalAmount : 0,
          cardAmount: _bulkPaymentType == 'CARD' ? order.finalAmount : 0,
          creditAmount: _bulkPaymentType == 'CREDIT' ? order.finalAmount : 0,
          onlineAmount: _bulkPaymentType == 'ONLINE' ? order.finalAmount : 0,
        );
        await repo.updateOrder(updated);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment updated for ${selectedOrders.length} orders')),
      );
      await _reload();
    } catch (e) {
      if (!mounted) return;
      showErrorDialog(context, e);
    } finally {
      if (mounted) setState(() => _bulkUpdating = false);
    }
  }

  Future<void> _updateStatus(Order order, String dbStatus) async {
    final display = _displayStatus(dbStatus);
    final removing = dbStatus == 'delivered' || dbStatus == 'cancelled';
    final ok = await _confirm(
      title: 'Confirm status change',
      message: removing
          ? 'Mark order ${order.invoiceNumber} as $display? It will be removed from Driver Log.'
          : 'Mark order ${order.invoiceNumber} as $display?',
    );
    if (!ok || !mounted) return;
    await locator<OrderRepository>().updateOrderStatus(order.id, dbStatus);
    await _reload();
  }

  Future<void> _viewItems(Order order) async {
    final cartRepo = locator<CartRepository>();
    final itemRepo = locator<ItemRepository>();
    final cartItems = await cartRepo.getCartItemsByCartId(order.cartId);
    if (cartItems == null || cartItems.isEmpty) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Order Items'),
          content: Text('No items found in this order.'),
        ),
      );
      return;
    }

    final itemsWithDetails = <Map<String, dynamic>>[];
    for (final cartItem in cartItems) {
      final item = await itemRepo.fetchItemByIdFromLocal(cartItem.itemId);
      final variant = cartItem.itemVariantId != null ? await itemRepo.fetchVariantById(cartItem.itemVariantId!) : null;
      final topping = cartItem.itemToppingId != null ? await itemRepo.fetchToppingById(cartItem.itemToppingId!) : null;
      itemsWithDetails.add({'cartItem': cartItem, 'item': item, 'variant': variant, 'topping': topping});
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Order ${order.invoiceNumber}'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: itemsWithDetails.map((m) {
                final item = m['item'] as Item?;
                final cartItem = m['cartItem'] as CartItem;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${item?.name ?? "?"} x${cartItem.quantity} - ₹${cartItem.total.toStringAsFixed(2)}'),
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _printOrder(Order order) async {
    final cartRepo = locator<CartRepository>();
    final printService = locator<PrintService>();
    final cartItems = await cartRepo.getCartItemsByCartId(order.cartId);
    if (cartItems == null || cartItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No items to print')));
      }
      return;
    }
    try {
      await printService.printFinalBill(order: order, cartItems: cartItems);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill sent to printer')));
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, e);
    }
  }

  void _openDeliveryLog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (context) => DeliveryLogCubit(
            locator<OrderRepository>(),
            locator<DeliveryPartnerRepository>(),
            locator<DriverRepository>(),
          ),
          child: const DeliveryLogScreen(),
        ),
      ),
    ).then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 600;
    final useWideTable = width >= 980;
    final horizontalPad = width < 400 ? 12.0 : (useWideTable ? 24.0 : 16.0);

    return CustomScaffold(
      title: 'Driver Log',
      appBarScreen: 'driver_log',
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryColor,
                strokeWidth: 2,
              ),
            )
          : ColoredBox(
              color: AppColors.scaffoldColor,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(isCompact),
                    const SizedBox(height: 20),
                    _buildToolbar(isCompact),
                    const SizedBox(height: 12),
                    _buildBulkBar(isCompact),
                    const SizedBox(height: 12),
                    _buildSummaryBar(isCompact),
                    const SizedBox(height: 12),
                    if (_filteredOrders.isEmpty)
                      _buildEmptyState()
                    else if (useWideTable)
                      _DriverOrdersTable(
                        orders: _filteredOrders,
                        selectedOrderIds: _selectedOrderIds,
                        allVisibleSelected: _allFilteredSelected,
                        onToggleSelect: _toggleSelection,
                        onToggleSelectAll: _toggleSelectAllVisible,
                        onUpdateStatus: _updateStatus,
                        onUpdatePayment: _updatePaymentType,
                        onViewItems: _viewItems,
                        onPrint: _printOrder,
                      )
                    else
                      ..._filteredOrders.map(
                        (order) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DriverOrderCard(
                            order: order,
                            selected: _selectedOrderIds.contains(order.id),
                            onToggleSelect: _toggleSelection,
                            onUpdateStatus: _updateStatus,
                            onUpdatePayment: _updatePaymentType,
                            onViewItems: _viewItems,
                            onPrint: _printOrder,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Driver log - Out for delivery',
          style: AppStyles.getSemiBoldTextStyle(fontSize: isCompact ? 22 : 26),
        ),
        const SizedBox(height: 6),
        Text(
          'Assigned orders are shown as Out for delivery. Delivered and Cancelled orders are removed after confirmation.',
          style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.hintFontColor),
        ),
      ],
    );
  }

  Widget _buildToolbar(bool isCompact) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _driverDropdown(),
                  const SizedBox(height: 12),
                  _searchField(),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _openDeliveryLog(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.local_shipping_outlined, size: 20),
                    label: Text('Delivery log', style: AppStyles.getMediumTextStyle(fontSize: 14, color: Colors.white)),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _driverDropdown()),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _searchField()),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () => _openDeliveryLog(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.local_shipping_outlined, size: 20),
                    label: Text('Delivery log', style: AppStyles.getMediumTextStyle(fontSize: 14, color: Colors.white)),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBulkBar(bool isCompact) {
    final selectedCount = _filteredOrders.where((o) => _selectedOrderIds.contains(o.id)).length;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Selected: $selectedCount', style: AppStyles.getMediumTextStyle(fontSize: 13)),
                  const SizedBox(height: 10),
                  _bulkPaymentDropdown(),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: _bulkUpdating ? null : _bulkUpdatePayment,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(_bulkUpdating ? 'Updating...' : 'Update payment for selected'),
                  ),
                ],
              )
            : Row(
                children: [
                  Text('Selected: $selectedCount', style: AppStyles.getMediumTextStyle(fontSize: 13)),
                  const SizedBox(width: 16),
                  SizedBox(width: 220, child: _bulkPaymentDropdown()),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _bulkUpdating ? null : _bulkUpdatePayment,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(_bulkUpdating ? 'Updating...' : 'Apply to selected'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _bulkPaymentDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _bulkPaymentType,
      decoration: CustomFormFieldDecoration.dropdownDecoration(context),
      items: _paymentOptionsNormal.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() => _bulkPaymentType = v);
      },
    );
  }

  Widget _driverDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Driver', style: AppStyles.getMediumTextStyle(fontSize: 12, color: AppColors.hintFontColor)),
        const SizedBox(height: 6),
        DropdownButtonFormField<int?>(
          key: ValueKey(_filterDriverId ?? -1),
          initialValue: _filterDriverId,
          isExpanded: true,
          decoration: CustomFormFieldDecoration.dropdownDecoration(context),
          hint: Text('All drivers', style: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.hintFontColor)),
          items: [
            const DropdownMenuItem<int?>(value: null, child: Text('All drivers')),
            ..._drivers.map((d) => DropdownMenuItem<int?>(value: d.id, child: Text(d.name))),
          ],
          onChanged: (v) => setState(() => _filterDriverId = v),
        ),
      ],
    );
  }

  Widget _searchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Search', style: AppStyles.getMediumTextStyle(fontSize: 12, color: AppColors.hintFontColor)),
        const SizedBox(height: 6),
        TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: const Color(0xFFF5F6F8),
            hintText: 'Receipt, phone, driver...',
            hintStyle: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.hintFontColor),
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.hintFontColor, size: 22),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primaryColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryBar(bool isCompact) {
    final n = _filteredOrders.length;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor.withValues(alpha: 0.08),
            AppColors.primaryColor.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: isCompact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$n ${n == 1 ? 'order' : 'orders'}', style: AppStyles.getMediumTextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    'Total ₹ ${_totalAmount.toStringAsFixed(2)}',
                    style: AppStyles.getBoldTextStyle(fontSize: 18, color: AppColors.primaryColor),
                  ),
                ],
              )
            : Row(
                children: [
                  Icon(Icons.receipt_long_outlined, color: AppColors.primaryColor, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    '$n ${n == 1 ? 'order' : 'orders'} in view',
                    style: AppStyles.getMediumTextStyle(fontSize: 14),
                  ),
                  const Spacer(),
                  Text(
                    'Total ',
                    style: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.hintFontColor),
                  ),
                  Text(
                    '₹ ${_totalAmount.toStringAsFixed(2)}',
                    style: AppStyles.getBoldTextStyle(fontSize: 20, color: AppColors.primaryColor),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: AppColors.hintFontColor.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text(
              'No active driver logs',
              style: AppStyles.getSemiBoldTextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Assign driver in Delivery Log. Delivered/Cancelled orders are hidden from this list.',
                textAlign: TextAlign.center,
                style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.hintFontColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverOrdersTable extends StatelessWidget {
  const _DriverOrdersTable({
    required this.orders,
    required this.selectedOrderIds,
    required this.allVisibleSelected,
    required this.onToggleSelect,
    required this.onToggleSelectAll,
    required this.onUpdateStatus,
    required this.onUpdatePayment,
    required this.onViewItems,
    required this.onPrint,
  });

  final List<Order> orders;
  final Set<int> selectedOrderIds;
  final bool allVisibleSelected;
  final void Function(int orderId, bool selected) onToggleSelect;
  final void Function(bool selected) onToggleSelectAll;
  final Future<void> Function(Order order, String dbStatus) onUpdateStatus;
  final Future<void> Function(Order order, String paymentType) onUpdatePayment;
  final Future<void> Function(Order order) onViewItems;
  final Future<void> Function(Order order) onPrint;

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.divider.withValues(alpha: 0.85);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder(
            horizontalInside: BorderSide(color: borderColor),
            bottom: BorderSide(color: borderColor),
          ),
          columnWidths: const {
            0: FixedColumnWidth(52),
            1: FlexColumnWidth(2.1),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(1.45),
            4: FlexColumnWidth(1.4),
            5: FlexColumnWidth(1.35),
            6: FlexColumnWidth(1.3),
            7: FixedColumnWidth(170),
            8: FixedColumnWidth(100),
          },
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFF5F6F8)),
              children: [
                _headerCellWidget(
                  Checkbox(
                    value: allVisibleSelected,
                    onChanged: (v) => onToggleSelectAll(v == true),
                  ),
                ),
                _headerCell('Receipt'),
                _headerCell('Status'),
                _headerCell('Driver'),
                _headerCell('Customer'),
                _headerCell('Ordered'),
                _headerCell('Payment'),
                _headerCell('Actions'),
                _headerCell('Amount', alignEnd: true),
              ],
            ),
            ...orders.map((o) {
              final selected = selectedOrderIds.contains(o.id);
              return TableRow(
                children: [
                  _dataCell(
                    Checkbox(
                      value: selected,
                      onChanged: (v) => onToggleSelect(o.id, v == true),
                    ),
                  ),
                  _dataCell(
                    Text(
                      o.invoiceNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.getSemiBoldTextStyle(fontSize: 13, color: AppColors.primaryColor),
                    ),
                  ),
                  _dataCell(
                    _StatusDropdown(
                      value: _DriverLogScreenState._displayStatus(o.status),
                      onChanged: (dbStatus) => onUpdateStatus(o, dbStatus),
                    ),
                  ),
                  _dataCell(Text(o.driverName ?? '—', style: AppStyles.getRegularTextStyle(fontSize: 13))),
                  _dataCell(Text(o.customerPhone ?? '—', style: AppStyles.getRegularTextStyle(fontSize: 13))),
                  _dataCell(Text(DateFormat('dd MMM yyyy · HH:mm').format(o.createdAt), style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.hintFontColor))),
                  _dataCell(
                    _PaymentDropdown(
                      value: _paymentTypeFromOrder(o),
                      onChanged: (v) => onUpdatePayment(o, v),
                    ),
                  ),
                  _dataCell(
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'View items',
                          icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                          onPressed: () => onViewItems(o),
                        ),
                        IconButton(
                          tooltip: 'Print',
                          icon: const Icon(Icons.print_outlined, size: 18),
                          onPressed: () => onPrint(o),
                        ),
                      ],
                    ),
                  ),
                  _dataCell(
                    Text(
                      '₹ ${o.finalAmount.toStringAsFixed(2)}',
                      style: AppStyles.getSemiBoldTextStyle(fontSize: 13),
                      textAlign: TextAlign.right,
                    ),
                    alignEnd: true,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  static Widget _headerCell(String label, {bool alignEnd = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 14, 10, 12),
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          label.toUpperCase(),
          style: AppStyles.getSemiBoldTextStyle(fontSize: 10, color: AppColors.hintFontColor),
        ),
      ),
    );
  }

  static Widget _headerCellWidget(Widget child) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      child: Align(alignment: Alignment.center, child: child),
    );
  }

  static Widget _dataCell(Widget child, {bool alignEnd = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: child,
      ),
    );
  }
}

class _DriverOrderCard extends StatelessWidget {
  const _DriverOrderCard({
    required this.order,
    required this.selected,
    required this.onToggleSelect,
    required this.onUpdateStatus,
    required this.onUpdatePayment,
    required this.onViewItems,
    required this.onPrint,
  });

  final Order order;
  final bool selected;
  final void Function(int orderId, bool selected) onToggleSelect;
  final Future<void> Function(Order order, String dbStatus) onUpdateStatus;
  final Future<void> Function(Order order, String paymentType) onUpdatePayment;
  final Future<void> Function(Order order) onViewItems;
  final Future<void> Function(Order order) onPrint;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd MMM yyyy · HH:mm').format(order.createdAt);

    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (v) => onToggleSelect(order.id, v == true),
                ),
                Expanded(
                  child: Text(
                    order.invoiceNumber,
                    style: AppStyles.getSemiBoldTextStyle(fontSize: 13, color: AppColors.primaryColor),
                  ),
                ),
                Text(
                  '₹ ${order.finalAmount.toStringAsFixed(2)}',
                  style: AppStyles.getBoldTextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _info('Driver', order.driverName ?? '—'),
            const SizedBox(height: 6),
            _info('Customer', order.customerPhone ?? '—'),
            const SizedBox(height: 6),
            _info('Ordered', dateStr),
            const SizedBox(height: 10),
            _StatusDropdown(
              value: _DriverLogScreenState._displayStatus(order.status),
              onChanged: (dbStatus) => onUpdateStatus(order, dbStatus),
            ),
            const SizedBox(height: 10),
            _PaymentDropdown(
              value: _paymentTypeFromOrder(order),
              onChanged: (v) => onUpdatePayment(order, v),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => onViewItems(order),
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                  label: const Text('View items'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => onPrint(order),
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text('Print'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _info(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(label, style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.hintFontColor)),
        ),
        Expanded(child: Text(value, style: AppStyles.getMediumTextStyle(fontSize: 13))),
      ],
    );
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({required this.value, required this.onChanged});

  final String value;
  final Future<void> Function(String dbStatus) onChanged;

  static const List<(String, String)> _options = [
    ('Out for delivery', 'assigned'),
    ('Delivered', 'delivered'),
    ('Cancelled', 'cancelled'),
  ];

  @override
  Widget build(BuildContext context) {
    final safeValue = _options.any((e) => e.$1 == value) ? value : 'Out for delivery';
    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      decoration: CustomFormFieldDecoration.dropdownDecoration(context),
      items: _options.map((e) => DropdownMenuItem<String>(value: e.$1, child: Text(e.$1))).toList(),
      onChanged: (v) {
        if (v == null || v == safeValue) return;
        final db = _options.firstWhere((e) => e.$1 == v).$2;
        onChanged(db);
      },
    );
  }
}

class _PaymentDropdown extends StatelessWidget {
  const _PaymentDropdown({required this.value, required this.onChanged});

  final String value;
  final Future<void> Function(String paymentType) onChanged;

  static const List<String> _options = ['CREDIT', 'CASH', 'CARD'];

  @override
  Widget build(BuildContext context) {
    final safe = _options.contains(value) ? value : _options.first;
    return DropdownButtonFormField<String>(
      initialValue: safe,
      decoration: CustomFormFieldDecoration.dropdownDecoration(context),
      items: _options.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: (v) {
        if (v == null || v == safe) return;
        onChanged(v);
      },
    );
  }
}

String _paymentTypeFromOrder(Order o) {
  if (o.creditAmount > 0) return 'CREDIT';
  if (o.cashAmount > 0) return 'CASH';
  if (o.cardAmount > 0) return 'CARD';
  return 'CREDIT';
}
