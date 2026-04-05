import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pos/app/di.dart';
import 'package:pos/app/routes.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/core/utils/order_display_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/presentation/dine_in_log/dine_in_log_cubit.dart';
import 'package:pos/presentation/dine_in_log/dine_in_move_table_sheet.dart';
import 'package:pos/presentation/dine_in_log/dine_in_split_merge_dialogs.dart';
import 'package:pos/presentation/widgets/app_snackbar.dart';
import 'package:pos/presentation/widgets/auto_complete_textfield.dart';
import 'package:pos/presentation/widgets/app_standard_dialog.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';
import 'package:pos/presentation/widgets/custom_sheet.dart';
import 'package:pos/presentation/widgets/modern_bottom_sheet.dart' show filterPanelDecoration;
import 'package:pos/presentation/widgets/custom_textfield.dart';
import 'package:pos/presentation/widgets/move_order_dialog.dart';
import 'package:pos/presentation/widgets/order_log_details_dialog.dart';

class DineInLogScreen extends StatelessWidget {
  const DineInLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DineInLogCubit(locator<OrderRepository>(), locator<CartRepository>()),
      child: CustomScaffold(
        title: 'Dine In Log',
        appBarScreen: 'take_away_log',
        floatingActionButton: const _MobileDineInFilterFab(),
        body: BlocBuilder<DineInLogCubit, DineInLogState>(
          builder: (context, state) {
            if (state is DineInLogLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DineInLogError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<DineInLogCubit>().loadOrders(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            if (state is! DineInLogLoaded) {
              return const SizedBox.shrink();
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 768;
                return RefreshIndicator(
                  onRefresh: () => context.read<DineInLogCubit>().refreshOrders(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: AppPadding.screenAll,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMobile) const _DineInFilterBar(),
                          if (!isMobile) const SizedBox(height: 16),
                          if (state.orders.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Text(
                                  'No dine in orders',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            LayoutBuilder(
                              builder: (context, c) {
                                final width = c.maxWidth;
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
                                  children: state.orders
                                      .map((o) => SizedBox(
                                            width: cardWidth,
                                            child: DineInLogCard(
                                              order: o,
                                              cartLineCount: state.cartLineCountsByCartId[o.cartId] ?? 0,
                                            ),
                                          ))
                                      .toList(),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MobileDineInFilterFab extends StatelessWidget {
  const _MobileDineInFilterFab();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final state = context.watch<DineInLogCubit>().state;
    if (!isMobile || state is! DineInLogLoaded) {
      return const SizedBox.shrink();
    }
    return FloatingActionButton(
      onPressed: () {
        final cubit = context.read<DineInLogCubit>();
        CustomSheet.show(
          context: context,
          maxChildSize: 0.92,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: AppPadding.screenAll,
            child: BlocProvider.value(
              value: cubit,
              child: const _DineInFilterBar(),
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

class _DineInFilterBar extends StatefulWidget {
  const _DineInFilterBar();

  @override
  State<_DineInFilterBar> createState() => _DineInFilterBarState();
}

class _DineInFilterBarState extends State<_DineInFilterBar> {
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

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _applyFilters() {
    context.read<DineInLogCubit>().filterOrders(
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
    context.read<DineInLogCubit>().loadOrders();
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
                child: CustomTextField(controller: _invoiceController, labelText: 'Receipt No.'),
              ),
              SizedBox(
                width: fieldW,
                child: CustomTextField(controller: _referenceController, labelText: 'Table / Ref'),
              ),
              SizedBox(
                width: statusW,
                child: AutoCompleteTextField<String>(
                  defaultText: 'Select Status',
                  displayStringFunction: (v) => v,
                  items: _statusOptions,
                  onSelected: (v) => setState(() => _statusController.text = v),
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
                            style: TextStyle(color: _startDate == null ? Colors.grey : Colors.black),
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
                            style: TextStyle(color: _endDate == null ? Colors.grey : Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              CustomButton(width: btnW, onPressed: _applyFilters, text: 'Filter', elevation: 0),
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

class DineInLogCard extends StatefulWidget {
  const DineInLogCard({
    super.key,
    required this.order,
    required this.cartLineCount,
  });

  final Order order;
  final int cartLineCount;

  @override
  State<DineInLogCard> createState() => _DineInLogCardState();
}

class _DineInLogCardState extends State<DineInLogCard> {
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
              color: Colors.black.withValues(alpha: _hovered ? 0.25 : 0.08),
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

  Widget _header() {
    final order = widget.order;
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2F3A56),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.restaurant, size: 14, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'DINE IN',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                order.status.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: AppStyles.getSemiBoldTextStyle(fontSize: 11, color: AppColors.hintFontColor),
              ),
              const SizedBox(height: 2),
              Text(
                formattedDate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.hintFontColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _customerPeekSection() {
    final label = orderLogCustomerLabel(widget.order);
    return LayoutBuilder(
      builder: (context, c) {
        final blockW = math.min(220.0, c.maxWidth);
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
                      width: blockW,
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
      },
    );
  }

  Widget _infoRow() {
    final order = widget.order;
    return LayoutBuilder(
      builder: (context, c) {
        final blockW = math.min(220.0, c.maxWidth);
        return Wrap(
          spacing: 20,
          runSpacing: 10,
          children: [
            SizedBox(width: blockW, child: _infoBlock('Receipt No', order.invoiceNumber)),
            SizedBox(width: blockW, child: _infoBlock('Table / Ref', order.referenceNumber ?? 'N/A')),
          ],
        );
      },
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
          Expanded(
            child: Text(
              'Net Total',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.getMediumTextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              '₹ ${total.toStringAsFixed(2)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    final order = widget.order;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _actionBtn(
          icon: Icons.remove_red_eye_outlined,
          label: 'View',
          onTap: () => _handleView(context, order),
        ),
        _actionBtn(
          icon: Icons.print_outlined,
          label: 'Print',
          onTap: () => _handlePrint(context, order),
        ),
        _actionBtn(
          icon: Icons.edit_outlined,
          label: 'Edit',
          onTap: () => _handleEdit(context, order),
        ),
        if (dineInBillIsSplittable(order) && widget.cartLineCount > 1)
          _actionBtn(
            icon: Icons.call_split,
            label: 'Split',
            onTap: () => _handleSplit(context, order),
          ),
        if (dineInBillIsSplittable(order))
          _actionBtn(
            icon: Icons.merge_type,
            label: 'Merge',
            onTap: () => _handleMerge(context, order),
          ),
        _actionBtn(
          icon: Icons.layers_outlined,
          label: 'Floor',
          onTap: () => _handleMoveFloorTable(context, order),
        ),
        _actionBtn(
          icon: Icons.drive_file_move_outline,
          label: 'Move',
          onTap: () => showMoveOrderDialog(
                context,
                order: order,
                sourceOrderType: 'dine_in',
                onSuccess: () => context.read<DineInLogCubit>().refreshOrders(),
              ),
        ),
        _actionBtn(
          icon: Icons.delete_outline,
          label: 'Delete',
          onTap: () => _handleDelete(context, order),
          danger: true,
        ),
      ],
    );
  }

  Future<void> _handleSplit(BuildContext context, Order order) async {
    await showDineInSplitBillUi(context, order);
  }

  void _handleMerge(BuildContext context, Order order) {
    final state = context.read<DineInLogCubit>().state;
    if (state is! DineInLogLoaded) return;
    final ref = order.referenceNumber?.trim();
    if (ref == null || ref.isEmpty) {
      showAppMessageDialog(
        context,
        title: 'Merge bill',
        message: 'Set a table reference (Floor) before merging bills.',
      );
      return;
    }
    final others = state.orders.where((o) {
      if (o.id == order.id) return false;
      if (o.referenceNumber?.trim() != ref) return false;
      return dineInBillIsSplittable(o);
    }).toList();
    showDineInMergeBillUi(context, order, others);
  }

  void _handleMoveFloorTable(BuildContext context, Order order) {
    showDineInMoveFloorTableUi(context, order);
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: danger ? Colors.red : AppColors.primaryColor),
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

  void _handleEdit(BuildContext context, Order order) {
    Navigator.pushNamed(
      context,
      Routes.counter,
      arguments: {
        'orderId': order.id,
        'orderType': 'dine_in',
      },
    ).then((_) {
      if (context.mounted) {
        context.read<DineInLogCubit>().refreshOrders();
      }
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
      await context.read<DineInLogCubit>().deleteOrder(order.id);
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
