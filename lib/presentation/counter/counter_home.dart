import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/app/routes.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/delivery_partner_repository.dart';
import 'package:pos/data/repository/driver_repository.dart';
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
              create: (context) => DeliveryLogCubit(
                locator<OrderRepository>(),
                locator<DeliveryPartnerRepository>(),
                locator<DriverRepository>(),
              ),
              child: const DeliveryLogScreen(),
            ),
          ),
        );
        break;
      case 4:
        AppNavigator.pushNamed(Routes.dineIn);
        break;
      case 5:
        AppNavigator.pushNamed(Routes.dineInLog);
        break;
    }
  }

  Future<void> _showDeliveryPartnerPopup(BuildContext context) async {
    final repo = locator<DeliveryPartnerRepository>();
    final partners = await repo.getAll();
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _DeliveryServiceDialog(
        partners: partners,
        onSelectPartner: (partnerName) {
          Navigator.pop(ctx);
          AppNavigator.pushNamed(
            Routes.counter,
            args: {'orderType': 'delivery', 'deliveryPartner': partnerName},
          );
        },
        onClose: () => Navigator.pop(ctx),
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
          final crossAxisCount = width >= 1200
              ? 3
              : width >= 760
                  ? 2
                  : 1;
          final maxWidth = width >= 1400 ? 1120.0 : (width >= 760 ? 980.0 : width);
          final gap = width >= 760 ? 12.0 : 10.0;
          final horizontalPad = width >= 760 ? 200.0 : 10.0;
          final verticalPad = width >= 760 ? 29.0 : 12.0;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(
                padding: EdgeInsets.fromLTRB(horizontalPad, verticalPad, horizontalPad, 12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _titles.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: gap,

                    mainAxisSpacing: gap, mainAxisExtent: 100,
                    // childAspectRatio: width >= 980 ? 3.2 : (width >= 760 ? 1.8 : 3.0),
                  ),
                  itemBuilder: (context, index) {
                    return _DashboardCard(
                      title: _titles[index],
                      icon: _icons[index],
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

/// -------------------- DELIVERY SERVICE DIALOG --------------------

class _DeliveryServiceDialog extends StatelessWidget {
  final List<DeliveryPartner> partners;
  final void Function(String partnerName) onSelectPartner;
  final VoidCallback onClose;

  const _DeliveryServiceDialog({
    required this.partners,
    required this.onSelectPartner,
    required this.onClose,
  });

  static Widget _buildOptionRow(String label, int index, void Function(String) onSelect) {
    final isAltRow = index.isOdd;
    return Container(
      color: isAltRow ? Colors.white : const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Center(
        child: Material(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () => onSelect(label),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
              child: Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Text(
                'DELIVERY SERVICE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            // Body: delivery partners from sync + NORMAL (own delivery)
            Builder(
              builder: (_) {
                final options = <String>[
                  ...partners.map((p) => p.name.trim()).where((e) => e.isNotEmpty),
                ];
                final hasNormal = options.any((e) => e.toUpperCase() == 'NORMAL');
                if (!hasNormal) {
                  options.add('NORMAL'); // Own delivery - always available
                }
                if (options.length == 1) {
                  // Only NORMAL
                  return _buildOptionRow('NORMAL', 0, onSelectPartner);
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox.shrink(),
                  itemBuilder: (_, i) => _buildOptionRow(options[i], i, onSelectPartner),
                );
              },
            ),
            // Footer
            Divider(color: AppColors.divider, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Material(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.divider),
                  ),
                  child: InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                      child: const Text(
                        'CLOSE',
                        style: TextStyle(
                          color: Color(0xFF5A5A5A),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// -------------------- CARD --------------------

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final compact = w < 560;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.96), size: compact ? 18 : 20),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppStyles.getSemiBoldTextStyle(
                    fontSize: compact ? 18 : 19,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
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
  "Dine In",
  "Dine In Log",
];

const _icons = [
  Icons.point_of_sale_rounded,
  Icons.receipt_long_rounded,
  Icons.delivery_dining_rounded,
  Icons.local_shipping_rounded,
  Icons.table_restaurant_rounded,
  Icons.event_note_rounded,
];

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
