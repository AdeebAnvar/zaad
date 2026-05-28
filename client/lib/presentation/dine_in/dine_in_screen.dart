import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/app/routes.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/core/utils/order_list_sort.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/presentation/dine_in_log/dine_in_reference_utils.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';
import 'package:pos/presentation/widgets/relative_time_text.dart';

const String _kChairAsset = 'assets/images/png/chair.png';

/// Seat covered by an active order (pax on ref); show red.
const Color _chairSeatOrdered = Color(0xFFDC2626);

/// Seat still available at the table; show green.
const Color _chairSeatAvailable = Color(0xFF22C55E);

/// Wider table when more seats (2→base, 4/6 scale up, capped).
double _tableWidthForChairs(int chairs) {
  if (chairs <= 0) return 56;
  const base = 58.0;
  const step = 14.0;
  return (base + (chairs - 2).clamp(0, 8) * step).clamp(56, 130);
}

/// Top row count: floor(n/2); bottom = n - top (4→2+2, 6→3+3, 5→2+3).
(int, int) _chairRowsSplit(int chairs) {
  if (chairs <= 0) return (0, 0);
  final top = chairs ~/ 2;
  return (top, chairs - top);
}

/// Same key for DB table codes and order references (trim + case).
String _tableKey(String codeOrExtracted) => codeOrExtracted.trim().toUpperCase();

class DineInScreen extends StatefulWidget {
  const DineInScreen({super.key});

  @override
  State<DineInScreen> createState() => _DineInScreenState();
}

class _DineInScreenState extends State<DineInScreen> {
  final _db = locator<AppDatabase>();
  final _orderRepo = locator<OrderRepository>();

  bool _loading = true;

  /// Chair-level allocation is disabled; floor plan shows order counts / loose capacity only.
  static const bool _seatHandlingEnabled = false;
  int _selectedFloorIndex = 0;
  List<DiningFloor> _floors = [];
  List<DiningTable> _tables = [];
  List<Order> _activeDineInOrders = [];

  /// Table code → floor ids that contain that code (for legacy refs without floor prefix).
  Map<String, Set<int>> _tableCodeToFloorIds = {};
  Map<String, int> _activeOrdersPerTable = {};

  /// When seat handling on: exact 1-based seats in use on this floor.
  Map<String, Set<int>> _blockedSeatsPerTable = {};

  /// When seat handling off: sum of pax strings per table (for capacity display).
  Map<String, int> _occupiedPaxPerTable = {};

  void Function()? _detachHubOrdersLive;

  @override
  void initState() {
    super.initState();
    final hub = locator<HubOrdersLiveSync>();
    void onRev() {
      if (mounted) _load(showLoadingOverlay: false);
    }

    hub.revision.addListener(onRev);
    _detachHubOrdersLive = () => hub.revision.removeListener(onRev);
    _load();
  }

  @override
  void dispose() {
    _detachHubOrdersLive?.call();
    super.dispose();
  }

  Future<void> _load({bool showLoadingOverlay = true}) async {
    if (showLoadingOverlay) {
      setState(() => _loading = true);
    }
    final priorFloorIndex = _selectedFloorIndex;
    final session = await _db.sessionDao.getActiveSession();
    final branchId = session?.branchId ?? 1;
    final triple = await Future.wait([
      _db.diningTablesDao.getFloorsForBranch(branchId),
      _db.diningTablesDao.getAllDiningTablesForBranch(branchId),
      _orderRepo.filterOrders(
        orderType: 'dine_in',
        excludeStatusAnyOf: const ['completed', 'cancelled'],
      ),
    ]);
    final floors = triple[0] as List<DiningFloor>;
    final allTables = triple[1] as List<DiningTable>;
    final orders = triple[2] as List<Order>;
    final active = List<Order>.from(orders);
    sortOrdersNewestFirst(active);

    final codeToFloors = <String, Set<int>>{};
    for (final t in allTables) {
      codeToFloors.putIfAbsent(_tableKey(t.code), () => {}).add(t.floorId);
    }

    final floorIndex = floors.isEmpty ? 0 : priorFloorIndex.clamp(0, floors.length - 1);
    List<DiningTable> tables = [];
    if (floors.isNotEmpty) {
      tables = await _db.diningTablesDao.getTablesByFloorForBranch(floors[floorIndex].id, branchId);
    }

    if (!mounted) return;
    setState(() {
      _floors = floors;
      _tables = tables;
      _activeDineInOrders = active;
      _tableCodeToFloorIds = codeToFloors;
      _selectedFloorIndex = floorIndex;
      _loading = false;
      _rebuildAllocationMaps();
    });
  }

