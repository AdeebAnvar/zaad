import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/utils/order_display_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/presentation/take_away_log/take_away_log_cubit.dart';
import 'package:pos/presentation/widgets/auto_complete_textfield.dart';
import 'package:pos/presentation/widgets/app_snackbar.dart';
import 'package:pos/presentation/widgets/app_standard_dialog.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';
import 'package:pos/presentation/widgets/custom_sheet.dart';
import 'package:pos/presentation/widgets/modern_bottom_sheet.dart' show filterPanelDecoration;
import 'package:pos/presentation/widgets/custom_textfield.dart';
import 'package:pos/presentation/widgets/move_order_dialog.dart';
import 'package:pos/presentation/widgets/order_log_details_dialog.dart';

class TakeAwayLogScreen extends StatelessWidget {
  const TakeAwayLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TakeAwayLogCubit(locator<OrderRepository>()),
      child: CustomScaffold(
        title: 'Take Away Log',
        appBarScreen: 'take_away_log',
        floatingActionButton: _MobileTakeAwayFilterFab(),
        body: BlocBuilder<TakeAwayLogCubit, TakeAwayLogState>(
          builder: (context, state) {
            if (state is TakeAwayLogLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is TakeAwayLogError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<TakeAwayLogCubit>().loadOrders(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is TakeAwayLogLoaded) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 768;
                  return RefreshIndicator(
                    onRefresh: () => context.read<TakeAwayLogCubit>().refreshOrders(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: AppPadding.screenAll,
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
                                    'No orders found',
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
                                      child: TakeAwayCard(order: order),
                                    );
                                  }).toList(),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
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

class _MobileTakeAwayFilterFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final state = context.watch<TakeAwayLogCubit>().state;
    if (!isMobile || state is! TakeAwayLogLoaded) {
      return const SizedBox.shrink();
    }
    return FloatingActionButton(
      onPressed: () {
        final cubit = context.read<TakeAwayLogCubit>();
        CustomSheet.show(
          context: context,
          // maxChildSize: 0.92,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: AppPadding.screenAll,
            child: BlocProvider.value(
              value: cubit,
              child: const _FilterBar(),
            ),
          ),
        );
      },
      backgroundColor: AppColors.primaryColor,
      tooltip: 'Filters',
      child: const Icon(Icons.filter_list, color: Colors.white),
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
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _statusOptions = ['All', 'kot', 'completed', 'placed', 'cancelled'];

  @override
  void dispose() {
    _invoiceController.dispose();
    _referenceController.dispose();
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
    final cubit = context.read<TakeAwayLogCubit>();
    cubit.filterOrders(
      invoiceNumber: _invoiceController.text.trim().isEmpty ? null : _invoiceController.text.trim(),
      referenceNumber: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
      status: _statusController.text.isEmpty || _statusController.text == 'All' ? null : _statusController.text,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  void _clearFilters() {
    setState(() {
      _invoiceController.clear();
      _referenceController.clear();
      _statusController.clear();
      _startDate = null;
      _endDate = null;
    });
    context.read<TakeAwayLogCubit>().loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final fieldW = maxW < 640 ? maxW : 220.0;
        final narrowField = maxW < 640 ? maxW : 200.0;
        final statusW = maxW < 640 ? maxW : 180.0;
        final btnW = maxW < 640 ? maxW : 120.0;
        return Container(
          padding: AppPadding.card,
          decoration: filterPanelDecoration(),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              SizedBox(
                width: fieldW,
                child: CustomTextField(
                  controller: _invoiceController,
                  labelText: 'Receipt No.',
                ),
              ),
              SizedBox(
                width: fieldW,
                child: CustomTextField(
                  controller: _referenceController,
                  labelText: 'Reference No.',
                ),
              ),
              SizedBox(
                width: statusW,
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
                width: narrowField,
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
                width: narrowField,
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
                width: btnW,
                onPressed: _applyFilters,
                text: 'Filter',
                elevation: 0,
              ),
              CustomButton(
                width: btnW,
                onPressed: _clearFilters,
                text: 'Clear',
                backgroundColor: Colors.grey,
                elevation: 0,
              ),
            ],
          ),
        );
      },
    );
  }
}

class TakeAwayCard extends StatefulWidget {
  final Order order;
  const TakeAwayCard({super.key, required this.order});

