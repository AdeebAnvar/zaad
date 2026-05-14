import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/app/routes.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/domain/models/user_model.dart';
import 'package:pos/data/repository/delivery_partner_repository.dart';
import 'package:pos/data/repository/driver_repository.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/presentation/delivery_log/delivery_log_cubit.dart';
import 'package:pos/presentation/delivery_log/delivery_log_ui.dart';
import 'package:pos/presentation/take_away_log/take_away_log_cubit.dart';
import 'package:pos/presentation/take_away_log/take_away_log_ui.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';

class CounterHome extends StatefulWidget {
  const CounterHome({super.key, required this.sessionUser});
  final UserModel? sessionUser;

  @override
  State<CounterHome> createState() => _CounterHomeState();
}

class _CounterHomeState extends State<CounterHome> {
  StreamSubscription<Order?>? _tokenBoardSub;
  int? _lastPickupToken;

  @override
  void initState() {
    super.initState();
    _bindPickupTokenStream();
  }

  Future<void> _bindPickupTokenStream() async {
    await _tokenBoardSub?.cancel();
    final db = locator<AppDatabase>();
    final session = await db.sessionDao.getActiveSession();
    final bid = session?.branchId ?? 1;
    if (!mounted) return;
    _tokenBoardSub = db.dayClosingCheckpointDao
        .watchLastSettledAtForBranch(bid)
        .asyncExpand(
          (cutoff) => db.ordersDao.watchLatestOrderWithPickupToken(
                branchId: bid,
                createdAfterExclusive: cutoff,
              ),
        )
        .listen((order) {
      if (!mounted) return;
      setState(() => _lastPickupToken = order?.pickupToken);
    });
  }

  @override
  void dispose() {
    _tokenBoardSub?.cancel();
    super.dispose();
  }