  /// `floorId|rest` prefix from counter; strip before parsing table code / pax.
  int? _extractLeadingFloorId(String? referenceNumber) {
    final v = (referenceNumber ?? '').trim();
    final m = RegExp(r'^(\d+)\|(.+)$').firstMatch(v);
    if (m == null) return null;
    return int.tryParse(m.group(1)!);
  }

  String _stripLeadingFloorId(String? referenceNumber) {
    final v = (referenceNumber ?? '').trim();
    final m = RegExp(r'^(\d+)\|(.+)$').firstMatch(v);
    if (m != null) return m.group(2)!.trim();
    return v;
  }

  void _rebuildAllocationMaps() {
    final counts = <String, int>{};
    final paxPerTable = <String, int>{};
    final blockedSeats = <String, Set<int>>{};
    if (_floors.isEmpty || _selectedFloorIndex < 0 || _selectedFloorIndex >= _floors.length) {
      _activeOrdersPerTable = counts;
      _occupiedPaxPerTable = paxPerTable;
      _blockedSeatsPerTable = blockedSeats;
      return;
    }
    final floorId = _floors[_selectedFloorIndex].id;
    final keysOnFloor = _tables.map((t) => _tableKey(t.code)).toSet();
    final codeToChairs = {for (final t in _tables) _tableKey(t.code): t.chairs};

    for (final o in _activeDineInOrders) {
      final ref = DineInRefParser.dineInAnchorForMatching(o);
      if (ref == null || ref.isEmpty) continue;
      final leadFloor = _extractLeadingFloorId(ref);
      final normalized = _stripLeadingFloorId(ref);
      final tableCode = _tableKey(_extractTableCode(normalized));
      if (tableCode.isEmpty || !keysOnFloor.contains(tableCode)) continue;

      if (leadFloor != null) {
        if (leadFloor != floorId) continue;
      } else {
        final floorsForCode = _tableCodeToFloorIds[tableCode];
        if (floorsForCode == null || floorsForCode.length != 1 || floorsForCode.first != floorId) {
          continue;
        }
      }

      counts[tableCode] = (counts[tableCode] ?? 0) + 1;
      var pax = _extractPaxFromReference(normalized);
      if (pax <= 0) pax = 1;
      paxPerTable[tableCode] = (paxPerTable[tableCode] ?? 0) + pax;
    }

    for (final code in keysOnFloor) {
      final chairCap = codeToChairs[code] ?? 4;
      final ordersHere = _activeDineInOrders.where((o) {
        final ref = DineInRefParser.dineInAnchorForMatching(o);
        if (ref == null || ref.isEmpty) return false;
        final leadFloor = _extractLeadingFloorId(ref);
        final normalized = _stripLeadingFloorId(ref);
        final c = _tableKey(_extractTableCode(normalized));
        if (c != code || !keysOnFloor.contains(c)) return false;
        if (leadFloor != null) {
          if (leadFloor != floorId) return false;
        } else {
          final floorsForCode = _tableCodeToFloorIds[c];
          if (floorsForCode == null || floorsForCode.length != 1 || floorsForCode.first != floorId) {
            return false;
          }
        }
        return true;
      }).toList();
      if (_seatHandlingEnabled) {
        blockedSeats[code] = DineInRefParser.computeBlockedSeatsForTable(
          chairCapacity: chairCap,
          ordersOnTable: ordersHere,
        );
      } else {
        blockedSeats[code] = {};
      }
    }

    _activeOrdersPerTable = counts;
    _occupiedPaxPerTable = paxPerTable;
    _blockedSeatsPerTable = blockedSeats;
  }

