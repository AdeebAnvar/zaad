import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pos/app/di.dart';
import 'package:pos/data/repository/customer_repository.dart';
import 'package:pos/domain/models/customer_model.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/presentation/delivery_log/delivery_log_cubit.dart';
import 'package:pos/presentation/widgets/auto_complete_textfield.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';
import 'package:pos/presentation/driver_log/driver_log_screen.dart';

class DeliveryLogScreen extends StatelessWidget {
  const DeliveryLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Delivery Sale Log',
      appBarScreen: 'delivery_log',
      body: BlocBuilder<DeliveryLogCubit, DeliveryLogState>(
        builder: (context, state) {
          if (state is DeliveryLogLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DeliveryLogError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<DeliveryLogCubit>().loadOrders(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is DeliveryLogLoaded) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 768;
                return Stack(
                  children: [
                    RefreshIndicator(
                      onRefresh: () => context.read<DeliveryLogCubit>().refreshOrders(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: AppPadding.screenAll,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMobile) const _DeliveryFilterBar(),
                              _PartnerTabs(
                                selectedPartner: state.selectedPartner,
                                deliveryPartners: state.deliveryPartners,
                                onSelect: (p) => context.read<DeliveryLogCubit>().selectPartnerTab(p),
                              ),
                              if (state.orders.isEmpty)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Text(
                                      'No delivery orders found',
                                      style: TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                  ),
                                )
                              else
                                LayoutBuilder(builder: (context, constraints) {
                                  final width = constraints.maxWidth;
                                  final columns = width >= 1200 ? 3 : width >= 700 ? 2 : 1;
                                  const spacing = 16.0;
                                  final cardWidth = (width - (columns - 1) * spacing) / columns;
                                  return Wrap(
                                    spacing: spacing,
                                    runSpacing: spacing,
                                    children: state.orders
                                        .asMap()
                                        .entries
                                        .map((e) => SizedBox(
                                              width: cardWidth,
                                              child: _DeliveryCard(order: e.value, serialNo: e.key + 1),
                                            ))
                                        .toList(),
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
                              builder: (_, scrollController) => BlocBuilder<DeliveryLogCubit, DeliveryLogState>(
                                builder: (context, sheetState) {
                                  return SingleChildScrollView(
                                    controller: scrollController,
                                    child: Padding(
                                      padding: AppPadding.screenAll,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const _DeliveryFilterBar(),
                                          if (sheetState is DeliveryLogLoaded)
                                            _PartnerTabs(
                                              selectedPartner: sheetState.selectedPartner,
                                              deliveryPartners: sheetState.deliveryPartners,
                                              onSelect: (p) => context.read<DeliveryLogCubit>().selectPartnerTab(p),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
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
    );
  }
}

class _DeliveryFilterBar extends StatefulWidget {
  const _DeliveryFilterBar();

  @override
  State<_DeliveryFilterBar> createState() => _DeliveryFilterBarState();
}

class _DeliveryFilterBarState extends State<_DeliveryFilterBar> {
  final _invoiceController = TextEditingController();
  final _customerController = TextEditingController();
  final _usersController = TextEditingController();

  List<CustomerModel> _customers = [];
  String? _selectedCustomerPhone;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      final customers = await locator<CustomerRepository>().getAllLocalCustomers();
      if (mounted) setState(() => _customers = customers);
    } catch (_) {
      if (mounted) setState(() => _customers = []);
    }
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _customerController.dispose();
    _usersController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<DeliveryLogCubit>().filterOrders(
          invoiceNumber: _invoiceController.text.trim().isEmpty ? null : _invoiceController.text.trim(),
          customerPhone: _selectedCustomerPhone,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPadding.card,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 220,
                  child: AutoCompleteTextField<CustomerModel>(
                    defaultText: 'SELECT',
                    labelText: 'Customer',
                    displayStringFunction: (c) => c.phone != null && c.phone!.isNotEmpty
                        ? '${c.name} - ${c.phone}'
                        : c.name,
                    items: _customers.where((c) => c.phone != null && c.phone!.isNotEmpty).toList(),
                    onSelected: (c) => setState(() {
                      _customerController.text = '${c.name} - ${c.phone ?? ''}';
                      _selectedCustomerPhone = c.phone;
                    }),
                    onChanged: (v) {
                      if (v.isEmpty) setState(() => _selectedCustomerPhone = null);
                    },
                    controller: _customerController,
                  ),
                ),
                SizedBox(width: 180, child: CustomTextField(controller: _invoiceController, labelText: 'Receipt No.')),
                SizedBox(
                  width: 140,
                  child: AutoCompleteTextField<String>(
                    defaultText: 'SELECT',
                    labelText: 'Users',
                    displayStringFunction: (v) => v,
                    items: const ['SELECT', 'User 1', 'User 2'],
                    onSelected: (_) {},
                    controller: _usersController,
                  ),
                ),
                CustomButton(width: 100, onPressed: _applyFilters, text: 'Submit'),
              ],
            ),
          ),
          CustomButton(
            width: 120,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DriverLogScreen(),
                ),
              );
            },
            text: 'Driver Log',
          ),
        ],
      ),
    );
  }

}

