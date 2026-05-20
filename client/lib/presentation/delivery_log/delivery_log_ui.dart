import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
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
import 'package:pos/presentation/delivery_log/delivery_log_cubit.dart';
import 'package:pos/presentation/driver_log/driver_log_screen.dart';
import 'package:pos/presentation/widgets/app_standard_dialog.dart';
import 'package:pos/presentation/widgets/order_log_user_filter_autocomplete.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_loading.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';
import 'package:pos/presentation/widgets/custom_sheet.dart';
import 'package:pos/presentation/widgets/common_log_card.dart';
import 'package:pos/presentation/widgets/log_filter_shell.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';
import 'package:pos/presentation/widgets/move_order_dialog.dart';
import 'package:pos/presentation/sale/desktop/desktop_cart_panel.dart';
import 'package:pos/presentation/widgets/qty_password_guard.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';

class DeliveryLogScreen extends StatelessWidget {
  const DeliveryLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Delivery Sale Log',
      appBarScreen: 'delivery_log',
      floatingActionButton: _MobileDeliveryFilterFab(),
      body: BlocBuilder<DeliveryLogCubit, DeliveryLogState>(
        builder: (context, state) {
          if (state is DeliveryLogLoading) {
            return const Center(child: CustomLoading());
          }
          if (state is DeliveryLogError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${state.message}',
                    style: AppStyles.getRegularTextStyle(fontSize: 15, color: AppColors.textColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    width: 120,
                    onPressed: () => context.read<DeliveryLogCubit>().loadOrders(),
                    text: 'Retry',
                  ),
                ],
              ),
            );
          }
          if (state is DeliveryLogLoaded) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 768;
                return RefreshIndicator(
                  onRefresh: () => context.read<DeliveryLogCubit>().refreshOrders(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: AppPadding.screenAll,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LayoutBuilder(
                            builder: (context, topBarConstraints) {
                              final stackTopBar = !isMobile && topBarConstraints.maxWidth < 1100;
                              final driverLogButton = CustomButton(
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
                              );

                              if (isMobile) {
                                return Align(
                                  alignment: Alignment.centerRight,
                                  child: driverLogButton,
                                );
                              }

                              if (stackTopBar) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const _DeliveryFilterBar(),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: driverLogButton,
                                    ),
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Expanded(child: _DeliveryFilterBar()),
                                  const SizedBox(width: 12),
                                  driverLogButton,
                                ],
                              );
                            },
                          ),
                          _PartnerTabs(
                            selectedPartner: state.selectedPartner,
                            deliveryPartners: state.deliveryPartners,
                            onSelect: (p) => context.read<DeliveryLogCubit>().selectPartnerTab(p),
                          ),
                          if (state.selectedPartner?.toUpperCase() == 'NORMAL' && state.orders.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _NormalDriverAssignBar(
                                drivers: state.drivers,
                                selection: state.normalSelection,
                              ),
                            ),
                          if (state.orders.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Text(
                                  'No pending delivery orders',
                                  style: AppStyles.getRegularTextStyle(fontSize: 16, color: AppColors.hintFontColor),
                                ),
                              ),
                            )
                          else
                            LayoutBuilder(builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              const spacing = 12.0;
                              const minCardWidth = 260.0;
                              final columns = ((width + spacing) / (minCardWidth + spacing)).floor().clamp(1, 8);
                              final cardWidth = (width - (columns - 1) * spacing) / columns;
                              final normalTab = state.selectedPartner?.toUpperCase() == 'NORMAL';
                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: state.orders.asMap().entries.map((e) {
                                  final o = e.value;
                                  final isNormalOrder = o.deliveryPartner?.trim().toUpperCase() == 'NORMAL';
                                  return SizedBox(
                                    width: cardWidth,
                                    child: _DeliveryCard(
                                      key: ValueKey<int>(o.id),
                                      order: o,
                                      serialNo: e.key + 1,
                                      showNormalBulkCheckbox: normalTab && isNormalOrder,
                                      selected: state.normalSelection.contains(o.id),
                                    ),
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

class _MobileDeliveryFilterFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final state = context.watch<DeliveryLogCubit>().state;
    if (!isMobile || state is! DeliveryLogLoaded) {
      return const SizedBox.shrink();
    }
    return FloatingActionButton(
      onPressed: () {
        final deliveryLogCubit = context.read<DeliveryLogCubit>();
        CustomSheet.show(
          context: context,
          maxChildSize: 0.9,
          padding: EdgeInsets.zero,
          child: BlocProvider.value(
            value: deliveryLogCubit,
            child: Padding(
              padding: AppPadding.screenAll,
              child: BlocBuilder<DeliveryLogCubit, DeliveryLogState>(
                builder: (context, sheetState) {
                  return const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DeliveryFilterBar(),
                    ],
                  );
                },
              ),
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

/// Bulk assign driver for Normal tab (multi-select orders).
class _NormalDriverAssignBar extends StatefulWidget {
  const _NormalDriverAssignBar({
    required this.drivers,
    required this.selection,
  });

  final List<Driver> drivers;
  final Set<int> selection;

  @override
  State<_NormalDriverAssignBar> createState() => _NormalDriverAssignBarState();
}

class _NormalDriverAssignBarState extends State<_NormalDriverAssignBar> {
  int? _driverId;

  Future<void> _confirmAndAssign(BuildContext context) async {
    if (widget.selection.isEmpty) {
      CustomSnackBar.showWarning(message: 'Select one or more orders (checkbox).');
      return;
    }
    if (_driverId == null) {
      CustomSnackBar.showWarning(message: 'Choose a driver.');
      return;
    }
    Driver? driver;
    for (final d in widget.drivers) {
      if (d.id == _driverId) {
        driver = d;
        break;
      }
    }
    if (driver == null) return;
    final driverName = driver.name;
    final ok = await showAppConfirmDialog(
      context,
      title: 'Assign driver',
      message: 'Assign $driverName to ${widget.selection.length} order(s) and set status to Out for delivery?',
      confirmText: 'Confirm',
    );
    if (ok != true || !context.mounted) return;
    final err = await context.read<DeliveryLogCubit>().assignDriverToOrders(
          widget.selection.toList(),
          driver.id,
          driverName,
        );
    if (!context.mounted) return;
    if (err != null) {
      CustomSnackBar.showError(message: err);
    } else {
      CustomSnackBar.showSuccess(
        message: 'Driver assigned to ${widget.selection.length} order(s).',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppPadding.card,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider, width: 1.5),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Text(
            'Normal delivery — assign driver (${widget.selection.length} selected)',
            style: AppStyles.getSemiBoldTextStyle(fontSize: 13),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<int>(
              value: _driverId,
              decoration: CustomFormFieldDecoration.dropdownDecoration(context),
              hint: Text('Choose driver', style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.hintFontColor)),
              items: widget.drivers.map((d) => DropdownMenuItem<int>(value: d.id, child: Text(d.name))).toList(),
              onChanged: (v) => setState(() => _driverId = v),
            ),
          ),
          CustomButton(
            width: 140,
            text: 'Assign driver',
            onPressed: () => _confirmAndAssign(context),
          ),
        ],
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
  final _usersController = TextEditingController();
  int? _filterUserId;

  Future<void> _applyFiltersInner() async {
    final c = context.read<DeliveryLogCubit>();
    await c.filterOrders(
      invoiceNumber: _invoiceController.text.trim().isEmpty ? null : _invoiceController.text.trim(),
      referenceNumber: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
      userId: _filterUserId,
    );
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    _referenceController.dispose();
    _usersController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    unawaited(_applyFiltersInner());
  }

  void _clearFilters() {
    setState(() {
      _invoiceController.clear();
      _referenceController.clear();
      _usersController.clear();
      _filterUserId = null;
    });
    final c = context.read<DeliveryLogCubit>();
    unawaited(c.loadOrders());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final m = LogFilterLayout(constraints.maxWidth);
        return LogFilterShell(
          title: 'Filters',
          subtitle: 'Pending delivery only (placed / pending / KOT). Dispatched & closed orders use Driver Log or order history.',
          icon: Icons.local_shipping_outlined,
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
                  allUsersLabel: 'All users',
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
                      style: AppStyles.getSemiBoldTextStyle(
                        fontSize: 13,
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

  /// Bulk driver assign (Normal tab only); only for orders with partner NORMAL.
  final bool showNormalBulkCheckbox;
  final bool selected;

  const _DeliveryCard({
    super.key,
    required this.order,
    required this.serialNo,
    this.showNormalBulkCheckbox = false,
    this.selected = false,
  });

  @override
  State<_DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends State<_DeliveryCard> {
  String _status = '';
  String? _orderUserName;

  /// Bumps when user cancels confirmation so the dropdown rebuilds and shows the previous value.
  int _statusDropdownRevision = 0;

  @override
  void initState() {
    super.initState();
    _status = widget.order.status;
    _loadOrderUserName();
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
  void didUpdateWidget(covariant _DeliveryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.order.id != oldWidget.order.id) {
      _status = widget.order.status;
      _loadOrderUserName();
      return;
    }
    if (widget.order.userId != oldWidget.order.userId ||
        widget.order.hubMetadata != oldWidget.order.hubMetadata) {
      _loadOrderUserName();
    }
    // Same row: sync when parent list refreshes after a successful save (or external update).
    if (widget.order.status != oldWidget.order.status ||
        widget.order.driverId != oldWidget.order.driverId ||
        widget.order.driverName != oldWidget.order.driverName) {
      _status = widget.order.status;
    }
  }

  Future<bool> _showUpdateConfirmation({
    required String title,
    required String message,
  }) async {
    final confirmed = await showAppConfirmDialog(context, title: title, message: message);
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final partnerLabel = order.deliveryPartner ?? 'Normal';
    final isNormal = widget.order.deliveryPartner?.toUpperCase() == 'NORMAL';

    return CommonLogCard(
      tag: 'DL',
      amount: RuntimeAppSettings.money(order.finalAmount > 0 ? order.finalAmount : order.totalAmount),
      invoiceNumber: order.invoiceNumber,
      referenceNumber: order.referenceNumber ?? '',
      createdAt: order.createdAt,
      orderTakerName: _orderUserName,
      pickupToken: order.pickupToken,
      leadingHeader: widget.showNormalBulkCheckbox
          ? Checkbox(
              value: widget.selected,
              onChanged: (_) => context.read<DeliveryLogCubit>().toggleNormalSelection(widget.order.id),
            )
          : null,
      onDelete: () => _handleDelete(context, order),
      extraContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _metaRow('Partner', partnerLabel.toUpperCase()),
          if (isNormal)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: _metaRow(
                'Driver',
                (order.driverName != null && order.driverName!.trim().isNotEmpty) ? order.driverName! : '—',
              ),
            ),
          const SizedBox(height: 6),
          _statusDropdown(),
        ],
      ),
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
        LogCardAction(
          icon: Icons.payments_outlined,
          tooltip: 'Pay',
          onTap: () => _handlePay(context, order),
        ),
        LogCardAction(
          icon: Icons.drive_file_move_outline,
          tooltip: 'Move',
          onTap: () => showMoveOrderDialog(
            context,
            order: order,
            sourceOrderType: 'delivery',
            onSuccess: () => context.read<DeliveryLogCubit>().refreshOrders(),
          ),
        ),
      ],
    );
  }

  Widget _metaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            '$label:',
            style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.hintFontColor),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.hintFontColor),
          ),
        ),
      ],
    );
  }

  // DB status -> Display (for showing current value)
  static const _dbToDisplay = {
    'placed': 'Pending',
    'pending': 'Pending',
    'kot': 'Pending',
    'out_of_delivery': 'Out for delivery',
    'dispatched': 'Out for delivery',
    'assigned': 'Out for delivery',
    'delivered': 'Delivered',
    'completed': 'Delivered',
    'cancelled': 'Cancelled',
  };

  // Partner (aggregator): Dispatched hides row from log; still mapped for legacy rows / sync.
  static const _partnerStatusOptions = [
    ('Pending', 'pending'),
    ('Out for delivery', 'dispatched'),
    ('Delivered', 'completed'),
    ('Cancelled', 'cancelled'),
  ];

  // NORMAL fleet: Delivered persists as completed (bill closed).
  static const _normalStatusOptions = [
    ('Pending', 'pending'),
    ('Out for delivery', 'out_of_delivery'),
    ('Delivered', 'completed'),
    ('Cancelled', 'cancelled'),
  ];

  bool _hasDriverAssigned(Order o) => o.driverId != null && (o.driverName?.trim().isNotEmpty ?? false);

  List<(String, String)> _normalStatusOptionsFor(Order o) {
    final hasDriver = _hasDriverAssigned(o);
    final st = o.status.toLowerCase();
    const all = _normalStatusOptions;
    if (!hasDriver) {
      return all
          .where((e) => e.$2 == 'pending' || e.$2 == 'cancelled' || e.$2 == 'completed')
          .toList();
    }
    if (st == 'assigned' ||
        st == 'out_of_delivery' ||
        st == 'dispatched' ||
        st == 'delivered' ||
        st == 'completed') {
      return all.where((e) => e.$2 != 'pending').toList();
    }
    return all;
  }

  Widget _statusDropdown() {
    final isNormal = widget.order.deliveryPartner?.toUpperCase() == 'NORMAL';
    final options = isNormal ? _normalStatusOptionsFor(widget.order) : _partnerStatusOptions;

    final dbStatus = _status.isEmpty ? 'pending' : _status;
    final displayStatus = _dbToDisplay[dbStatus] ?? 'Pending';
    final validDisplay = options.any((e) => e.$1 == displayStatus) ? displayStatus : options.first.$1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Status', style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.hintFontColor)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          key: ValueKey<String>('status_${widget.order.id}_$_statusDropdownRevision'),
          isExpanded: true,
          value: validDisplay,
          style: AppStyles.getRegularTextStyle(fontSize: 14).copyWith(fontWeight: FontWeight.w500),
          iconEnabledColor: AppColors.textColor,
          dropdownColor: Colors.white,
          decoration: CustomFormFieldDecoration.dropdownDecoration(context),
          items: options
              .map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$1, style: AppStyles.getRegularTextStyle(fontSize: 14).copyWith(fontWeight: FontWeight.w500))))
              .toList(),
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
            final err = await context.read<DeliveryLogCubit>().updateOrderStatus(widget.order.id, newStatus);
            if (!mounted) return;
            if (err != null) {
              CustomSnackBar.showError(message: err);
              setState(() => _statusDropdownRevision++);
            }
          },
        ),
      ],
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

  void _handlePay(BuildContext context, Order order) {
    showCartStylePaymentDialogForOrder(
      context,
      order: order,
      fromDeliveryLog: true,
      onPaymentRecorded: () => context.read<DeliveryLogCubit>().refreshOrders(),
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
      if (context.mounted) CustomSnackBar.showWarning(message: 'No items to print');
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
          CustomSnackBar.showSuccess(message: 'Bill sent to printer');
        } else {
          showPrintFailedDialog(context, printFailed);
        }
      }
    } catch (e) {
      if (context.mounted) showErrorDialog(context, e);
    }
  }

  Future<void> _handleDelete(BuildContext context, Order order) async {
    final reason = await requireQtyPasswordWithReason(
      context,
      actionLabel: 'Delete',
      reasonLabel: 'Reason for deleting',
    );
    if (reason == null) return;
    final ok = await showAppConfirmDialog(
      context,
      title: 'Delete Order',
      message: 'Are you sure you want to delete order ${order.invoiceNumber}?\n\nReason: $reason',
      confirmText: 'Delete',
      confirmBackgroundColor: Colors.red,
    );
    if (ok == true && context.mounted) {
      await context.read<DeliveryLogCubit>().deleteOrder(order.id);
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
      await showAppMessageDialog(
        context,
        title: 'Order ${order.invoiceNumber}',
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (order.deliveryPartner != null)
                Text(
                  'Partner: ${order.deliveryPartner}',
                  style: AppStyles.getSemiBoldTextStyle(fontSize: 14),
                ),
              const SizedBox(height: 12),
              ...itemsWithDetails.map((m) {
                final item = m['item'] as Item?;
                final cartItem = m['cartItem'] as CartItem;
                final catalog = (item?.name ?? '').trim();
                final snap = cartItem.itemName.trim();
                final lineLabel = catalog.isNotEmpty ? catalog : (snap.isNotEmpty ? snap : 'Item');
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '$lineLabel x${cartItem.quantity} - ${RuntimeAppSettings.money(cartItem.total)}',
                    style: AppStyles.getRegularTextStyle(fontSize: 14),
                  ),
                );
              }),
            ],
          ),
        ),
        okText: 'Close',
      );
    }
  }
}