  /// Matches floor-plan occupancy (same as grid cards).
  int _occupiedPaxForTable(DiningTable t) {
    final tableCode = _tableKey(t.code);
    if (_seatHandlingEnabled) {
      return (_blockedSeatsPerTable[tableCode]?.length ?? 0).clamp(0, t.chairs);
    }
    final activeOrders = _activeOrdersPerTable[tableCode] ?? 0;
    final rawPax = _occupiedPaxPerTable[tableCode] ?? 0;
    var occupiedPax = rawPax.clamp(0, t.chairs);
    if (occupiedPax == 0 && activeOrders > 0) {
      occupiedPax = activeOrders.clamp(1, t.chairs);
    }
    return occupiedPax;
  }

  String _extractTableCode(String? referenceNumber) {
    final v = _stripLeadingFloorId(referenceNumber);
    if (v.isEmpty) return '';
    if (v.contains('|')) {
      return v.split('|').first.trim().toUpperCase();
    }
    return v.toUpperCase();
  }

  /// Parses `T1 | 3 pax` → 3; avoids matching digits inside `T1` when possible.
  int _extractPaxFromReference(String? referenceNumber) {
    final v = _stripLeadingFloorId(referenceNumber);
    if (v.isEmpty || !v.contains('|')) return 0;
    final after = v.split('|').skip(1).join('|').trim();
    final paxM = RegExp(r'(\d+)\s*pax', caseSensitive: false).firstMatch(after);
    if (paxM != null) return int.tryParse(paxM.group(1)!) ?? 0;
    final m = RegExp(r'(\d+)').firstMatch(after);
    if (m == null) return 0;
    return int.tryParse(m.group(1)!) ?? 0;
  }

  Future<void> _changeFloor(int index) async {
    if (index < 0 || index >= _floors.length) return;
    final floorId = _floors[index].id;
    final session = await _db.sessionDao.getActiveSession();
    final branchId = session?.branchId ?? 1;
    final tables = await _db.diningTablesDao.getTablesByFloorForBranch(floorId, branchId);
    if (!mounted) return;
    setState(() {
      _selectedFloorIndex = index;
      _tables = tables;
      _rebuildAllocationMaps();
    });
  }

  Future<void> _openCounterForTable(DiningTable table) async {
    if (_seatHandlingEnabled) {
      final blocked = _blockedSeatsPerTable[_tableKey(table.code)] ?? {};
      if (blocked.length >= table.chairs) {
        CustomSnackBar.showWarning(
          message: 'All seats are occupied. Complete or clear orders before adding a new one.',
          context: context,
        );
        return;
      }
    }
    final reference = DineInRefParser.buildTableOnlyReference(table.floorId, table.code);
    AppNavigator.pushNamed(
      Routes.counter,
      args: {
        'orderType': 'dine_in',
        'referenceNumber': reference,
        'fromDineIn': true,
      },
    ).then((_) => _load());
  }

