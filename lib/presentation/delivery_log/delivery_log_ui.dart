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
import 'package:pos/presentation/driver_log/driver_log_screen.dart';
import 'package:pos/presentation/widgets/auto_complete_textfield.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';

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
                return RefreshIndicator(
                  onRefresh: () => context.read<DeliveryLogCubit>().refreshOrders(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: AppPadding.screenAll,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (!isMobile) const _DeliveryFilterBar(),
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
                              final columns = width >= 1200
                                  ? 3
                                  : width >= 700
                                      ? 2
                                      : 1;
                              const spacing = 16.0;
                              final cardWidth = (width - (columns - 1) * spacing) / columns;
                              final normalTab = state.selectedPartner?.toUpperCase() == 'NORMAL';
                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: state.orders
                                    .asMap()
                                    .entries
                                    .map((e) => SizedBox(
                                          width: cardWidth,
                                          child: _DeliveryCard(
                                            order: e.value,
                                            serialNo: e.key + 1,
                                            normalTab: normalTab,
                                            selected: state.normalSelection.contains(e.value.id),
                                          ),
                                        ))
                                    .toList(),
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
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => BlocProvider.value(
            value: deliveryLogCubit,
            child: DraggableScrollableSheet(
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
                        ],
                      ),
                    ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select one or more orders (checkbox).')),
      );
      return;
    }
    if (_driverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a driver.')),
      );
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign driver'),
        content: Text(
          'Assign $driverName to ${widget.selection.length} order(s) and set status to Assigned?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryColor, foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final err = await context.read<DeliveryLogCubit>().assignDriverToOrders(
          widget.selection.toList(),
          driver.id,
          driverName,
        );
    if (!context.mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Driver assigned to ${widget.selection.length} order(s).')),
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
              items: widget.drivers
                  .map((d) => DropdownMenuItem<int>(value: d.id, child: Text(d.name)))
                  .toList(),
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
            width: 220,
            child: AutoCompleteTextField<CustomerModel>(
              defaultText: 'SELECT',
              labelText: 'Customer',
              displayStringFunction: (c) => c.phone != null && c.phone!.isNotEmpty ? '${c.name} - ${c.phone}' : c.name,
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
  final bool normalTab;
  final bool selected;

  const _DeliveryCard({
    required this.order,
    required this.serialNo,
    this.normalTab = false,
    this.selected = false,
  });

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
        widget.order.driverId != oldWidget.order.driverId ||
        widget.order.driverName != oldWidget.order.driverName ||
        widget.order.cashAmount != oldWidget.order.cashAmount ||
        widget.order.cardAmount != oldWidget.order.cardAmount ||
        widget.order.creditAmount != oldWidget.order.creditAmount ||
        widget.order.onlineAmount != oldWidget.order.onlineAmount) {
      _status = widget.order.status;
      _paymentType = _getPaymentType(widget.order);
    }
  }

  bool _isPartnerDeliveryOrder(Order o) {
    final p = o.deliveryPartner?.trim().toUpperCase();
    if (p == null || p.isEmpty) return false;
    return p != 'NORMAL';
  }

  String _getPaymentType(Order o) {
    if (o.creditAmount > 0) return 'CREDIT';
    if (o.onlineAmount > 0) return 'ONLINE';
    if (o.cashAmount > 0) return 'CASH';
    if (o.cardAmount > 0) return 'CARD';
    return _isPartnerDeliveryOrder(o) ? 'ONLINE' : 'CREDIT';
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
    final isNormal = widget.order.deliveryPartner?.toUpperCase() == 'NORMAL';

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
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.normalTab)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Checkbox(
                        value: widget.selected,
                        onChanged: (_) =>
                            context.read<DeliveryLogCubit>().toggleNormalSelection(widget.order.id),
                      ),
                    ),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2F3A56),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_shipping, size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text('DELIVERY - ${partnerLabel.toUpperCase()}',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          formattedDate,
                          style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.hintFontColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 1,
                color: AppColors.divider.withOpacity(0.7),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 20,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: 220,
                    child: _infoRow('S.No', '${widget.serialNo}'),
                  ),
                  SizedBox(
                    width: 220,
                    child: _infoRow('Receipt No', order.invoiceNumber),
                  ),
                  SizedBox(
                    width: 220,
                    child: _infoRow('Order Number', order.referenceNumber ?? '-'),
                  ),
                  SizedBox(
                    width: 220,
                    child: _infoRow('Customer', order.customerPhone ?? order.customerName ?? '-'),
                  ),
                  if (isNormal)
                    SizedBox(
                      width: 220,
                      child: _infoRow(
                        'Assigned driver',
                        (order.driverName != null && order.driverName!.trim().isNotEmpty)
                            ? order.driverName!
                            : '—',
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _statusDropdown()),
                  const SizedBox(width: 12),
                  Expanded(child: _paymentTypeDropdown()),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
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
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Move - Coming soon')),
                      );
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
        Text(label, style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.hintFontColor)),
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

  bool _hasDriverAssigned(Order o) =>
      o.driverId != null && (o.driverName?.trim().isNotEmpty ?? false);

  List<(String, String)> _normalStatusOptionsFor(Order o) {
    final hasDriver = _hasDriverAssigned(o);
    final st = o.status.toLowerCase();
    const all = _normalStatusOptions;
    if (!hasDriver) {
      return all.where((e) => e.$2 == 'pending' || e.$2 == 'cancelled').toList();
    }
    if (st == 'assigned' || st == 'delivered' || st == 'completed') {
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
        const Text('Status', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          key: ValueKey<String>('status_${widget.order.id}_$_statusDropdownRevision'),
          isExpanded: true,
          value: validDisplay,
          style: AppStyles.getRegularTextStyle(fontSize: 14).copyWith(fontWeight: FontWeight.w500),
          iconEnabledColor: AppColors.textColor,
          dropdownColor: Colors.white,
          decoration: CustomFormFieldDecoration.dropdownDecoration(context),
          items: options.map((e) => DropdownMenuItem(value: e.$1, child: Text(e.$1, style: AppStyles.getRegularTextStyle(fontSize: 14).copyWith(fontWeight: FontWeight.w500)))).toList(),
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
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
              setState(() => _statusDropdownRevision++);
            }
          },
        ),
      ],
    );
  }

  static const _paymentOptionsPartner = ['ONLINE', 'CASH', 'CARD', 'CREDIT'];
  static const _paymentOptionsNormal = ['CREDIT', 'CASH', 'CARD'];

  Widget _paymentTypeDropdown() {
    final partner = _isPartnerDeliveryOrder(widget.order);
    final options = partner ? _paymentOptionsPartner : _paymentOptionsNormal;
    final validDisplay = options.contains(_paymentType) ? _paymentType : options.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Payment Type', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          key: ValueKey<String>('pay_${widget.order.id}_$_paymentDropdownRevision'),
          isExpanded: true,
          value: validDisplay,
          style: AppStyles.getRegularTextStyle(fontSize: 14).copyWith(fontWeight: FontWeight.w500),
          iconEnabledColor: AppColors.textColor,
          dropdownColor: Colors.white,
          decoration: CustomFormFieldDecoration.dropdownDecoration(context),
          items: options.map((s) => DropdownMenuItem(value: s, child: Text(s, style: AppStyles.getRegularTextStyle(fontSize: 14).copyWith(fontWeight: FontWeight.w500)))).toList(),
          onChanged: (v) async {
            if (v == null) return;
            if (v == validDisplay) return;
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
          color: danger ? Colors.red.withOpacity(0.35) : AppColors.primaryColor.withOpacity(0.25),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