class _PartnerTabs extends StatelessWidget {
  final String? selectedPartner;
  final List<DeliveryPartner> deliveryPartners;
  final ValueChanged<String?> onSelect;

  const _PartnerTabs({
    this.selectedPartner,
    required this.deliveryPartners,
    required this.onSelect,
  });

  static bool _samePartner(String? a, String? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.toUpperCase() == b.toUpperCase();
  }

  static String _chipLabel(String filterValue) {
    final t = filterValue.trim();
    if (t.isEmpty) return '?';
    if (t.toUpperCase() == 'NORMAL') return 'Normal';
    return t;
  }

  /// ALL + partners from DB/sync (deduped) + NORMAL (own delivery) if not already in sync list.
  List<({String label, String? value})> _buildTabs() {
    final tabs = <({String label, String? value})>[
      (label: 'ALL', value: null),
    ];
    final seen = <String>{};
    for (final p in deliveryPartners) {
      final v = p.name.trim();
      if (v.isEmpty) continue;
      final key = v.toUpperCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      tabs.add((label: _chipLabel(v), value: v));
    }
    if (!seen.contains('NORMAL')) {
      tabs.add((label: 'Normal', value: 'NORMAL'));
    }
    return tabs;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _buildTabs();
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: tabs.map((t) {
            final isSelected = _samePartner(selectedPartner, t.value);
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Material(
                color: isSelected ? AppColors.primaryColor : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: AppColors.primaryColor),
                ),
                child: InkWell(
                  onTap: () => onSelect(t.value),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      t.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatefulWidget {
  final Order order;
  final int serialNo;

  const _DeliveryCard({required this.order, required this.serialNo});

  @override
  State<_DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends State<_DeliveryCard> {
  bool _hovered = false;
  String _status = '';
  String _paymentType = '';
  /// Bumps when user cancels confirmation so the dropdown rebuilds and shows the previous value.
  int _statusDropdownRevision = 0;
  int _paymentDropdownRevision = 0;

  @override
  void initState() {
    super.initState();
    _status = widget.order.status;
    _paymentType = _getPaymentType(widget.order);
  }

  @override
  void didUpdateWidget(covariant _DeliveryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.order.id != oldWidget.order.id) {
      _status = widget.order.status;
      _paymentType = _getPaymentType(widget.order);
      return;
    }
    // Same row: sync when parent list refreshes after a successful save (or external update).
    if (widget.order.status != oldWidget.order.status ||
        widget.order.cashAmount != oldWidget.order.cashAmount ||
        widget.order.cardAmount != oldWidget.order.cardAmount ||
        widget.order.onlineAmount != oldWidget.order.onlineAmount) {
      _status = widget.order.status;
      _paymentType = _getPaymentType(widget.order);
    }
  }

  String _getPaymentType(Order o) {
    if (o.onlineAmount > 0) return 'ONLINE';
    if (o.cashAmount > 0) return 'CASH';
    if (o.cardAmount > 0) return 'CARD';
    return 'CASH';
  }

  Future<bool> _showUpdateConfirmation({
    required String title,
    required String message,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.primaryColor),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final partnerLabel = order.deliveryPartner ?? 'Normal';
    final formattedDate = DateFormat('dd-MM-yyyy HH:mm:ss').format(order.createdAt);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F3A56),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.local_shipping, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text('DELIVERY - ${partnerLabel.toUpperCase()}', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(formattedDate, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('S.No', '${widget.serialNo}'),
                        const SizedBox(height: 8),
                        _infoRow('Order Number', order.referenceNumber ?? '-'),
                        const SizedBox(height: 8),
                        _statusDropdown(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow('Receipt No', order.invoiceNumber),
                        const SizedBox(height: 8),
                        _infoRow('Customer / Driver', order.customerPhone ?? order.customerName ?? '-'),
                        const SizedBox(height: 8),
                        _paymentTypeDropdown(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _actionIcon(Icons.remove_red_eye_outlined, 'View', () => _handleView(context, order)),
                  _actionIcon(Icons.print_outlined, 'Print', () => _handlePrint(context, order)),
                  _actionIcon(Icons.edit_outlined, 'Edit', () => _handleEdit(context, order)),
                  _actionIcon(Icons.delete_outline, 'Delete', () => _handleDelete(context, order), bg: Colors.red),
                  const Spacer(),
                  CustomButton(
                    width: 80,
                    text: 'Move',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Move - Coming soon')));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // DB status -> Display (for showing current value)
  static const _dbToDisplay = {
    'placed': 'Pending',
    'pending': 'Pending',
    'dispatched': 'Dispatched',
    'assigned': 'Assigned',
    'delivered': 'Delivered',
    'completed': 'Delivered',
    'kot': 'Pending',
    'cancelled': 'Cancelled',
  };

  // Delivery partner (NOON, KEETA, TALABAT): Pending, Dispatched, Cancelled
  static const _partnerStatusOptions = [
    ('Pending', 'pending'),
    ('Dispatched', 'dispatched'),
    ('Cancelled', 'cancelled'),
  ];

  // NORMAL: Pending, Assigned, Delivered, Cancelled
  static const _normalStatusOptions = [
    ('Pending', 'pending'),
    ('Assigned', 'assigned'),
    ('Delivered', 'delivered'),
    ('Cancelled', 'cancelled'),
  ];

  Widget _statusDropdown() {
    final isNormal = widget.order.deliveryPartner?.toUpperCase() == 'NORMAL';
    final options = isNormal ? _normalStatusOptions : _partnerStatusOptions;

    final dbStatus = _status.isEmpty ? 'pending' : _status;
    final displayStatus = _dbToDisplay[dbStatus] ?? 'Pending';
    final validDisplay = options.any((e) => e.$1 == displayStatus) ? displayStatus : options.first.$1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          key: ValueKey<String>('status_${widget.order.id}_$_statusDropdownRevision'),
          value: validDisplay,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          items: options.map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$1, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) async {
            if (v == null) return;
            final newStatus = options.firstWhere((e) => e.$1 == v).$2;
            if (newStatus == _status) return;
            final confirmed = await _showUpdateConfirmation(
              title: 'Confirm Status Change',
              message: 'Change order status to "$v"?',
            );
            if (!mounted) return;
            if (!confirmed) {
              setState(() => _statusDropdownRevision++);
              return;
            }
            // Only persist and refresh list after Confirm; UI updates when cubit reloads (didUpdateWidget).
            await context.read<DeliveryLogCubit>().updateOrderStatus(widget.order.id, newStatus);
          },
        ),
      ],
    );
  }

  static const _paymentOptions = ['CASH', 'CARD', 'ONLINE'];

  Widget _paymentTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Type', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          key: ValueKey<String>('pay_${widget.order.id}_$_paymentDropdownRevision'),
          value: _paymentType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            isDense: true,
          ),
          items: _paymentOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) async {
            if (v == null) return;
            if (v == _paymentType) return;
            final confirmed = await _showUpdateConfirmation(
              title: 'Confirm Payment Type Change',
              message: 'Change payment type to "$v"?',
            );
            if (!mounted) return;
            if (!confirmed) {
              setState(() => _paymentDropdownRevision++);
              return;
            }
            await context.read<DeliveryLogCubit>().updateOrderPaymentType(widget.order.id, v, widget.order.finalAmount);
          },
        ),
      ],
    );
  }

  Widget _actionIcon(IconData icon, String tooltip, VoidCallback onTap, {Color? bg}) {
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
            decoration: BoxDecoration(color: bg ?? AppColors.primaryColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }

  void _handleEdit(BuildContext context, Order order) {
    Navigator.pushNamed(
      context,
      '/counter',
      arguments: {
        'orderId': order.id,
        'orderType': order.orderType ?? 'delivery',
        'deliveryPartner': order.deliveryPartner,
      },
    ).then((_) {
      context.read<DeliveryLogCubit>().refreshOrders();
    });
  }

  Future<void> _handlePrint(BuildContext context, Order order) async {
    final cartRepo = locator<CartRepository>();
    final printService = locator<PrintService>();
    final cartItems = await cartRepo.getCartItemsByCartId(order.cartId);
    if (cartItems == null || cartItems.isEmpty) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No items to print')));
      return;
    }
    try {
      await printService.printFinalBill(order: order, cartItems: cartItems);
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill sent to printer')));
    } catch (e) {
      if (context.mounted) showErrorDialog(context, e);
    }
  }

  void _handleDelete(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order'),
        content: Text('Are you sure you want to delete order ${order.invoiceNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          CustomButton(
            width: 100,
            backgroundColor: Colors.red,
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<DeliveryLogCubit>().deleteOrder(order.id);
            },
            text: 'Delete',
          ),
        ],
      ),
    );
  }

  Future<void> _handleView(BuildContext context, Order order) async {
    final cartRepo = locator<CartRepository>();
    final itemRepo = locator<ItemRepository>();
    final cartItems = await cartRepo.getCartItemsByCartId(order.cartId);
    if (cartItems == null || cartItems.isEmpty) {
      if (!context.mounted) return;
      showDialog(context: context, builder: (_) => const AlertDialog(title: Text('Order Details'), content: Text('No items found in this order.')));
      return;
    }
    final List<Map<String, dynamic>> itemsWithDetails = [];
    for (final cartItem in cartItems) {
      final item = await itemRepo.fetchItemByIdFromLocal(cartItem.itemId);
      final variant = cartItem.itemVariantId != null ? await itemRepo.fetchVariantById(cartItem.itemVariantId!) : null;
      final topping = cartItem.itemToppingId != null ? await itemRepo.fetchToppingById(cartItem.itemToppingId!) : null;
      itemsWithDetails.add({'cartItem': cartItem, 'item': item, 'variant': variant, 'topping': topping});
    }
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Order ${order.invoiceNumber}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.deliveryPartner != null) Text('Partner: ${order.deliveryPartner}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...itemsWithDetails.map((m) {
                  final item = m['item'] as Item?;
                  final cartItem = m['cartItem'] as CartItem;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('${item?.name ?? "?"} x${cartItem.quantity} - ₹${cartItem.total.toStringAsFixed(2)}'),
                  );
                }),
              ],
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
        ),
      );
    }
  }
}
