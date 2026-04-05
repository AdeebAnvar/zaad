import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/customer_repository.dart';
import 'package:pos/presentation/crm/crm_cubit.dart';
import 'package:pos/presentation/crm/crm_customer_details_screen.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';
import 'package:pos/presentation/widgets/custom_sheet.dart';
import 'package:pos/presentation/widgets/modern_bottom_sheet.dart' show filterPanelDecoration;
import 'package:pos/presentation/widgets/custom_textfield.dart';
import 'package:pos/app/navigation.dart';

class CrmScreen extends StatelessWidget {
  const CrmScreen({super.key});
  static const String route = '/crm';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CrmCubit(
        locator<CustomerRepository>(),
        locator<AppDatabase>(),
      )..loadCustomers(),
      child: CustomScaffold(
        title: 'CRM - Customers',
        body: BlocBuilder<CrmCubit, CrmState>(
          builder: (context, state) {
            if (state is CrmLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is CrmError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<CrmCubit>().loadCustomers(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is CrmLoaded) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 768;
                  return Column(
                    children: [
                      Padding(
                        padding: AppPadding.screenAll,
                        child: isMobile
                            ? Row(
                                children: [
                                  Text(
                                    'Total ${state.customers.length} Customers',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.filter_list, color: AppColors.primaryColor),
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
                                    tooltip: 'Filters',
                                  ),
                                ],
                              )
                            : const _FilterBar(),
                      ),
                      Expanded(
                        child: state.customers.isEmpty
                            ? const Center(
                                child: Text(
                                  'No customers found',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMobile)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: AppPadding.screenHorizontal, vertical: 12),
                                      child: Text(
                                        'Total ${state.customers.length} Customers',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  Expanded(
                                    child: RefreshIndicator(
                                      onRefresh: () => context.read<CrmCubit>().loadCustomers(),
                                      child: LayoutBuilder(
                                        builder: (context, innerConstraints) {
                                          final innerMobile = innerConstraints.maxWidth < 768;
                                          if (innerMobile) {
                                            return _MobileTable(customers: state.customers);
                                          } else {
                                            return _DesktopTable(customers: state.customers);
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
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
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppPadding.card,
      decoration: filterPanelDecoration(borderRadius: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, color: AppColors.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Filters',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 768;
              if (isMobile) {
                return Column(
                  children: [
                    CustomTextField(
                      controller: _searchController,
                      labelText: 'Search (Name, Phone, Email)',
                      prefixIcon: const Icon(Icons.search),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          context.read<CrmCubit>().loadCustomers();
                        } else {
                          context.read<CrmCubit>().searchCustomers(value);
                        }
                      },
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _searchController,
                            labelText: 'Search (Name, Phone, Email)',
                            prefixIcon: const Icon(Icons.search),
                            onChanged: (value) {
                              if (value.isEmpty) {
                                context.read<CrmCubit>().loadCustomers();
                              } else {
                                context.read<CrmCubit>().searchCustomers(value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        CustomButton(
                          text: 'Clear',
                          width: 100,
                          elevation: 0,
                          onPressed: () {
                            _searchController.clear();
                            _nameController.clear();
                            _phoneController.clear();
                            _emailController.clear();
                            context.read<CrmCubit>().loadCustomers();
                          },
                        ),
                      ],
                    ),

                    //   Row(
                    //     children: [
                    //       Expanded(
                    //         child: CustomTextField(
                    //           controller: _nameController,
                    //           labelText: 'Filter by Name',
                    //           onChanged: (value) {
                    //             context.read<CrmCubit>().filterCustomers(
                    //                   name: value.isEmpty ? null : value,
                    //                   phone: _phoneController.text.isEmpty ? null : _phoneController.text,
                    //                   email: _emailController.text.isEmpty ? null : _emailController.text,
                    //                 );
                    //           },
                    //         ),
                    //       ),
                    //       const SizedBox(width: 12),
                    //       Expanded(
                    //         child: CustomTextField(
                    //           controller: _phoneController,
                    //           labelText: 'Filter by Phone',
                    //           onChanged: (value) {
                    //             context.read<CrmCubit>().filterCustomers(
                    //                   name: _nameController.text.isEmpty ? null : _nameController.text,
                    //                   phone: value.isEmpty ? null : value,
                    //                   email: _emailController.text.isEmpty ? null : _emailController.text,
                    //                 );
                    //           },
                    //         ),
                    //       ),
                    //       const SizedBox(width: 12),
                    //       Expanded(
                    //         child: CustomTextField(
                    //           controller: _emailController,
                    //           labelText: 'Filter by Email',
                    //           onChanged: (value) {
                    //             context.read<CrmCubit>().filterCustomers(
                    //                   name: _nameController.text.isEmpty ? null : _nameController.text,
                    //                   phone: _phoneController.text.isEmpty ? null : _phoneController.text,
                    //                   email: value.isEmpty ? null : value,
                    //                 );
                    //           },
                    //         ),
                    //       ),
                    //       const SizedBox(width: 12),
                    //       CustomButton(
                    //         text: 'Clear',
                    //         width: 100,
                    //         onPressed: () {
                    //           _searchController.clear();
                    //           _nameController.clear();
                    //           _phoneController.clear();
                    //           _emailController.clear();
                    //           context.read<CrmCubit>().loadCustomers();
                    //         },
                    //       ),
                    //     ],
                    //   ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _DesktopTable extends StatelessWidget {
  final List<CustomerWithOrders> customers;

  const _DesktopTable({required this.customers});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppPadding.screenHorizontal, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              child: SizedBox(
                width: constraints.maxWidth > 0 ? constraints.maxWidth : double.infinity,
                child: DataTable(
                  showCheckboxColumn: false,
                  headingRowColor: MaterialStateProperty.all(
                    AppColors.primaryColor.withOpacity(0.1),
                  ),
                  headingRowHeight: 56,
                  dataRowMinHeight: 60,
                  dataRowMaxHeight: 80,
                  columnSpacing: 20,
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primaryColor,
                  ),
                  columns: const [
                    DataColumn(label: Text('S.NO.'), numeric: true),
                    DataColumn(label: Text('CUSTOMER')),
                    DataColumn(label: Text('CUSTOMER PURCHASED AMOUNT'), numeric: true),
                    DataColumn(label: Text('CUSTOMER PURCHASED COUNT'), numeric: true),
                  ],
                  rows: customers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final customerWithOrders = entry.value;
                    final customer = customerWithOrders.customer;

                    // Format customer name with phone in parentheses
                    String customerDisplay = customer.name;
                    if (customer.phone != null && customer.phone!.isNotEmpty) {
                      customerDisplay = '${customer.name} (${customer.phone})';
                    }

                    return DataRow(
                      onSelectChanged: (selected) {
                        if (selected == true && customer.id != null) {
                          AppNavigator.pushNamed(
                            CrmCustomerDetailsScreen.route,
                            args: {'customerId': customer.id},
                          );
                        }
                      },
                      cells: [
                        DataCell(
                          Text(
                            '${index + 1}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        DataCell(
                          Text(
                            customerDisplay,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            customerWithOrders.totalSpent.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            customerWithOrders.orderCount.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MobileTable extends StatelessWidget {
  final List<CustomerWithOrders> customers;

  const _MobileTable({required this.customers});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: AppPadding.screenAll,
      itemCount: customers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final customerWithOrders = customers[index];
        final customer = customerWithOrders.customer;

        // Format customer name with phone in parentheses
        String customerDisplay = customer.name;
        if (customer.phone != null && customer.phone!.isNotEmpty) {
          customerDisplay = '${customer.name} (${customer.phone})';
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              if (customer.id != null) {
                AppNavigator.pushNamed(
                  CrmCustomerDetailsScreen.route,
                  args: {'customerId': customer.id},
                );
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: AppPadding.card,
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerDisplay,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Amount: ₹${customerWithOrders.totalSpent.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Count: ${customerWithOrders.orderCount}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