  /// Active dine-in orders whose reference maps to this table on the current floor (same rules as allocation).
  List<Order> _ordersForTable(DiningTable table) {
    if (_floors.isEmpty || _selectedFloorIndex < 0 || _selectedFloorIndex >= _floors.length) {
      return [];
    }
    final floorId = _floors[_selectedFloorIndex].id;
    final keysOnFloor = _tables.map((t) => _tableKey(t.code)).toSet();
    final tableCode = _tableKey(table.code);

    final list = _activeDineInOrders.where((o) {
      final ref = DineInRefParser.dineInAnchorForMatching(o);
      if (ref == null || ref.isEmpty) return false;
      final leadFloor = _extractLeadingFloorId(ref);
      final normalized = _stripLeadingFloorId(ref);
      final code = _tableKey(_extractTableCode(normalized));
      if (code != tableCode || !keysOnFloor.contains(code)) return false;

      if (leadFloor != null) {
        if (leadFloor != floorId) return false;
      } else {
        final floorsForCode = _tableCodeToFloorIds[tableCode];
        if (floorsForCode == null || floorsForCode.length != 1 || floorsForCode.first != floorId) {
          return false;
        }
      }
      return true;
    }).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> _showTableOrders(DiningTable table) async {
    final orders = _ordersForTable(table);
    final useBottomSheet = MediaQuery.sizeOf(context).width < 900;

    Future<void> openOrder(Order order) async {
      Navigator.of(context).pop();
      await AppNavigator.pushNamed(
        Routes.counter,
        args: {
          'orderId': order.id,
          'orderType': 'dine_in',
          'fromDineIn': true,
        },
      );
      if (mounted) await _load();
    }

    final panel = _DineInTableOrdersPanel(
      tableCode: table.code,
      orders: orders,
      onOrderTap: openOrder,
    );

    if (!mounted) return;
    if (useBottomSheet) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) => SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.62,
            child: panel,
          ),
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440, maxHeight: 520),
            child: panel,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: 'Dine In',
      appBarScreen: 'take_away',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ColoredBox(
              color: AppColors.scaffoldColor,
              child: RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dine in allocation', style: AppStyles.getSemiBoldTextStyle(fontSize: 19)),
                      const SizedBox(height: 8),
                      _legend(),
                      const SizedBox(height: 8),
                      _floorTabs(),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (_, c) {
                          const spacing = 8.0;
                          const targetVisibleTables = 12;
                          final screenHeight = MediaQuery.sizeOf(context).height;
                          final availableForGrid = (screenHeight - 250).clamp(320.0, 900.0);
                          final cols = ((c.maxWidth + spacing) / (150 + spacing)).floor().clamp(2, 6);
                          final rows = (targetVisibleTables / cols).ceil();
                          final cardWidth = (c.maxWidth - (cols - 1) * spacing) / cols;
                          final cardHeight = ((availableForGrid - (rows - 1) * spacing) / rows).clamp(128.0, 210.0);
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _tables.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: cols,
                              crossAxisSpacing: spacing,
                              mainAxisSpacing: spacing,
                              childAspectRatio: cardWidth / cardHeight,
                            ),
                            itemBuilder: (_, i) {
                              final t = _tables[i];
                              final tableCode = _tableKey(t.code);
                              final activeOrders = _activeOrdersPerTable[tableCode] ?? 0;
                              final blocked = _blockedSeatsPerTable[tableCode] ?? {};
                              final occupiedPax = _occupiedPaxForTable(t);
                              final canAddOrder = _seatHandlingEnabled ? blocked.length < t.chairs : true;
                              return _TableCard(
                                key: ValueKey('dine_table_${t.id}_${blocked.length}'),
                                code: t.code,
                                chairs: t.chairs,
                                seatHandlingEnabled: _seatHandlingEnabled,
                                blockedSeatNumbers: blocked,
                                contiguousOccupiedWhenNoSeatHandling: occupiedPax,
                                activeOrders: activeOrders,
                                canAddOrder: canAddOrder,
                                onViewOrders: () => _showTableOrders(t),
                                onAdd: () => _openCounterForTable(t),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _legend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _LegendChip(
          label: 'Ordered seat',
          color: _chairSeatOrdered,
          showChairAsset: true,
          chairOrdered: true,
        ),
        _LegendChip(
          label: 'Available seat',
          color: _chairSeatAvailable,
          showChairAsset: true,
          chairOrdered: false,
        ),
      ],
    );
  }

  Widget _floorTabs() {
    if (_floors.isEmpty) {
      return Text(
        'No floor data synced yet.',
        style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.hintFontColor),
      );
    }
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _floors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final selected = i == _selectedFloorIndex;
          return ChoiceChip(
            label: Text(_floors[i].name),
            selected: selected,
            onSelected: (_) => _changeFloor(i),
            selectedColor: AppColors.primaryColor.withValues(alpha: 0.12),
            labelStyle: AppStyles.getMediumTextStyle(
              fontSize: 12,
              color: selected ? AppColors.primaryColor : AppColors.textColor,
            ),
            side: BorderSide(
              color: selected ? AppColors.primaryColor.withValues(alpha: 0.25) : AppColors.divider,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            backgroundColor: Colors.white,
          );
        },
      ),
    );
  }
}

