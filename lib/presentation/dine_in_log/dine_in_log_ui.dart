import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/cart_repository.dart';
import 'package:pos/data/repository/item_repository.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/presentation/dine_in_log/dine_in_log_cubit.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';

class DineInLogScreen extends StatelessWidget {
  const DineInLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DineInLogCubit(locator<OrderRepository>()),
      child: CustomScaffold(
        title: 'Dine In Log',
        appBarScreen: 'take_away_log',
        body: BlocBuilder<DineInLogCubit, DineInLogState>(
          builder: (context, state) {
            if (state is DineInLogLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is DineInLogError) {
              return Center(child: Text(state.message));
            }
            if (state is! DineInLogLoaded) {
              return const SizedBox.shrink();
            }

            return RefreshIndicator(
              onRefresh: () => context.read<DineInLogCubit>().refreshOrders(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: AppPadding.screenAll,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _DineInFilterBar(),
                    const SizedBox(height: 16),
                    if (state.orders.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No dine in orders')),
                      )
                    else
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: state.orders
                            .map((o) => SizedBox(
                                  width: 420,
                                  child: _DineInLogCard(order: o),
                                ))
                            .toList(),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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

  @override
  void dispose() {
    _invoiceController.dispose();
    _referenceController.dispose();
    super.dispose();
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
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        children: [
          SizedBox(
            width: 220,
            child: CustomTextField(controller: _invoiceController, labelText: 'Receipt No'),
          ),
          SizedBox(
            width: 220,
            child: CustomTextField(controller: _referenceController, labelText: 'Table / Ref'),
          ),
          CustomButton(
            width: 110,
            text: 'Filter',
            onPressed: () {
              context.read<DineInLogCubit>().filterOrders(
                    invoiceNumber: _invoiceController.text.trim().isEmpty ? null : _invoiceController.text.trim(),
                    referenceNumber: _referenceController.text.trim().isEmpty ? null : _referenceController.text.trim(),
                  );
            },
          ),
          CustomButton(
            width: 110,
            text: 'Clear',
            backgroundColor: Colors.grey,
            onPressed: () {
              _invoiceController.clear();
              _referenceController.clear();
              context.read<DineInLogCubit>().loadOrders();
            },
          ),
        ],
      ),
    );
  }
}

class _DineInLogCard extends StatelessWidget {
  const _DineInLogCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final dt = DateFormat('dd MMM yyyy · HH:mm').format(order.createdAt);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'DINE IN',
                  style: AppStyles.getSemiBoldTextStyle(fontSize: 11, color: AppColors.primaryColor),
                ),
              ),
              const Spacer(),
              Text(dt, style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.hintFontColor)),
            ],
          ),
          const SizedBox(height: 12),
          _info('Receipt', order.invoiceNumber),
          const SizedBox(height: 8),
          _info('Table / Ref', order.referenceNumber ?? '-'),
          const SizedBox(height: 8),
          _info('Status', order.status.toUpperCase()),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '₹ ${order.finalAmount.toStringAsFixed(2)}',
                style: AppStyles.getBoldTextStyle(fontSize: 20),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () => _viewItems(context, order),
                icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                label: const Text('View'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _printOrder(context, order),
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text('Print'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.hintFontColor)),
        ),
        Expanded(child: Text(value, style: AppStyles.getMediumTextStyle(fontSize: 13))),
      ],
    );
  }

  Future<void> _printOrder(BuildContext context, Order order) async {
    final cartRepo = locator<CartRepository>();
    final printService = locator<PrintService>();
    final cartItems = await cartRepo.getCartItemsByCartId(order.cartId);
    if (cartItems == null || cartItems.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No items to print')));
      return;
    }
    try {
      await printService.printFinalBill(order: order, cartItems: cartItems);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bill sent to printer')));
    } catch (e) {
      if (!context.mounted) return;
      showErrorDialog(context, e);
    }
  }

  Future<void> _viewItems(BuildContext context, Order order) async {
    final cartRepo = locator<CartRepository>();
    final itemRepo = locator<ItemRepository>();
    final cartItems = await cartRepo.getCartItemsByCartId(order.cartId);
    if (cartItems == null || cartItems.isEmpty) {
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => const AlertDialog(title: Text('Order Details'), content: Text('No items found in this order.')),
      );
      return;
    }
    final List<Map<String, dynamic>> itemsWithDetails = [];
    for (final cartItem in cartItems) {
      final item = await itemRepo.fetchItemByIdFromLocal(cartItem.itemId);
      itemsWithDetails.add({'cartItem': cartItem, 'item': item});
    }
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Order ${order.invoiceNumber}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: itemsWithDetails.map((m) {
              final item = m['item'] as Item?;
              final cartItem = m['cartItem'] as CartItem;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('${item?.name ?? "?"} x${cartItem.quantity} - ₹${cartItem.total.toStringAsFixed(2)}'),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }
}
