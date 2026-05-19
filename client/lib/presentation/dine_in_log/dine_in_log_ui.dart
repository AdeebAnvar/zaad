import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/app/routes.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/core/utils/order_log_cart_fallback.dart';
import 'package:pos/core/utils/order_owner_display_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';
import 'package:pos/presentation/dine_in_log/dine_in_log_cubit.dart';
import 'package:pos/presentation/dine_in_log/dine_in_move_table_sheet.dart';
import 'package:pos/presentation/dine_in_log/dine_in_reference_utils.dart';
import 'package:pos/presentation/dine_in_log/dine_in_split_merge_dialogs.dart';
import 'package:pos/presentation/widgets/app_snackbar.dart';
import 'package:pos/presentation/widgets/order_log_user_filter_autocomplete.dart';
import 'package:pos/presentation/widgets/app_standard_dialog.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';
import 'package:pos/presentation/widgets/custom_sheet.dart';
import 'package:pos/presentation/widgets/log_filter_shell.dart';
import 'package:pos/presentation/widgets/common_log_card.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';
import 'package:pos/presentation/widgets/move_order_dialog.dart';
import 'package:pos/presentation/widgets/order_log_details_dialog.dart';
import 'package:pos/presentation/sale/desktop/desktop_cart_panel.dart';
import 'package:pos/presentation/widgets/qty_password_guard.dart';

/// Optional KOT / staff reference only (not floor–table routing from hub metadata).
String _dineInLogReferenceLabel(Order order) {
  final raw = (order.referenceNumber ?? '').trim();
  if (raw.isEmpty) return '';
  return DineInRefParser.stripLeadingFloorId(raw);
}