/// Lists active dine-in orders for one table; used inside a bottom sheet (mobile) or dialog (wide).
class _DineInTableOrdersPanel extends StatelessWidget {
  const _DineInTableOrdersPanel({
    required this.tableCode,
    required this.orders,
    required this.onOrderTap,
  });

  final String tableCode;
  final List<Order> orders;
  final ValueChanged<Order> onOrderTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Orders — Table $tableCode',
                  style: AppStyles.getSemiBoldTextStyle(fontSize: 18),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: orders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No active orders on this table.',
                      style: AppStyles.getRegularTextStyle(fontSize: 14, color: AppColors.hintFontColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                  itemBuilder: (context, i) {
                    final o = orders[i];
                    final ref = DineInRefParser.stripLeadingFloorId(o.referenceNumber).trim();
                    return ListTile(
                      leading: Icon(Icons.receipt_long_outlined, color: AppColors.primaryColor),
                      title: Text(
                        o.invoiceNumber,
                        style: AppStyles.getSemiBoldTextStyle(fontSize: 14),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            [
                              o.status.toUpperCase(),
                              RuntimeAppSettings.money(o.finalAmount),
                              if (ref.isNotEmpty) ref,
                            ].join(' · '),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.hintFontColor),
                          ),
                          const SizedBox(height: 2),
                          RelativeTimeText(
                            at: o.createdAt,
                            style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.hintFontColor),
                          ),
                        ],
                      ),
                      onTap: () => onOrderTap(o),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    super.key,
    required this.code,
    required this.chairs,
    required this.seatHandlingEnabled,
    required this.blockedSeatNumbers,
    required this.contiguousOccupiedWhenNoSeatHandling,
    required this.activeOrders,
    required this.canAddOrder,
    required this.onViewOrders,
    required this.onAdd,
  });

  final String code;
  final int chairs;
  final bool seatHandlingEnabled;
  final Set<int> blockedSeatNumbers;
  final int contiguousOccupiedWhenNoSeatHandling;
  final int activeOrders;
  final bool canAddOrder;
  final VoidCallback onViewOrders;
  final VoidCallback onAdd;

  static const Color _cardAccentFree = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final tableFullyOccupied = chairs > 0 &&
        (seatHandlingEnabled
            ? blockedSeatNumbers.length >= chairs
            : contiguousOccupiedWhenNoSeatHandling >= chairs);
    final (topCount, bottomCount) = _chairRowsSplit(chairs);
    final contiguousN = contiguousOccupiedWhenNoSeatHandling.clamp(0, chairs);
    final tableW = _tableWidthForChairs(chairs);

    final hasActiveOrders = activeOrders > 0;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: canAddOrder
            ? () {
                onAdd();
              }
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _cardAccentFree.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: LayoutBuilder(
              builder: (context, c) {
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: c.maxWidth),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (hasActiveOrders) ...[
                          Text(
                            '$activeOrders active order${activeOrders > 1 ? 's' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppStyles.getSemiBoldTextStyle(fontSize: 12, color: AppColors.primaryColor),
                          ),
                          const SizedBox(height: 6),
                        ],
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _cardAccentFree.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  code,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppStyles.getSemiBoldTextStyle(fontSize: 11, color: _cardAccentFree),
                                ),
                              ),
                            ),
                            Tooltip(
                              message: 'Orders on this table',
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                icon: Icon(Icons.receipt_long_outlined, size: 17, color: AppColors.primaryColor),
                                onPressed: onViewOrders,
                              ),
                            ),
                            Tooltip(
                              message: !seatHandlingEnabled ? 'Add customer order' : (canAddOrder ? 'Add customer order' : 'All seats occupied'),
                              child: IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                icon: Icon(canAddOrder ? Icons.add_circle_outline : Icons.block, size: 17),
                                color: canAddOrder ? AppColors.primaryColor : AppColors.hintFontColor,
                                onPressed: canAddOrder
                                    ? () {
                                        onAdd();
                                      }
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (topCount > 0)
                          _ChairRow(
                            startSeatIndex: 0,
                            count: topCount,
                            seatHandlingEnabled: seatHandlingEnabled,
                            occupiedSeatNumbers: blockedSeatNumbers,
                            contiguousOccupiedCount: contiguousN,
                            facingDown: true,
                          ),
                        if (topCount > 0) const SizedBox(height: 4),
                        Container(
                          height: 32,
                          width: tableW,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: tableFullyOccupied
                                ? AppColors.danger
                                : (hasActiveOrders
                                    ? AppColors.primaryColor.withValues(alpha: 0.14)
                                    : _cardAccentFree.withValues(alpha: 0.13)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: tableFullyOccupied
                                  ? AppColors.danger.withValues(alpha: 0.85)
                                  : (hasActiveOrders
                                      ? AppColors.primaryColor.withValues(alpha: 0.45)
                                      : _cardAccentFree.withValues(alpha: 0.35)),
                              width: (tableFullyOccupied || hasActiveOrders) ? 2 : 1,
                            ),
                          ),
                          child: (hasActiveOrders || tableFullyOccupied)
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'OCCUPIED',
                                      maxLines: 1,
                                      softWrap: false,
                                      style: AppStyles.getSemiBoldTextStyle(
                                        fontSize: 11,
                                        color: tableFullyOccupied ? Colors.white : AppColors.primaryColor,
                                      ).copyWith(letterSpacing: 0.6),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        if (bottomCount > 0) const SizedBox(height: 4),
                        if (bottomCount > 0)
                          _ChairRow(
                            startSeatIndex: topCount,
                            count: bottomCount,
                            seatHandlingEnabled: seatHandlingEnabled,
                            occupiedSeatNumbers: blockedSeatNumbers,
                            contiguousOccupiedCount: contiguousN,
                            facingDown: false,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Chairs above/below the table. Seat numbers are 1-based globally (top row then bottom row).
class _ChairRow extends StatelessWidget {
  const _ChairRow({
    required this.startSeatIndex,
    required this.count,
    required this.seatHandlingEnabled,
    required this.occupiedSeatNumbers,
    required this.contiguousOccupiedCount,
    required this.facingDown,
  });

  final int startSeatIndex;
  final int count;
  final bool seatHandlingEnabled;
  final Set<int> occupiedSeatNumbers;
  final int contiguousOccupiedCount;
  final bool facingDown;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(count, (i) {
                final globalIndex0 = startSeatIndex + i;
                final seatNo = globalIndex0 + 1;
                final ordered = seatHandlingEnabled
                    ? occupiedSeatNumbers.contains(seatNo)
                    : globalIndex0 < contiguousOccupiedCount;
                return _ChairSeat(ordered: ordered, facingDown: facingDown);
              }),
            ),
          ),
        );
      },
    );
  }
}

