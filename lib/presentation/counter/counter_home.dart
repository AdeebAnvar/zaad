import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/app/routes.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/repository/order_repository.dart';
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
                      onTap: () {
                        if (index == 0) {
                          AppNavigator.pushNamed(Routes.counter);
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider(
                                create: (context) => TakeAwayLogCubit(
                                  locator<OrderRepository>(),
                                ),
                                child: const TakeAwayLogScreen(),
                              ),
                            ),
                          );
                        }
                      },
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
  // "Customers",
  // "Reports",
  // "Sync",
  // "Settings",
];

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
