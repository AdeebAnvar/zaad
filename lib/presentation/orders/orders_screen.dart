import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/presentation/orders/orders_cubit.dart';
import 'package:pos/presentation/widgets/custom_app_bar.dart';
import 'package:pos/presentation/widgets/relative_time_text.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrdersCubit(locator<OrderRepository>())..loadOrders(),
      child: Scaffold(
        appBar: const CustomAppBar(title: 'Orders'),
        body: BlocBuilder<OrdersCubit, OrdersState>(
          builder: (context, state) {
            if (state is OrdersLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is OrdersError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<OrdersCubit>().loadOrders(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is OrdersLoaded) {
              if (state.orders.isEmpty) {
                return const Center(
                  child: Text(
                    'No orders found',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () => context.read<OrdersCubit>().loadOrders(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.orders.length,
                  itemBuilder: (context, index) {
                    final order = state.orders[index];
                    return _OrderCard(order: order);
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final dynamic order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.invoiceNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (order.customerName != null) ...[
              Text('Customer: ${order.customerName}'),
              if (order.customerPhone != null)
                Text('Phone: ${order.customerPhone}'),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Date: '),
                    RelativeTimeText(
                      at: order.createdAt,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Text(
                  '₹ ${order.finalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
            ),
            if (order.discountAmount > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Discount: ₹ ${order.discountAmount.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
            if (order.cashAmount > 0 || order.creditAmount > 0 || order.cardAmount > 0 || order.onlineAmount > 0) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                children: [
                  if (order.cashAmount > 0)
                    Text('Cash: ₹ ${order.cashAmount.toStringAsFixed(2)}'),
                  if (order.creditAmount > 0)
                    Text('Credit: ₹ ${order.creditAmount.toStringAsFixed(2)}'),
                  if (order.cardAmount > 0)
                    Text('Card: ₹ ${order.cardAmount.toStringAsFixed(2)}'),
                  if (order.onlineAmount > 0)
                    Text('Online: ₹ ${order.onlineAmount.toStringAsFixed(2)}'),
                ],
              ),
            ],
          ],
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
      case 'kot':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
