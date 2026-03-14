import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pos/app/di.dart';
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
import 'package:pos/data/repository/delivery_partner_repository.dart';

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
                              if (!isMobile) const SizedBox(height: 16),
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
                                        .map((order) => SizedBox(
                                              width: cardWidth,
                                              child: _DeliveryCard(order: order),
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
                              builder: (_, scrollController) => SingleChildScrollView(
                                controller: scrollController,
                                child: Padding(
                                  padding: AppPadding.screenAll,
                                  child: const _DeliveryFilterBar(),
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
  final _referenceController = TextEditingController();
  final _partnerController = TextEditingController();
  final _statusController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  List<String> _partnerNames = [];
  final List<String> _statusOptions = ['All', 'kot', 'placed', 'cancelled'];

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    final partners = await locator<DeliveryPartnerRepository>().getAll();
    if (mounted) {
      setState(() => _partnerNames = partners.map((p) => p.name).toList());
    }
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _referenceController.dispose();
    _partnerController.dispose();
    _statusController.dispose();
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
    context.read<DeliveryLogCubit>().filterOrders(
          invoiceNumber: _invoiceController.text.trim().isEmpty ? null : _invoiceController.text.trim(),
          referenceNumber: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
          deliveryPartner: _partnerController.text.trim().isEmpty ? null : _partnerController.text.trim(),
          status: _statusController.text.isEmpty || _statusController.text == 'All' ? null : _statusController.text,
          startDate: _startDate,
          endDate: _endDate,
        );
  }

  void _clearFilters() {
    setState(() {
      _invoiceController.clear();
      _referenceController.clear();
      _partnerController.clear();
      _statusController.clear();
      _startDate = null;
      _endDate = null;
    });
    context.read<DeliveryLogCubit>().loadOrders();
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
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          SizedBox(width: 220, child: CustomTextField(controller: _invoiceController, labelText: 'Receipt No.')),
          SizedBox(width: 220, child: CustomTextField(controller: _referenceController, labelText: 'Reference No.')),
          SizedBox(
            width: 180,
            child: AutoCompleteTextField<String>(
              defaultText: 'Delivery Partner',
              displayStringFunction: (v) => v,
              items: _partnerNames,
              onSelected: (v) => setState(() => _partnerController.text = v),
              controller: _partnerController,
            ),
          ),
          SizedBox(
            width: 180,
            child: AutoCompleteTextField<String>(
              defaultText: 'Status',
              displayStringFunction: (v) => v,
              items: _statusOptions,
              onSelected: (v) => setState(() => _statusController.text = v),
              controller: _statusController,
            ),
          ),
          _datePicker('Start Date', _startDate, true),
          _datePicker('End Date', _endDate, false),
          CustomButton(width: 120, onPressed: _applyFilters, text: 'Filter'),
          CustomButton(width: 120, onPressed: _clearFilters, text: 'Clear', backgroundColor: Colors.grey),
        ],
      ),
    );
  }

  Widget _datePicker(String label, DateTime? value, bool isStart) {
    return SizedBox(
      width: 200,
      child: InkWell(
        onTap: () => _selectDate(context, isStart),
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
                  value == null ? label : DateFormat('dd-MM-yyyy').format(value),
                  style: TextStyle(color: value == null ? Colors.grey : Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryCard extends StatefulWidget {
  final Order order;

  const _DeliveryCard({required this.order});

  @override
  State<_DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends State<_DeliveryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt);

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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delivery_dining, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text('DELIVERY', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (order.deliveryPartner != null && order.deliveryPartner!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          order.deliveryPartner!,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.orange.shade900),
                        ),
                      ),
                    ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(order.status.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(formattedDate, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _infoBlock('Receipt No', order.invoiceNumber),
                  const SizedBox(width: 48),
                  _infoBlock('Reference', order.referenceNumber ?? 'N/A'),
                ],
              ),
              const SizedBox(height: 14),
              Container(
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
                    Text('Net Total', style: AppStyles.getMediumTextStyle(fontSize: 14, color: Colors.grey.shade600)),
                    const Spacer(),
                    Text('₹ ${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _actionIcon(Icons.remove_red_eye_outlined, 'View', () => _handleView(context, order)),
                  _actionIcon(Icons.print_outlined, 'Print', () => _handlePrint(context, order)),
                  _actionIcon(Icons.edit_outlined, 'Edit', () => _handleEdit(context, order)),
                  _actionIcon(Icons.delete_outline, 'Delete', () => _handleDelete(context, order), bg: Colors.red),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
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