class _ChairSeat extends StatelessWidget {
  const _ChairSeat({required this.ordered, required this.facingDown});

  final bool ordered;
  final bool facingDown;

  @override
  Widget build(BuildContext context) {
    const size = 20.0;
    final accent = ordered ? _chairSeatOrdered : _chairSeatAvailable;
    Widget img = ColorFiltered(
      colorFilter: ColorFilter.mode(accent, BlendMode.srcIn),
      child: Image.asset(
        _kChairAsset,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
    if (!facingDown) {
      img = Transform.rotate(angle: 3.14159, child: img);
    }
    return Container(
      width: size + 10,
      height: size + 6,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: ordered ? 0.12 : 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent, width: ordered ? 2.5 : 2),
      ),
      child: img,
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.label,
    required this.color,
    this.showChairAsset = false,
    this.chairOrdered = false,
  });

  final String label;
  final Color color;
  final bool showChairAsset;
  final bool chairOrdered;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showChairAsset)
            SizedBox(
              width: 32,
              height: 28,
              child: _ChairSeat(
                ordered: chairOrdered,
                facingDown: true,
              ),
            )
          else
            Container(
              height: 9,
              width: 9,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
            ),
          const SizedBox(width: 8),
          Text(label, style: AppStyles.getMediumTextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
