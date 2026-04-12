import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/utils/order_display_utils.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/presentation/recent_sales/recent_sales_actions.dart';
import 'package:pos/presentation/recent_sales/recent_sales_cubit.dart';
import 'package:pos/presentation/widgets/auto_complete_textfield.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';
import 'package:pos/presentation/widgets/custom_sheet.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';
import 'package:pos/presentation/widgets/modern_bottom_sheet.dart' show filterPanelDecoration;
import 'package:pos/presentation/widgets/relative_time_text.dart';

class RecentSalesScreen extends StatelessWidget {
  const RecentSalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RecentSalesCubit(locator<OrderRepository>()),
      child: CustomScaffold(
        title: 'Recent Sales',
        body: BlocBuilder<RecentSalesCubit, RecentSalesState>(
          builder: (context, state) {
            if (state is RecentSalesLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is RecentSalesError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<RecentSalesCubit>().loadOrders(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is RecentSalesLoaded) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 768;
                  return Stack(
                    children: [
                      RefreshIndicator(
                        onRefresh: () => context.read<RecentSalesCubit>().refreshOrders(),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
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
                                        'No sales found',
                                        style: TextStyle(fontSize: 16, color: Colors.grey),
                                      ),
                                    ),
                                  )
                                else if (isMobile)
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
                                          child: RecentSaleCard(order: order),
                                        );
                                      }).toList(),
                                    );
                                  })
                                else
                                  _RecentSalesDesktopTable(orders: state.orders),
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
                            onPressed: () {
                              CustomSheet.show(
                                context: context,
                                maxChildSize: 0.92,
                                padding: EdgeInsets.zero,
                                child: Padding(
                                  padding: AppPadding.screenAll,
                                  child: const _FilterBar(),
                                ),
                              );
                            },
                            backgroundColor: AppColors.primaryColor,
                            tooltip: 'Filters',
                            child: const Icon(Icons.filter_list, color: Colors.white),
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
      ),
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
  final _orderTypeController = TextEditingController();
  final _paymentMethodController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _statusOptions = ['All', 'placed', 'completed', 'cancelled'];
  final List<String> _orderTypeOptions = ['All', 'Take Away', 'Dine In', 'Delivery'];
  final List<String> _paymentMethodOptions = ['All', 'Cash', 'Card', 'Credit', 'Online'];

  @override
  void dispose() {
    _invoiceController.dispose();
    _referenceController.dispose();
    _statusController.dispose();
    _orderTypeController.dispose();
    _paymentMethodController.dispose();
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
    final cubit = context.read<RecentSalesCubit>();
    cubit.filterOrders(
      invoiceNumber: _invoiceController.text.trim().isEmpty ? null : _invoiceController.text.trim(),
      referenceNumber: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
      status: _statusController.text.isEmpty || _statusController.text == 'All' ? null : _statusController.text,
      orderType: _orderTypeController.text.isEmpty || _orderTypeController.text == 'All' ? null : _orderTypeController.text,
      paymentMethod: _paymentMethodController.text.isEmpty || _paymentMethodController.text == 'All' ? null : _paymentMethodController.text,
      startDate: _startDate,
      endDate: _endDate,
    );
  }

  void _clearFilters() {
    setState(() {
      _invoiceController.clear();
      _referenceController.clear();
      _statusController.clear();
      _orderTypeController.clear();
      _paymentMethodController.clear();
      _startDate = null;
      _endDate = null;
    });
    context.read<RecentSalesCubit>().loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: filterPanelDecoration(),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 200,
            child: CustomTextField(
              controller: _invoiceController,
              labelText: 'Receipt No.',
            ),
          ),
          SizedBox(
            width: 200,
            child: CustomTextField(
              controller: _referenceController,
              labelText: 'Reference No.',
            ),
          ),
          SizedBox(
            width: 160,
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
            width: 160,
            child: AutoCompleteTextField<String>(
              defaultText: 'Order Type',
              displayStringFunction: (v) => v,
              items: _orderTypeOptions,
              onSelected: (v) {
                setState(() {
                  _orderTypeController.text = v;
                });
              },
              controller: _orderTypeController,
            ),
          ),
          SizedBox(
            width: 160,
            child: AutoCompleteTextField<String>(
              defaultText: 'Payment Method',
              displayStringFunction: (v) => v,
              items: _paymentMethodOptions,
              onSelected: (v) {
                setState(() {
                  _paymentMethodController.text = v;
                });
              },
              controller: _paymentMethodController,
            ),
          ),
          SizedBox(
            width: 180,
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
            width: 180,
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
            width: 120,
            onPressed: _applyFilters,
            text: 'Filter',
            elevation: 0,
          ),
          CustomButton(
            width: 120,
            onPressed: _clearFilters,
            text: 'Clear',
            backgroundColor: Colors.grey,
            elevation: 0,
          ),
        ],
      ),
    );
  }
}

