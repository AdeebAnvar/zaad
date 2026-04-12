import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:pos/presentation/widgets/relative_time_text.dart';

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

  DateTime? _lastOrderAt() {
    if (orders.isEmpty) return null;
    return orders.map((o) => o.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return CustomScaffold(
        title: 'Profile',
        onBack: () => Navigator.of(context).pop(),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
      );
    }

    if (customer == null) {
      return CustomScaffold(
        title: 'Profile',
        onBack: () => Navigator.of(context).pop(),
        body: Center(
          child: Text(
            'Customer not found',
            style: AppStyles.getRegularTextStyle(fontSize: 16, color: AppColors.hintFontColor),
          ),
        ),
      );
    }

    final c = customer!;
    final totalSpent = orders.fold<double>(0.0, (sum, o) => sum + o.finalAmount);
    final counts = _countsByChannel();
    final avgOrder = orders.isEmpty ? 0.0 : totalSpent / orders.length;
    final lastAt = _lastOrderAt();

    return CustomScaffold(
      title: 'Customer profile',
      onBack: () => Navigator.of(context).pop(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 768;
          final maxContent = constraints.maxWidth > 1200 ? 1000.0 : constraints.maxWidth;
          return RefreshIndicator(
            color: AppColors.primaryColor,
            onRefresh: _loadCustomerDetails,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContent),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileHero(
                        customer: c,
                        orderCount: orders.length,
                        totalSpent: totalSpent,
                        avgOrder: avgOrder,
                        lastOrderAt: lastAt,
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isNarrow ? 0 : 0,
                          0,
                          isNarrow ? 0 : 0,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Transform.translate(
                              offset: const Offset(0, -28),
                              child: _ContactDetailsCard(customer: c),
                            ),
                            const SizedBox(height: 4),
                            _ActivityByChannelCard(counts: counts),
                            const SizedBox(height: 20),
                            _OrderHistoryHeader(count: orders.length),
                            const SizedBox(height: 12),
                            if (orders.isEmpty)
                              _EmptyOrdersPlaceholder()
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
                            const SizedBox(height: 24),
                          ],
                        ),
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

/// Top banner: avatar, name, key metrics — app primary theme.
class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.customer,
    required this.orderCount,
    required this.totalSpent,
    required this.avgOrder,
    required this.lastOrderAt,
  });

  final CustomerModel customer;
  final int orderCount;
  final double totalSpent;
  final double avgOrder;
  final DateTime? lastOrderAt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 44),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text(
                      customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                      style: AppStyles.getBoldTextStyle(fontSize: 32, color: AppColors.primaryColor),
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
                        style: AppStyles.getBoldTextStyle(fontSize: 22, color: Colors.white),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (customer.phone != null && customer.phone!.isNotEmpty) _HeroLine(icon: Icons.phone_rounded, text: customer.phone!),
                      if (customer.email != null && customer.email!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: _HeroLine(icon: Icons.email_outlined, text: customer.email!),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.dashboard_outlined, color: Colors.white.withValues(alpha: 0.9)),
                  tooltip: 'Dashboard',
                  onPressed: () => AppNavigator.pushReplacementNamed(Routes.dashboard),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _HeroMetric(
                    label: 'Orders',
                    value: '$orderCount',
                    icon: Icons.receipt_long_outlined,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                Expanded(
                  child: _HeroMetric(
                    label: 'Lifetime value',
                    value: '₹${totalSpent.toStringAsFixed(0)}',
                    icon: Icons.payments_outlined,
                  ),
                ),
                Container(width: 1, height: 40, color: Colors.white24),
                Expanded(
                  child: _HeroMetric(
                    label: 'Avg. order',
                    value: orderCount == 0 ? '—' : '₹${avgOrder.toStringAsFixed(0)}',
                    icon: Icons.analytics_outlined,
                  ),
                ),
              ],
            ),
            if (lastOrderAt != null) ...[
              const SizedBox(height: 14),
              Text(
                'Last order · ${DateFormat('MMM d, yyyy · h:mm a').format(lastOrderAt!)}',
                style: AppStyles.getRegularTextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroLine extends StatelessWidget {
  const _HeroLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppStyles.getRegularTextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.92)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.white70),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppStyles.getBoldTextStyle(fontSize: 16, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppStyles.getRegularTextStyle(fontSize: 11, color: Colors.white70),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }
}

/// Overlapping card: full contact & profile metadata.
class _ContactDetailsCard extends StatelessWidget {
  const _ContactDetailsCard({required this.customer});

