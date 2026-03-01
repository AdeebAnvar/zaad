import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/customer_repository.dart';
import 'package:pos/domain/models/customer_model.dart';
import 'package:pos/presentation/crm/crm_cubit.dart';

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
      // Handle error
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Customer Details'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (customer == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text('Customer Details'),
          backgroundColor: AppColors.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Customer not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Customer Details'),
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _customerInfoCard(),
            const SizedBox(height: 24),
            _ordersSection(),
          ],
        ),
      ),
    );
  }

  Widget _customerInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primaryColor,
                  child: Text(
                    customer!.name.isNotEmpty ? customer!.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer!.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (customer!.phone != null && customer!.phone!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Phone: ${customer!.phone}',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                          ),
                        ),
                      if (customer!.email != null && customer!.email!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Email: ${customer!.email}',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                          ),
                        ),
                      if (customer!.gender != null && customer!.gender!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Chip(
                            label: Text(customer!.gender!),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (customer!.createdAt != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Customer since: ${DateFormat('MMM dd, yyyy').format(customer!.createdAt!)}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ordersSection() {
    final totalSpent = orders.fold<double>(0.0, (sum, order) => sum + order.finalAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Order History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${orders.length} order${orders.length == 1 ? '' : 's'} • ₹${totalSpent.toStringAsFixed(2)}',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (orders.isEmpty)
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
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _orderCard(order);
            },
          ),
      ],
    );
  }

  Widget _orderCard(Order order) {
    return Card(
      elevation: 1,
      child: InkWell(
        onTap: () {
          // Navigate to order details if needed
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.invoiceNumber,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ₹${order.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  Text(
                    'Final: ₹${order.finalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'placed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
