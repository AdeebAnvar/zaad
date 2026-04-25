import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
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
import 'package:pos/presentation/widgets/custom_scaffold.dart';
import 'package:pos/presentation/widgets/custom_sheet.dart';
import 'package:pos/presentation/widgets/log_filter_shell.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';
import 'package:pos/presentation/widgets/move_order_dialog.dart';
import 'package:pos/presentation/widgets/order_log_details_dialog.dart';
import 'package:pos/presentation/sale/desktop/desktop_cart_panel.dart';
import 'package:pos/presentation/widgets/qty_password_guard.dart';
import 'package:pos/presentation/widgets/relative_time_text.dart';

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
                                      width: 400,
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
  final _usersController = TextEditingController();
  final List<String> _userOptions = ['All users', 'User 1', 'User 2'];

  @override
  void dispose() {
    _invoiceController.dispose();
    _referenceController.dispose();
    _usersController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final cubit = context.read<TakeAwayLogCubit>();
    cubit.filterOrders(
      invoiceNumber: _invoiceController.text.trim().isEmpty ? null : _invoiceController.text.trim(),
      referenceNumber: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
    );
  }

  void _clearFilters() {
    setState(() {
      _invoiceController.clear();
      _referenceController.clear();
      _usersController.clear();
    });
    context.read<TakeAwayLogCubit>().loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final m = LogFilterLayout(constraints.maxWidth);
        return LogFilterShell(
          title: 'Filters',
          subtitle: 'Receipt No, Reference No, and Users',
          icon: Icons.filter_alt_outlined,
          body: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: m.fieldWidth,
                child: CustomTextField(
                  controller: _invoiceController,
                  labelText: 'Receipt No.',
                  onChanged: (_) => _applyFilters(),
                ),
              ),
              SizedBox(
                width: m.fieldWidth,
                child: CustomTextField(
                  controller: _referenceController,
                  labelText: 'Reference No.',
                  onChanged: (_) => _applyFilters(),
                ),
              ),
              SizedBox(
                width: m.compactFieldWidth,
                child: AutoCompleteTextField<String>(
                  defaultText: 'All users',
                  labelText: 'Users',
                  displayStringFunction: (v) => v,
                  items: _userOptions,
                  onSelected: (v) {
                    setState(() {
                      _usersController.text = v;
                    });
                    _applyFilters();
                  },
                  onChanged: (_) => _applyFilters(),
                  controller: _usersController,
                ),
              ),
              SizedBox(
                width: 42,
                child: IconButton(
                  tooltip: 'Clear all',
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.close_rounded),
                ),
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
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_hovered ? 0.16 : 0.06),
              blurRadius: _hovered ? 16 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 1,
                color: AppColors.divider.withValues(alpha: 0.65),
              ),
              const SizedBox(height: 8),
              _infoRow(),
              if (orderHasCustomerDetails(widget.order)) _customerPeekSection(),
              const SizedBox(height: 10),
              _netTotal(),
              const SizedBox(height: 10),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tag(),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  order.status.toUpperCase(),
                  style: AppStyles.getSemiBoldTextStyle(fontSize: 11, color: AppColors.hintFontColor),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade700),
                  tooltip: 'Delete order',
                  onPressed: () => _handleDelete(context, order),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                ),
              ],
            ),
            RelativeTimeText(
              at: order.createdAt,
              style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.hintFontColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              fontSize: 11,
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
                const SizedBox(height: 8),
                SizedBox(
                  width: 180,
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
      spacing: 14,
      runSpacing: 8,
      children: [
        SizedBox(width: 160, child: _infoBlock('Receipt No', order.invoiceNumber)),
        SizedBox(width: 160, child: _infoBlock('Reference', order.referenceNumber ?? 'N/A')),
      ],
    );
  }

  Widget _infoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.getRegularTextStyle(fontSize: 10.5, color: AppColors.hintFontColor),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppStyles.getMediumTextStyle(fontSize: 14, color: AppColors.textColor),
        ),
      ],
    );
  }

  /* ───────── NET TOTAL ───────── */

  Widget _netTotal() {
    final total = widget.order.totalAmount;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Net Total',
            style: AppStyles.getMediumTextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const Spacer(),
          Text(
            RuntimeAppSettings.money(total),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 14),
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
          icon: Icons.payments_outlined,
          label: 'Pay',
          onTap: () => _handlePay(context, order),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

  void _handlePay(BuildContext context, Order order) {
    showCartStylePaymentDialogForOrder(
      context,
      order: order,
      onPaymentRecorded: () => context.read<TakeAwayLogCubit>().refreshOrders(),
    );
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
      final printFailed = await printService.printFinalBill(
        order: order,
        cartItems: cartItems,
        settledBill: true,
      );
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
    final auth = await requireQtyPassword(context, actionLabel: 'Delete');
    if (!auth) return;
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
