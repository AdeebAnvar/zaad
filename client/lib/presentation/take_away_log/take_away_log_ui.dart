import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/core/utils/order_log_cart_fallback.dart';
import 'package:pos/core/utils/order_owner_display_utils.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/presentation/take_away_log/take_away_log_cubit.dart';
import 'package:pos/presentation/widgets/order_log_user_filter_autocomplete.dart';
import 'package:pos/presentation/widgets/app_snackbar.dart';
import 'package:pos/presentation/widgets/app_standard_dialog.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';
import 'package:pos/presentation/widgets/custom_sheet.dart';
import 'package:pos/presentation/widgets/log_filter_shell.dart';
import 'package:pos/presentation/widgets/common_log_card.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';
import 'package:pos/presentation/widgets/order_log_details_dialog.dart';
import 'package:pos/presentation/sale/desktop/desktop_cart_panel.dart';
import 'package:pos/presentation/widgets/qty_password_guard.dart';

class TakeAwayLogScreen extends StatelessWidget {
  const TakeAwayLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
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

                                const spacing = 12.0;
                                const minCardWidth = 220.0;
                                final columns = ((width + spacing) / (minCardWidth + spacing)).floor().clamp(1, 8);
                                final cardWidth = (width - (columns - 1) * spacing) / columns;

                                return Wrap(
                                  spacing: spacing,
                                  runSpacing: spacing,
                                  children: state.orders.map((order) {
                                    return SizedBox(
                                      width: cardWidth,
                                      child: TakeAwayCard(key: ValueKey<int>(order.id), order: order),
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
  int? _filterUserId;

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

class TakeAwayCard extends StatefulWidget {
  final Order order;
  const TakeAwayCard({super.key, required this.order});

  @override
  State<TakeAwayCard> createState() => _TakeAwayCardState();
}

class _TakeAwayCardState extends State<TakeAwayCard> {
  String? _orderUserName;

  @override
  void initState() {
    super.initState();
    _loadOrderUserName();
  }

  @override
  void didUpdateWidget(covariant TakeAwayCard oldWidget) {
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
    final access = locator<CurrentCounterSession>().access;
    final canDelete = access.canTakeAwayLogDelete;
    final canPay = access.canTakeAwayPay;
    return CommonLogCard(
      tag: 'TA',
      amount: RuntimeAppSettings.money(order.totalAmount),
      invoiceNumber: order.invoiceNumber,
      referenceNumber: order.referenceNumber ?? '',
      createdAt: order.createdAt,
      orderTakerName: _orderUserName,
      onDelete: canDelete ? () => _handleDelete(context, order) : null,
      actions: [
        LogCardAction(
          icon: Icons.remove_red_eye_outlined,
          tooltip: 'View',
          onTap: () => _handleView(context, order),
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
        if (canPay)
          LogCardAction(
            icon: Icons.payments_outlined,
            tooltip: 'Pay',
            onTap: () => _handlePay(context, order),
          ),
      ],
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
    final cartItems = await OrderLogCartFallback.resolve(
      order: order,
      db: locator<AppDatabase>(),
      cartRepo: cartRepo,
    );
    if (cartItems.isEmpty) {
      if (context.mounted) showAppSnackBar(context, 'No items to print', isWarning: true);
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
      await context.read<TakeAwayLogCubit>().deleteOrder(order.id);
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