  final CustomerModel customer;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      color: AppColors.cardColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.badge_outlined, size: 22, color: AppColors.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Contact & profile',
                  style: AppStyles.getSemiBoldTextStyle(fontSize: 16, color: AppColors.textColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (customer.id != null)
              _DetailTile(
                icon: Icons.tag_outlined,
                label: 'Customer ID',
                value: '#${customer.id}',
              ),
            if (customer.phone != null && customer.phone!.isNotEmpty)
              _DetailTile(
                icon: Icons.phone_android_rounded,
                label: 'Phone',
                value: customer.phone!,
                onCopy: customer.phone,
              ),
            if (customer.email != null && customer.email!.isNotEmpty)
              _DetailTile(
                icon: Icons.alternate_email_rounded,
                label: 'Email',
                value: customer.email!,
                onCopy: customer.email,
              ),
            if (customer.gender != null && customer.gender!.isNotEmpty)
              _DetailTile(
                icon: Icons.wc_rounded,
                label: 'Gender',
                value: customer.gender!,
              ),
            if (customer.createdAt != null)
              _DetailTile(
                icon: Icons.calendar_today_outlined,
                label: 'Customer since',
                value: DateFormat('MMMM d, yyyy').format(customer.createdAt!),
              ),
            if (customer.updatedAt != null)
              _DetailTile(
                icon: Icons.update_outlined,
                label: 'Profile updated',
                value: DateFormat('MMM d, yyyy').format(customer.updatedAt!),
              ),
            const Divider(height: 28),
            Row(
              children: [
                Icon(
                  customer.isSynced ? Icons.cloud_done_rounded : Icons.cloud_upload_outlined,
                  size: 20,
                  color: customer.isSynced ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    customer.isSynced ? 'Synced with server' : 'Pending sync',
                    style: AppStyles.getMediumTextStyle(
                      fontSize: 13,
                      color: customer.isSynced ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onCopy,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.hintFontColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.hintFontColor),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: AppStyles.getMediumTextStyle(fontSize: 15, color: AppColors.textColor),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 20),
              color: AppColors.primaryColor,
              tooltip: 'Copy',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: onCopy!));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied'),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ActivityByChannelCard extends StatelessWidget {
  const _ActivityByChannelCard({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final total = (counts['take_away'] ?? 0) + (counts['dine_in'] ?? 0) + (counts['delivery'] ?? 0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline_rounded, size: 22, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Activity by channel',
                style: AppStyles.getSemiBoldTextStyle(fontSize: 16, color: AppColors.textColor),
              ),
            ],
          ),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'No orders yet — purchases show here once receipts match this customer.',
                style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.hintFontColor),
              ),
            )
          else ...[
            const SizedBox(height: 14),
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
        ],
      ),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
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

class _OrderHistoryHeader extends StatelessWidget {
  const _OrderHistoryHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.history_rounded, size: 22, color: AppColors.primaryColor),
        const SizedBox(width: 8),
        Text(
          'Order history',
          style: AppStyles.getSemiBoldTextStyle(fontSize: 17, color: AppColors.textColor),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: AppStyles.getSemiBoldTextStyle(fontSize: 13, color: AppColors.primaryColor),
          ),
        ),
      ],
    );
  }
}

class _EmptyOrdersPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.hintFontColor),
          const SizedBox(height: 12),
          Text(
            'No orders linked yet',
            style: AppStyles.getSemiBoldTextStyle(fontSize: 16, color: AppColors.textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Orders appear when the receipt customer matches this profile (phone, email, or name).',
            textAlign: TextAlign.center,
            style: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.hintFontColor),
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
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
                  headingRowColor: WidgetStateProperty.all(AppColors.primaryColor.withValues(alpha: 0.08)),
                  headingTextStyle: AppStyles.getSemiBoldTextStyle(fontSize: 12, color: AppColors.primaryColor),
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
                              color: tc.withValues(alpha: 0.12),
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
                        DataCell(
                          RelativeTimeText(
                            at: order.createdAt,
                            style: AppStyles.getRegularTextStyle(fontSize: 13),
                          ),
                        ),
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
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(16),
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
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
                          color: tc.withValues(alpha: 0.12),
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
                        style: AppStyles.getBoldTextStyle(fontSize: 18, color: AppColors.primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    order.invoiceNumber,
                    style: AppStyles.getSemiBoldTextStyle(fontSize: 15, color: AppColors.textColor),
                  ),
                  const SizedBox(height: 4),
                  RelativeTimeText(
                    at: order.createdAt,
                    style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.hintFontColor),
                  ),
                  if (order.referenceNumber != null && order.referenceNumber!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Ref: ${order.referenceNumber}',
                      style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.textColor),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Status · ${order.status.toUpperCase()}',
                    style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.hintFontColor),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => showRecentSaleOrderDetails(context, order),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text('View'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryColor,
                          side: const BorderSide(color: AppColors.primaryColor),
                        ),
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
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryColor,
                          side: const BorderSide(color: AppColors.primaryColor),
                        ),
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
