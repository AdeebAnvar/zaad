import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos/app/di.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/app/routes.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/utils/order_display_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/customer_repository.dart';
import 'package:pos/domain/models/customer_model.dart';
import 'package:pos/presentation/crm/crm_cubit.dart';
import 'package:pos/presentation/recent_sales/recent_sales_actions.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';

class CrmCustomerDetailsScreen extends StatefulWidget {
  const CrmCustomerDetailsScreen({super.key});
  static const String route = '/crm/customer_details';

  @override
  State<CrmCustomerDetailsScreen> createState() => _CrmCustomerDetailsScreenState();
}

class _CrmCustomerDetailsScreenState extends State<CrmCustomerDetailsScreen> {
  CustomerModel? customer;
  List<Order> orders = [];
  bool loading = true;
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _hasLoaded = true;
      _loadCustomerDetails();
    }
  }

  Future<void> _loadCustomerDetails() async {
    setState(() => loading = true);

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final customerId = args?['customerId'] as int?;

    if (customerId == null) {
      setState(() => loading = false);
      return;
    }

    try {
      final customerRepo = locator<CustomerRepository>();
      final db = locator<AppDatabase>();
      final cubit = CrmCubit(customerRepo, db);

      customer = await customerRepo.getCustomerById(customerId);
      if (customer != null) {
        orders = await cubit.getCustomerOrders(customerId);
      }
    } catch (e) {
      // ignore; UI shows empty
    }

    if (mounted) setState(() => loading = false);
  }

  Map<String, int> _countsByChannel() {
    var ta = 0, di = 0, de = 0;
    for (final o in orders) {
      switch (orderTypeKey(o)) {
        case 'dine_in':
          di++;
          break;
        case 'delivery':
          de++;
          break;
        default:
          ta++;
      }
    }
    return {'take_away': ta, 'dine_in': di, 'delivery': de};
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return CustomScaffold(
        title: 'Customer',
        onBack: () => Navigator.of(context).pop(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (customer == null) {
      return CustomScaffold(
        title: 'Customer',
        onBack: () => Navigator.of(context).pop(),
        body: const Center(child: Text('Customer not found')),
      );
    }

    final c = customer!;
    final totalSpent = orders.fold<double>(0.0, (sum, o) => sum + o.finalAmount);
    final counts = _countsByChannel();

    return CustomScaffold(
      title: 'Customer profile',
      onBack: () => Navigator.of(context).pop(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 768;
          final maxContent = constraints.maxWidth > 1200 ? 1100.0 : constraints.maxWidth;
          return RefreshIndicator(
            onRefresh: _loadCustomerDetails,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 16 : 24,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContent),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileHeader(customer: c, totalSpent: totalSpent, orderCount: orders.length),
                      const SizedBox(height: 20),
                      _ChannelStatsChips(counts: counts),
                      const SizedBox(height: 24),
                      Text(
                        'All orders (${orders.length})',
                        style: AppStyles.getMediumTextStyle(
                          fontSize: 16,
                          color: AppColors.textColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (orders.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'No linked orders yet. Orders appear when receipt customer matches this profile.',
                            textAlign: TextAlign.center,
                            style: AppStyles.getRegularTextStyle(fontSize: 14, color: Colors.grey.shade600),
                          ),
                        )
                      else if (isNarrow)
                        _OrdersCardList(
                          orders: orders,
                          onAfterEdit: _loadCustomerDetails,
                        )
                      else
                        _OrdersDataTable(
                          orders: orders,
                          onAfterEdit: _loadCustomerDetails,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.customer,
    required this.totalSpent,
    required this.orderCount,
  });

  final CustomerModel customer;
  final double totalSpent;
  final int orderCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withOpacity(0.12),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.primaryColor,
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: AppStyles.getMediumTextStyle(fontSize: 22, color: AppColors.textColor),
                    ),
                    if (customer.phone != null && customer.phone!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 18, color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                customer.phone!,
                                style: AppStyles.getRegularTextStyle(fontSize: 15, color: Colors.grey.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (customer.email != null && customer.email!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(Icons.email_outlined, size: 18, color: Colors.grey.shade700),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                customer.email!,
                                style: AppStyles.getRegularTextStyle(fontSize: 14, color: Colors.grey.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.home_outlined),
                onPressed: () => AppNavigator.pushReplacementNamed(Routes.dashboard),
                tooltip: 'Dashboard',
              ),
            ],
          ),
          if (customer.gender != null && customer.gender!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Chip(
              label: Text(customer.gender!),
              visualDensity: VisualDensity.compact,
              backgroundColor: Colors.white,
            ),
          ],
          if (customer.createdAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Customer since ${DateFormat('MMM d, yyyy').format(customer.createdAt!)}',
              style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _StatPill(
                icon: Icons.receipt_long_outlined,
                label: 'Total orders',
                value: '$orderCount',
              ),
              _StatPill(
                icon: Icons.currency_rupee,
                label: 'Lifetime value',
                value: '₹${totalSpent.toStringAsFixed(2)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: AppColors.primaryColor),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChannelStatsChips extends StatelessWidget {
  const _ChannelStatsChips({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Purchases by channel',
          style: AppStyles.getMediumTextStyle(fontSize: 14, color: AppColors.hintFontColor),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _ChannelChip(
              label: 'Take away',
              count: counts['take_away'] ?? 0,
              color: const Color(0xFF1565C0),
              icon: Icons.shopping_bag_outlined,
            ),
            _ChannelChip(
              label: 'Dine in',
              count: counts['dine_in'] ?? 0,
              color: const Color(0xFF7C4DFF),
              icon: Icons.restaurant_outlined,
            ),
            _ChannelChip(
              label: 'Delivery',
              count: counts['delivery'] ?? 0,
              color: const Color(0xFF00897B),
              icon: Icons.local_shipping_outlined,
            ),
          ],
        ),
      ],
    );
  }
}

class _ChannelChip extends StatelessWidget {
  const _ChannelChip({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            '$label · ',
            style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 13),
          ),
          Text(
            '$count',
            style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _OrdersDataTable extends StatelessWidget {
  const _OrdersDataTable({
    required this.orders,
    required this.onAfterEdit,
  });

  final List<Order> orders;
  final Future<void> Function() onAfterEdit;

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
                color: Colors.black.withOpacity(0.05),
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
                    fontSize: 12,
                    color: AppColors.primaryColor,
                  ),
                ),
                child: DataTable(
                  columnSpacing: 16,
                  horizontalMargin: 12,
                  columns: const [
                    DataColumn(label: Text('TYPE')),
                    DataColumn(label: Text('RECEIPT')),
                    DataColumn(label: Text('REFERENCE')),
                    DataColumn(label: Text('DATE')),
                    DataColumn(label: Text('AMOUNT'), numeric: true),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('')),
                  ],
                  rows: orders.map((order) {
                    final total = order.finalAmount > 0 ? order.finalAmount : order.totalAmount;
                    final tc = orderTypeColor(order);
                    return DataRow(
                      cells: [
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: tc.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              orderTypeShortLabel(order),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: tc,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(order.invoiceNumber)),
                        DataCell(Text(order.referenceNumber?.isNotEmpty == true ? order.referenceNumber! : '—')),
                        DataCell(Text(DateFormat('dd-MM-yyyy HH:mm').format(order.createdAt))),
                        DataCell(Text('₹ ${total.toStringAsFixed(2)}')),
                        DataCell(Text(order.status.toUpperCase())),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility_outlined, size: 20),
                                color: AppColors.primaryColor,
                                onPressed: () => showRecentSaleOrderDetails(context, order),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                color: AppColors.primaryColor,
                                onPressed: () => openRecentSaleForEdit(
                                  context,
                                  order,
                                  onReturn: () {
                                    onAfterEdit();
                                  },
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
}

class _OrdersCardList extends StatelessWidget {
  const _OrdersCardList({
    required this.orders,
    required this.onAfterEdit,
  });

  final List<Order> orders;
  final Future<void> Function() onAfterEdit;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = orders[index];
        final total = order.finalAmount > 0 ? order.finalAmount : order.totalAmount;
        final tc = orderTypeColor(order);
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tc.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          orderTypeShortLabel(order),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: tc,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₹ ${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(order.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy · HH:mm').format(order.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  if (order.referenceNumber != null && order.referenceNumber!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Ref: ${order.referenceNumber}', style: TextStyle(fontSize: 13, color: Colors.grey.shade800)),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => showRecentSaleOrderDetails(context, order),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('View'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => openRecentSaleForEdit(
                          context,
                          order,
                          onReturn: () {
                            onAfterEdit();
                          },
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