/// Desktop / tablet: all channels in one sortable-style table with horizontal scroll on narrow widths.
class _RecentSalesDesktopTable extends StatelessWidget {
  const _RecentSalesDesktopTable({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTableTheme(
                data: DataTableThemeData(
                  headingRowColor: WidgetStateProperty.all(AppColors.primaryColor.withOpacity(0.08)),
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.primaryColor,
                  ),
                  dataTextStyle: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.textColor),
                ),
                child: DataTable(
                  columnSpacing: 20,
                  horizontalMargin: 16,
                  headingRowHeight: 48,
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 72,
                  columns: const [
                    DataColumn(label: Text('TYPE')),
                    DataColumn(label: Text('RECEIPT')),
                    DataColumn(label: Text('REFERENCE')),
                    DataColumn(label: Text('CUSTOMER')),
                    DataColumn(label: Text('DATE')),
                    DataColumn(label: Text('AMOUNT'), numeric: true),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('ACTIONS')),
                  ],
                  rows: orders.map((order) {
                    final total = order.finalAmount > 0 ? order.finalAmount : order.totalAmount;
                    final typeColor = orderTypeColor(order);
                    return DataRow(
                      cells: [
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(orderTypeIcon(order), size: 16, color: typeColor),
                                const SizedBox(width: 6),
                                Text(
                                  orderTypeShortLabel(order),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: typeColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(Text(order.invoiceNumber)),
                        DataCell(Text(order.referenceNumber?.isNotEmpty == true ? order.referenceNumber! : '—')),
                        DataCell(
                          Text(
                            order.customerName?.isNotEmpty == true
                                ? order.customerName!
                                : (order.customerPhone ?? '—'),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DataCell(
                          RelativeTimeText(
                            at: order.createdAt,
                            style: AppStyles.getRegularTextStyle(fontSize: 13),
                          ),
                        ),
                        DataCell(Text('₹ ${total.toStringAsFixed(2)}')),
                        DataCell(
                          Text(
                            order.status.toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: _statusColor(order.status),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 20),
                                color: AppColors.primaryColor,
                                tooltip: 'View',
                                onPressed: () => showRecentSaleOrderDetails(context, order),
                              ),
                              IconButton(
                                icon: const Icon(Icons.print_outlined, size: 20),
                                color: AppColors.primaryColor,
                                tooltip: 'Print',
                                onPressed: () => printRecentSaleBill(context, order),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                color: AppColors.primaryColor,
                                tooltip: 'Edit',
                                onPressed: () => openRecentSaleForEdit(
                                  context,
                                  order,
                                  onReturn: () => context.read<RecentSalesCubit>().refreshOrders(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green.shade700;
      case 'placed':
        return Colors.blue.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return AppColors.textColor;
    }
  }
}

class RecentSaleCard extends StatefulWidget {
  final Order order;
  const RecentSaleCard({super.key, required this.order});

  @override
  State<RecentSaleCard> createState() => _RecentSaleCardState();
}

class _RecentSaleCardState extends State<RecentSaleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final orderType = orderTypeUpperTag(order);

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
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(orderType),
              const SizedBox(height: 14),
              _infoRow(order),
              const SizedBox(height: 14),
              _netTotal(order),
              const SizedBox(height: 14),
              _actions(context, order),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String orderType) {
    final order = widget.order;

    return Row(
      children: [
        _tag(orderType),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Counter',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            RelativeTimeText(
              at: order.createdAt,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _tag(String orderType) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2F3A56),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(orderTypeIcon(widget.order), size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            orderType,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(Order order) {
    final key = orderTypeKey(order);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _infoBlock('Receipt No', order.invoiceNumber),
            const SizedBox(width: 24),
            if (key == 'delivery')
              _infoBlock('Partner', order.deliveryPartner ?? '—')
            else
              _infoBlock('Ref. / Table', order.referenceNumber ?? '—'),
          ],
        ),
        if (order.driverName != null && order.driverName!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _infoBlock('Driver', order.driverName!),
        ],
        if (order.customerName != null && order.customerName!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _infoBlock('Customer', order.customerName!),
        ],
        if (order.status.isNotEmpty) ...[
          const SizedBox(height: 8),
          _infoBlock('Status', order.status.toUpperCase()),
        ],
      ],
    );
  }

  Widget _infoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _netTotal(Order order) {
    final total = order.finalAmount > 0 ? order.finalAmount : order.totalAmount;

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

  Widget _actions(BuildContext context, Order order) {
    return Row(
      children: [
        _icon(
          Icons.remove_red_eye_outlined,
          tooltip: 'View',
          onTap: () => showRecentSaleOrderDetails(context, order),
        ),
        _icon(
          Icons.print_outlined,
          tooltip: 'Print',
          onTap: () => printRecentSaleBill(context, order),
        ),
        _icon(
          Icons.edit_outlined,
          tooltip: 'Edit',
          onTap: () => openRecentSaleForEdit(
                context,
                order,
                onReturn: () => context.read<RecentSalesCubit>().refreshOrders(),
              ),
        ),
      ],
    );
  }

  Widget _icon(
    IconData icon, {
    required String tooltip,
    Color bg = AppColors.primaryColor,
    VoidCallback? onTap,
  }) {
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
            decoration: BoxDecoration(
              color: onTap == null ? Colors.grey.shade300 : bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