  @override
  State<TakeAwayCard> createState() => _TakeAwayCardState();
}

class _TakeAwayCardState extends State<TakeAwayCard> {
  bool _hovered = false;
  bool _customerExpanded = false;

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 1,
                color: AppColors.divider.withValues(alpha: 0.65),
              ),
              const SizedBox(height: 12),
              _infoRow(),
              if (orderHasCustomerDetails(widget.order)) _customerPeekSection(),
              const SizedBox(height: 14),
              _netTotal(),
              const SizedBox(height: 14),
              _actions(context),
            ],
          ),
        ),
      ),
    );
  }

  /* ───────── HEADER ───────── */

  Widget _header() {
    final order = widget.order;
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt);

    return Row(
      children: [
        _tag(),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              order.status.toUpperCase(),
              style: AppStyles.getSemiBoldTextStyle(fontSize: 11, color: AppColors.hintFontColor),
            ),
            const SizedBox(height: 2),
            Text(
              formattedDate,
              style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.hintFontColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2F3A56),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.shopping_bag, size: 14, color: Colors.white),
          SizedBox(width: 6),
          Text(
            'TAKE AWAY',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /* ───────── INFO ROW ───────── */

  Widget _customerPeekSection() {
    final label = orderLogCustomerLabel(widget.order);
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: _customerExpanded
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                SizedBox(
                  width: 220,
                  child: _infoBlock('Customer', label.isEmpty ? '—' : label),
                ),
                InkWell(
                  onTap: () => setState(() => _customerExpanded = false),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View less',
                          style: AppStyles.getMediumTextStyle(fontSize: 13, color: AppColors.hintFontColor),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.hintFontColor, size: 22),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: () => setState(() => _customerExpanded = true),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'View more',
                      style: AppStyles.getMediumTextStyle(fontSize: 13, color: AppColors.primaryColor),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryColor, size: 22),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _infoRow() {
    final order = widget.order;
    return Wrap(
      spacing: 20,
      runSpacing: 10,
      children: [
        SizedBox(width: 220, child: _infoBlock('Receipt No', order.invoiceNumber)),
        SizedBox(width: 220, child: _infoBlock('Reference', order.referenceNumber ?? 'N/A')),
      ],
    );
  }

  Widget _infoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.hintFontColor),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppStyles.getMediumTextStyle(fontSize: 15, color: AppColors.textColor),
        ),
      ],
    );
  }

  /* ───────── NET TOTAL ───────── */

  Widget _netTotal() {
    final total = widget.order.totalAmount;

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

  /* ───────── ACTIONS ───────── */

  Widget _actions(BuildContext context) {
    final order = widget.order;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _cleanActionButton(
          icon: Icons.remove_red_eye_outlined,
          label: 'View',
          onTap: () => _handleView(context, order),
        ),
        _cleanActionButton(
          icon: Icons.print_outlined,
          label: 'Print',
          onTap: () => _handlePrint(context, order),
        ),
        _cleanActionButton(
          icon: Icons.edit_outlined,
          label: 'Edit',
          onTap: () => _handleEdit(context, order),
        ),
        _cleanActionButton(
          icon: Icons.delete_outline,
          label: 'Delete',
          onTap: () => _handleDelete(context, order),
          danger: true,
        ),
        _cleanActionButton(
          icon: Icons.drive_file_move_outline,
          label: 'Move',
          onTap: () => showMoveOrderDialog(
            context,
            order: order,
            sourceOrderType: 'take_away',
            onSuccess: () => context.read<TakeAwayLogCubit>().refreshOrders(),
          ),
        ),
      ],
    );
  }

  Widget _cleanActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 18,
        color: danger ? Colors.red : AppColors.primaryColor,
      ),
      label: Text(
        label,
        style: AppStyles.getMediumTextStyle(
          fontSize: 13,
          color: danger ? Colors.red : AppColors.primaryColor,
        ),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        side: BorderSide(
          color: danger ? Colors.red.withValues(alpha: 0.35) : AppColors.primaryColor.withValues(alpha: 0.25),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  /* ───────── ACTION HANDLERS (UNCHANGED) ───────── */

  void _handleEdit(BuildContext context, Order order) {
    Navigator.pushNamed(
      context,
      '/counter',
      arguments: {'orderId': order.id},
    ).then((_) {
      context.read<TakeAwayLogCubit>().refreshOrders();
    });
  }

  Future<void> _handlePrint(BuildContext context, Order order) async {
    final cartRepo = locator<CartRepository>();
    final printService = locator<PrintService>();
    final cartItems = await cartRepo.getCartItemsByCartId(order.cartId);
    if (cartItems == null || cartItems.isEmpty) {
      if (context.mounted) {
        showAppSnackBar(context, 'No items to print');
      }
      return;
    }
    try {
      final printFailed = await printService.printFinalBill(order: order, cartItems: cartItems);
      if (context.mounted) {
        if (printFailed.isEmpty) {
          showAppSnackBar(context, 'Bill sent to printer');
        } else {
          showPrintFailedDialog(context, printFailed);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showErrorDialog(context, e);
      }
    }
  }

  Future<void> _handleDelete(BuildContext context, Order order) async {
    final ok = await showAppConfirmDialog(
      context,
      title: 'Delete Order',
      message: 'Are you sure you want to delete order ${order.invoiceNumber}?',
      confirmText: 'Delete',
      confirmBackgroundColor: Colors.red,
    );
    if (ok == true && context.mounted) {
      await context.read<TakeAwayLogCubit>().deleteOrder(order.id);
    }
  }

  Future<void> _handleView(BuildContext context, Order order) async {
    final cartRepo = locator<CartRepository>();
    final itemRepo = locator<ItemRepository>();

    final cartItems = await cartRepo.getCartItemsByCartId(order.cartId);

    if (cartItems == null || cartItems.isEmpty) {
      if (!context.mounted) return;
      await showAppMessageDialog(
        context,
        title: 'Order Details',
        message: 'No items found in this order.',
      );
      return;
    }

    final List<Map<String, dynamic>> itemsWithDetails = [];

    for (final cartItem in cartItems) {
      final item = await itemRepo.fetchItemByIdFromLocal(cartItem.itemId);
      final variant = cartItem.itemVariantId != null ? await itemRepo.fetchVariantById(cartItem.itemVariantId!) : null;
      final topping = cartItem.itemToppingId != null ? await itemRepo.fetchToppingById(cartItem.itemToppingId!) : null;

      itemsWithDetails.add({
        'cartItem': cartItem,
        'item': item,
        'variant': variant,
        'topping': topping,
      });
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => OrderLogDetailsDialog(
          order: order,
          itemsWithDetails: itemsWithDetails,
        ),
      );
    }
  }
}
