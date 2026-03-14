import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/app/routes.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/repository/delivery_partner_repository.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/presentation/delivery_log/delivery_log_cubit.dart';
import 'package:pos/presentation/delivery_log/delivery_log_ui.dart';
import 'package:pos/presentation/take_away_log/take_away_log_cubit.dart';
import 'package:pos/presentation/take_away_log/take_away_log_ui.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';

class CounterHome extends StatefulWidget {
  const CounterHome({super.key, required this.id});
  final int id;
  @override
  State<CounterHome> createState() => _CounterHomeState();
}

class _CounterHomeState extends State<CounterHome> {
  void _handleCardTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        AppNavigator.pushNamed(Routes.counter, args: {'orderType': 'take_away'});
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (context) => TakeAwayLogCubit(locator<OrderRepository>()),
              child: const TakeAwayLogScreen(),
            ),
          ),
        );
        break;
      case 2:
        _showDeliveryPartnerPopup(context);
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (context) => DeliveryLogCubit(locator<OrderRepository>()),
              child: const DeliveryLogScreen(),
            ),
          ),
        );
        break;
    }
  }

  Future<void> _showDeliveryPartnerPopup(BuildContext context) async {
    final repo = locator<DeliveryPartnerRepository>();
    final partners = await repo.getAll();
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Delivery Partner'),
        content: SizedBox(
          width: 280,
          child: partners.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No delivery partners. Sync to fetch from server.',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: partners.length,
                  itemBuilder: (_, i) {
                    final partner = partners[i];
                    return ListTile(
                      leading: const Icon(Icons.delivery_dining),
                      title: Text(partner.name),
                      onTap: () {
                        Navigator.pop(ctx);
                        AppNavigator.pushNamed(
                          Routes.counter,
                          args: {'orderType': 'delivery', 'deliveryPartner': partner.name},
                        );
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Zaad Dine',
      appBarScreen: 'dashboard',
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          // 🔹 Default (mobile)
          int crossAxisCount = 1;
          double maxWidth = width;

          // 🔹 Tablet & Desktop → 2 columns
          if (width >= 600) {
            crossAxisCount = 2;
            maxWidth = 900; // keeps grid centered
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: _titles.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    childAspectRatio: 3.90, // POS-style wide cards
                  ),
                  itemBuilder: (context, index) {
                    return _DashboardCard(
                      title: _titles[index],
                      onTap: () => _handleCardTap(context, index),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// -------------------- CARD --------------------

class _DashboardCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: AppStyles.getSemiBoldTextStyle(fontSize: 20, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// -------------------- DATA --------------------

const _titles = [
  "Take Away",
  "Take Away Log",
  "Delivery Sale",
  "Delivery Sale Log",
];

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
