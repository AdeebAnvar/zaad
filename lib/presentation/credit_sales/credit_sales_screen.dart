import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/presentation/credit_sales/credit_sales_cubit.dart';
import 'package:pos/presentation/credit_sales/pay_credit_bill_dialog.dart';
import 'package:pos/presentation/recent_sales/recent_sales_actions.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';
import 'package:pos/presentation/widgets/log_filter_shell.dart';
import 'package:pos/presentation/widgets/relative_time_text.dart';

class CreditSalesScreen extends StatelessWidget {
  const CreditSalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreditSalesCubit(locator<OrderRepository>()),
      child: const _CreditSalesView(),
    );
  }
}

class _CreditSalesView extends StatelessWidget {
  const _CreditSalesView();

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Credit Sales',
      appBarScreen: 'credit_sales',
      body: BlocBuilder<CreditSalesCubit, CreditSalesState>(
        builder: (context, state) {
          if (state is CreditSalesLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CreditSalesError) {
            return Center(
              child: Padding(
                padding: AppPadding.screenAll,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.read<CreditSalesCubit>().refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is CreditSalesLoaded) {
            return LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 768;
                return RefreshIndicator(
                  onRefresh: () => context.read<CreditSalesCubit>().refresh(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: AppPadding.screenAll,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FilterPanel(),
                          const SizedBox(height: 16),
                          if (state.filteredOrders.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 48),
                              child: Center(
                                child: Text(
                                  state.filterQuery.trim().isEmpty
                                      ? 'No credit sales found'
                                      : 'No matches for this customer filter',
                                  style: AppStyles.getRegularTextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ),
                            )
                          else if (isMobile)
                            _MobileCreditList(orders: state.filteredOrders)
                          else
                            _DesktopCreditTable(
                              orders: state.filteredOrders,
                              availableWidth: constraints.maxWidth,
                            ),
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

class _FilterPanel extends StatefulWidget {
  const _FilterPanel();

  @override
  State<_FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<_FilterPanel> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final q = context.read<CreditSalesCubit>().state;
    _controller = TextEditingController(
      text: q is CreditSalesLoaded ? q.filterQuery : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final m = LogFilterLayout(constraints.maxWidth);
        return LogFilterShell(
          title: 'Customer search',
          subtitle: 'Type to filter the list; balances update instantly',
          icon: Icons.person_search_outlined,
          body: SizedBox(
            width: m.fullWidth,
            child: CustomTextField(
              controller: _controller,
              labelText: 'Name or phone',
              onChanged: (v) => context.read<CreditSalesCubit>().setCustomerFilter(v),
            ),
          ),
          footer: m.stackActions
              ? OutlinedButton(
                  onPressed: () {
                    _controller.clear();
                    context.read<CreditSalesCubit>().setCustomerFilter('');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppColors.divider.withValues(alpha: 0.9)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Clear search', style: AppStyles.getMediumTextStyle(fontSize: 14)),
                )
              : Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () {
                      _controller.clear();
                      context.read<CreditSalesCubit>().setCustomerFilter('');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textColor,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      side: BorderSide(color: AppColors.divider.withValues(alpha: 0.9)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Clear search', style: AppStyles.getMediumTextStyle(fontSize: 14)),
                  ),
                ),
        );
      },
    );
  }
}

class _DesktopCreditTable extends StatelessWidget {
  const _DesktopCreditTable({
    required this.orders,
    required this.availableWidth,
  });

  final List<Order> orders;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy · HH:mm');
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.white,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: availableWidth),
            child: DataTableTheme(
              data: const DataTableThemeData(
                dataRowMinHeight: 52,
                dataRowMaxHeight: 72,
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(AppColors.primaryColor.withValues(alpha: 0.08)),
                columnSpacing: 20,
                horizontalMargin: 20,
                showCheckboxColumn: false,
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('CUSTOMER')),
                  DataColumn(label: Text('DEBIT'), numeric: true),
                  DataColumn(label: Text('CREDIT'), numeric: true),
                  DataColumn(label: Text('BALANCE'), numeric: true),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: List.generate(orders.length, (index) {
                  final order = orders[index];
                  final debit = order.finalAmount > 0 ? order.finalAmount : order.totalAmount;
                  final credit = paidAtSale(order);
                  final balance = order.creditAmount;
                  return DataRow(
                    cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(
                        _CustomerCell(order: order, dateFmt: dateFmt),
                      ),
                      DataCell(Text(RuntimeAppSettings.money(debit))),
                      DataCell(Text(RuntimeAppSettings.money(credit))),
                      DataCell(
                        Text(
                          RuntimeAppSettings.money(balance),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: balance > 0.01 ? const Color(0xFFC05621) : Colors.green.shade700,
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'View bill',
                              icon: const Icon(Icons.visibility_outlined, size: 22),
                              color: AppColors.primaryColor,
                              onPressed: () => showRecentSaleOrderDetails(context, order),
                            ),
                            IconButton(
                              tooltip: 'Pay credit',
                              icon: const Icon(Icons.payments_outlined, size: 22),
                              color: AppColors.primaryColor,
                              onPressed: () => showPayCreditBillDialog(
                                context,
                                order: order,
                                onPaymentRecorded: () {
                                  if (context.mounted) {
                                    context.read<CreditSalesCubit>().refresh();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerCell extends StatelessWidget {
  const _CustomerCell({required this.order, required this.dateFmt});

  final Order order;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final name = order.customerName?.trim();
    final phone = order.customerPhone?.trim();
    final line = <String>[];
    if (name != null && name.isNotEmpty) line.add(name);
    if (phone != null && phone.isNotEmpty) line.add(phone);
    final title = line.isEmpty ? '—' : line.join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppStyles.getSemiBoldTextStyle(fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          '${order.invoiceNumber} · ${dateFmt.format(order.createdAt)}',
          style: AppStyles.getRegularTextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _MobileCreditList extends StatelessWidget {
  const _MobileCreditList({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        return _CreditSaleCard(index: index + 1, order: order);
      },
    );
  }
}

class _CreditSaleCard extends StatelessWidget {
  const _CreditSaleCard({required this.index, required this.order});

  final int index;
  final Order order;

  @override
  Widget build(BuildContext context) {
    final debit = order.finalAmount > 0 ? order.finalAmount : order.totalAmount;
    final credit = paidAtSale(order);
    final balance = order.creditAmount;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryColor.withValues(alpha: 0.12),
                    child: Text(
                      '$index',
                      style: AppStyles.getSemiBoldTextStyle(fontSize: 13, color: AppColors.primaryColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerDisplayLine(order),
                          style: AppStyles.getSemiBoldTextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.invoiceNumber,
                          style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                        RelativeTimeText(
                          at: order.createdAt,
                          style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, c) {
                  final narrow = c.maxWidth < 360;
                  return Row(
                    children: [
                      _AmountChip(
                        label: 'Debit',
                        value: RuntimeAppSettings.money(debit),
                        valueColor: AppColors.textColor,
                        narrow: narrow,
                      ),
                      const SizedBox(width: 8),
                      _AmountChip(
                        label: 'Credit',
                        value: RuntimeAppSettings.money(credit),
                        valueColor: AppColors.textColor,
                        narrow: narrow,
                      ),
                      const SizedBox(width: 8),
                      _AmountChip(
                        label: 'Balance',
                        value: RuntimeAppSettings.money(balance),
                        valueColor: balance > 0.01 ? const Color(0xFFC05621) : Colors.green.shade700,
                        narrow: narrow,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => showRecentSaleOrderDetails(context, order),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('View'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryColor,
                        side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => showPayCreditBillDialog(
                        context,
                        order: order,
                        onPaymentRecorded: () {
                          if (context.mounted) {
                            context.read<CreditSalesCubit>().refresh();
                          }
                        },
                      ),
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: const Text('Pay'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  const _AmountChip({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.narrow,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: narrow ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppStyles.getMediumTextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppStyles.getSemiBoldTextStyle(fontSize: 13, color: valueColor),
            ),
          ],
        ),
      ),
    );
  }
}

double paidAtSale(Order o) => o.cashAmount + o.cardAmount + o.onlineAmount;

String customerDisplayLine(Order o) {
  final name = o.customerName?.trim();
  final phone = o.customerPhone?.trim();
  if (name != null && name.isNotEmpty && phone != null && phone.isNotEmpty) {
    return '$name · $phone';
  }
  if (name != null && name.isNotEmpty) return name;
  if (phone != null && phone.isNotEmpty) return phone;
  return 'Walk-in';
}