  List<_DashboardTile> _tilesForAccess(CounterAccess access) {
    final list = <_DashboardTile>[];
    if (access.canTakeAwayCounter) {
      list.add(
        _DashboardTile(
          title: 'Take Away',
          icon: Icons.point_of_sale_rounded,
          onTap: (ctx) => AppNavigator.pushNamed(Routes.counter, args: {'orderType': 'take_away'}),
        ),
      );
    }
    if (access.canTakeAwayLog) {
      list.add(
        _DashboardTile(
          title: 'Take Away Log',
          icon: Icons.receipt_long_rounded,
          onTap: (ctx) => Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (context) => TakeAwayLogCubit(
                  locator<OrderRepository>(),
                  locator<LocalHubSettings>(),
                  locator<CurrentCounterSession>(),
                  hubOrdersLive: locator<HubOrdersLiveSync>(),
                ),
                child: const TakeAwayLogScreen(),
              ),
            ),
          ),
        ),
      );
    }
    if (access.canDeliverySale) {
      list.add(
        _DashboardTile(
          title: 'Delivery Sale',
          icon: Icons.delivery_dining_rounded,
          onTap: (ctx) => _showDeliveryPartnerPopup(ctx),
        ),
      );
    }
    if (access.canDeliveryLog) {
      list.add(
        _DashboardTile(
          title: 'Delivery Sale Log',
          icon: Icons.local_shipping_rounded,
          onTap: (ctx) => Navigator.push(
            ctx,
            MaterialPageRoute(
              builder: (_) => BlocProvider(
                create: (context) => DeliveryLogCubit(
                  locator<OrderRepository>(),
                  locator<DeliveryPartnerRepository>(),
                  locator<DriverRepository>(),
                  locator<LocalHubSettings>(),
                  locator<CurrentCounterSession>(),
                  hubOrdersLive: locator<HubOrdersLiveSync>(),
                ),
                child: const DeliveryLogScreen(),
              ),
            ),
          ),
        ),
      );
    }
    if (access.canDineIn) {
      list.add(
        _DashboardTile(
          title: 'Dine In',
          icon: Icons.table_restaurant_rounded,
          onTap: (_) => AppNavigator.pushNamed(Routes.dineIn),
        ),
      );
    }
    if (access.canDineInLog) {
      list.add(
        _DashboardTile(
          title: 'Dine In Log',
          icon: Icons.event_note_rounded,
          onTap: (_) => AppNavigator.pushNamed(Routes.dineInLog),
        ),
      );
    }
    return list;
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
        onSelectPartner: (partnerName, deliveryServiceId) {
          Navigator.pop(ctx);
          AppNavigator.pushNamed(
            Routes.counter,
            args: {
              'orderType': 'delivery',
              'deliveryPartner': partnerName,
              'deliveryServiceId': deliveryServiceId,
            },
          );
        },
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final access = CounterAccess.fromUser(widget.sessionUser);
    final tiles = _tilesForAccess(access);

    return CustomScaffold(
      title: 'Zaad Dine',
      appBarScreen: 'dashboard',
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (tiles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No counter modules are assigned to your account. Contact your administrator.',
                  textAlign: TextAlign.center,
                  style: AppStyles.getRegularTextStyle(fontSize: 15, color: AppColors.hintFontColor),
                ),
              ),
            );
          }

          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final maxColsByWidth = width >= 1200 ? 3 : (width >= 760 ? 2 : 1);
          // Fewer tiles than columns left empty trailing cells — looks left-heavy on wide dashboards.
          final crossAxisCount = math.max(1, math.min(maxColsByWidth, tiles.length));
          final gap = width >= 760 ? 14.0 : 10.0;
          final horizontalPad = math.max(12.0, math.min(28.0, width * 0.03));
          final verticalPad = math.max(10.0, math.min(24.0, height * 0.02));

          return Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.fromLTRB(horizontalPad, verticalPad, horizontalPad, 12),
              child: SizedBox(
                width: math.max(0, width - 2 * horizontalPad),
                height: math.max(0, height - verticalPad - 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 38,
                      child: _CounterPickupTokenStrip(token: _lastPickupToken),
                    ),
                    SizedBox(height: gap + 2),
                    Expanded(
                      flex: 62,
                      child: LayoutBuilder(
                        builder: (context, gridConstraints) {
                          final rows = (tiles.length + crossAxisCount - 1) ~/ crossAxisCount;
                          final innerH = gridConstraints.maxHeight;
                          final tileH = rows > 0
                              ? math.max(
                                  72.0,
                                  (innerH - (rows - 1) * gap) / rows,
                                )
                              : 100.0;
                          return GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: tiles.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: gap,
                              mainAxisSpacing: gap,
                              mainAxisExtent: tileH,
                            ),
                            itemBuilder: (context, index) {
                              final t = tiles[index];
                              return _DashboardCard(
                                title: t.title,
                                icon: t.icon,
                                onTap: () => t.onTap(context),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DashboardTile {
  const _DashboardTile({required this.title, required this.icon, required this.onTap});
  final String title;
  final IconData icon;
  final void Function(BuildContext context) onTap;
}

class _CounterPickupTokenStrip extends StatelessWidget {
  const _CounterPickupTokenStrip({required this.token});
  final int? token;

  @override
  Widget build(BuildContext context) {
    final label = token != null ? '$token' : '—';
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final compact = w < 560;
        final numberFont = (h * 0.42).clamp(44.0, 120.0);
        final labelFont = (h * 0.075).clamp(12.0, 18.0);
        return Container(
          width: double.infinity,
          height: h.isFinite ? h : null,
          padding: EdgeInsets.symmetric(
            vertical: math.max(8.0, h * 0.06),
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'TOKEN NO.',
                style: AppStyles.getSemiBoldTextStyle(
                  fontSize: compact ? math.min(labelFont, 13) : labelFont,
                  color: AppColors.hintFontColor,
                ).copyWith(letterSpacing: 1.2),
              ),
              SizedBox(height: math.max(4.0, h * 0.02)),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: AppStyles.getBoldTextStyle(
                        fontSize: numberFont,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// -------------------- DELIVERY SERVICE DIALOG --------------------

class _DeliveryServiceDialog extends StatelessWidget {
  final List<DeliveryPartner> partners;
  final void Function(String partnerName, String deliveryServiceId) onSelectPartner;
  final VoidCallback onClose;

  const _DeliveryServiceDialog({
    required this.partners,
    required this.onSelectPartner,
    required this.onClose,
  });

  static Widget _buildOptionRow(String label, int index, String serviceId, void Function(String, String) onSelect) {
    final isAltRow = index.isOdd;
    return Container(
      color: isAltRow ? Colors.white : const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Center(
        child: Material(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: () => onSelect(label, serviceId),
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
                final options = <({String label, String id})>[
                  for (final p in partners)
                    if (p.name.trim().isNotEmpty) (label: p.name.trim(), id: p.id.toString()),
                ];
                final hasNormal = options.any((e) => e.label.toUpperCase() == 'NORMAL');
                if (!hasNormal) {
                  options.add((label: 'NORMAL', id: 'NORMAL'));
                }
                if (options.length == 1) {
                  final o = options.single;
                  return _buildOptionRow(o.label, 0, o.id, onSelectPartner);
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: options.length,
                  separatorBuilder: (_, __) => const SizedBox.shrink(),
                  itemBuilder: (_, i) {
                    final o = options[i];
                    return _buildOptionRow(o.label, i, o.id, onSelectPartner);
                  },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final compact = w < 560 || h < 72;
        final iconSize = (h * 0.32).clamp(18.0, 32.0);
        final fontSize = (h * 0.2).clamp(14.0, 24.0);
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
              padding: EdgeInsets.symmetric(horizontal: compact ? 10 : math.max(10.0, w * 0.06)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white.withValues(alpha: 0.96), size: iconSize),
                  SizedBox(width: math.max(8.0, w * 0.04)),
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppStyles.getSemiBoldTextStyle(
                        fontSize: compact ? math.min(fontSize, 17) : fontSize,
                        color: Colors.white,
                      ),
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

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