class DineInLogScreen extends StatelessWidget {
  const DineInLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DineInLogCubit(
        locator<OrderRepository>(),
        locator<CartRepository>(),
        locator<LocalHubSettings>(),
        locator<CurrentCounterSession>(),
        hubOrdersLive: locator<HubOrdersLiveSync>(),
      ),
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
                                const spacing = 12.0;
                                const minCardWidth = 260.0;
                                final columns = ((width + spacing) / (minCardWidth + spacing)).floor().clamp(1, 8);
                                final cardWidth = (width - (columns - 1) * spacing) / columns;
                                return Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: state.orders
                                      .map((o) => SizedBox(
                                            width: cardWidth,
                                            child: DineInLogCard(
                                              key: ValueKey<int>(o.id),
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
  final _usersController = TextEditingController();
  int? _filterUserId;

  @override
  void dispose() {
    _invoiceController.dispose();
    _referenceController.dispose();
    _usersController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<DineInLogCubit>().filterOrders(
          invoiceNumber: _invoiceController.text.trim().isEmpty ? null : _invoiceController.text.trim(),
          referenceNumber: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
          userId: _filterUserId,
        );
  }

  void _clearFilters() {
    setState(() {
      _invoiceController.clear();
      _referenceController.clear();
      _usersController.clear();
      _filterUserId = null;
    });
    context.read<DineInLogCubit>().loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final m = LogFilterLayout(constraints.maxWidth);
        return LogFilterShell(
          title: 'Filters',
          subtitle: 'Receipt No, Reference No, and Users',
          icon: Icons.restaurant_outlined,
          body: Wrap(
            spacing: 8,
            runSpacing: 8,
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
                child: OrderLogUserFilterAutocomplete(
                  controller: _usersController,
                  onSelectedUserId: (id) {
                    setState(() => _filterUserId = id);
                    _applyFilters();
                  },
                ),
              ),
              SizedBox(
                width: 34,
                child: IconButton(
                  tooltip: 'Clear all',
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
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
  String? _orderUserName;

  @override
  void initState() {
    super.initState();
    _loadOrderUserName();
  }

  @override
  void didUpdateWidget(covariant DineInLogCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.order.id != oldWidget.order.id ||
        widget.order.userId != oldWidget.order.userId ||
        widget.order.hubMetadata != oldWidget.order.hubMetadata) {
      _loadOrderUserName();
    }
  }

  Future<void> _loadOrderUserName() async {
    final db = locator<AppDatabase>();
    final name = await resolveOrderOwnerDisplayName(
      db: db,
      order: widget.order,
      currentSessionUserId: () async => (await db.sessionDao.getActiveSession())?.userId,
    );
    if (!mounted) return;
    setState(() {
      _orderUserName = name;
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final canPay = locator<CurrentCounterSession>().access.canDineInPay;
    return CommonLogCard(
      tag: 'DI',
      amount: RuntimeAppSettings.money(order.totalAmount),
      invoiceNumber: order.invoiceNumber,
      referenceNumber: _dineInLogReferenceLabel(order),
      createdAt: order.createdAt,
      orderTakerName: _orderUserName,
      onDelete: () => _handleDelete(context, order),
      actions: [
        LogCardAction(
          icon: Icons.remove_red_eye_outlined,
          tooltip: 'View',
          onTap: () => _handleView(context, order),
        ),
        if (canPay)
          LogCardAction(
            icon: Icons.payments_outlined,
            tooltip: 'Pay',
            onTap: () => _handlePay(context, order),
          ),
        LogCardAction(
          icon: Icons.print_outlined,
          tooltip: 'Print',
          onTap: () => _handlePrint(context, order),
        ),
        LogCardAction(
          icon: Icons.edit_outlined,
          tooltip: 'Edit',
          onTap: () => _handleEdit(context, order),
        ),
        if (dineInBillIsSplittable(order) && widget.cartLineCount > 1)
          LogCardAction(
            icon: Icons.call_split,
            tooltip: 'Split',
            onTap: () => _handleSplit(context, order),
          ),
        if (dineInBillIsSplittable(order))
          LogCardAction(
            icon: Icons.merge_type,
            tooltip: 'Merge',
            onTap: () => _handleMerge(context, order),
          ),
        LogCardAction(
          icon: Icons.layers_outlined,
          tooltip: 'Floor',
          onTap: () => _handleMoveFloorTable(context, order),
        ),
        LogCardAction(
          icon: Icons.drive_file_move_outline,
          tooltip: 'Move',
          onTap: () => showMoveOrderDialog(
            context,
            order: order,
            sourceOrderType: 'dine_in',
            onSuccess: () => context.read<DineInLogCubit>().refreshOrders(),
          ),
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
    final ref = DineInRefParser.dineInRoutingAnchorForMatching(order)?.trim();
    if (ref == null || ref.isEmpty) {
      showAppMessageDialog(
        context,
        title: 'Merge bill',
        message: 'Table assignment is missing for this bill. Use Floor to assign a table, then try again.',
      );
      return;
    }
    final others = state.orders.where((o) {
      if (o.id == order.id) return false;
      if (DineInRefParser.dineInRoutingAnchorForMatching(o)?.trim() != ref) return false;
      return dineInBillIsSplittable(o);
    }).toList();
    showDineInMergeBillUi(context, order, others);
  }

  void _handleMoveFloorTable(BuildContext context, Order order) {
    showDineInMoveFloorTableUi(context, order);
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

  void _handlePay(BuildContext context, Order order) {
    showCartStylePaymentDialogForOrder(
      context,
      order: order,
      onPaymentRecorded: () => context.read<DineInLogCubit>().refreshOrders(),
    );
  }

  Future<void> _handlePrint(BuildContext context, Order order) async {
    final cartRepo = locator<CartRepository>();
    final printService = locator<PrintService>();
    final cartItems = await OrderLogCartFallback.resolve(
      order: order,
      db: locator<AppDatabase>(),
      cartRepo: cartRepo,
    );
    if (cartItems.isEmpty) {
      if (context.mounted) {
        showAppSnackBar(context, 'No items to print', isWarning: true);
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
    final reason = await requireQtyPasswordWithReason(
      context,
      actionLabel: 'Delete',
      reasonLabel: 'Reason for deleting',
    );
    if (reason == null || !context.mounted) return;
    final ok = await showAppConfirmDialog(
      context,
      title: 'Delete Order',
      message: 'Are you sure you want to delete order ${order.invoiceNumber}?\n\nReason: $reason',
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

    final itemsWithDetails = await OrderLogCartFallback.buildItemsWithDetailsForOrderLog(
      order: order,
      db: locator<AppDatabase>(),
      cartRepo: cartRepo,
      itemRepo: itemRepo,
    );
    if (itemsWithDetails.isEmpty) {
      if (!context.mounted) return;
      await showAppMessageDialog(
        context,
        title: 'Order Details',
        message: 'No items found in this order.',
      );
      return;
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
