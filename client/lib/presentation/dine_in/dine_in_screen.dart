import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/features/orders/data/hub_orders_live_sync.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/app/routes.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/settings/app_settings_prefs.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/core/utils/order_list_sort.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/core/debug/agent_debug_log.dart';
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

  /// When false, Dine In does not allocate seats or cap orders by chair count.
  bool _seatHandlingEnabled = true;
  int _selectedFloorIndex = 0;
  List<DiningFloor> _floors = [];
  List<DiningTable> _tables = [];
  List<Order> _activeDineInOrders = [];

  /// Table code → floor ids that contain that code (for legacy refs without floor prefix).
  Map<String, Set<int>> _tableCodeToFloorIds = {};
  Map<String, int> _activeOrdersPerTable = {};

  /// Sum of pax from active orders on each table (from `CODE | N pax` ref).
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
    final seatHandling = await AppSettingsPrefs.getDineInSeatHandlingEnabled();
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
      _seatHandlingEnabled = seatHandling;
      _floors = floors;
      _tables = tables;
      _activeDineInOrders = active;
      _tableCodeToFloorIds = codeToFloors;
      _selectedFloorIndex = floorIndex;
      _loading = false;
      _rebuildAllocationMaps();
    });
    // #region agent log
    final floorIds = floors.map((f) => f.id).toList();
    final tableCodes = tables.map((t) => '${t.floorId}:${t.code}').toList();
    final orderDiag = <Map<String, Object?>>[];
    for (final o in active.take(12)) {
      final routing = DineInRefParser.dineInRoutingAnchorForMatching(o);
      orderDiag.add(<String, Object?>{
        'id': o.id,
        'invoice': o.invoiceNumber,
        'status': o.status,
        'orderType': o.orderType,
        'staffRef': o.referenceNumber,
        'routingAnchor': routing,
        'routingTableCode': routing == null
            ? null
            : DineInRefParser.tableKey(
                DineInRefParser.extractTableCode(DineInRefParser.stripLeadingFloorId(routing)),
              ),
        'hubHasAnchor': DineInRefParser.dineInAnchorFromHubMetadata(o.hubMetadata) != null,
      });
    }
    agentDebugLog(
      hypothesisId: 'H_load',
      location: 'dine_in_screen.dart:_load',
      message: 'floor_plan_reload',
      data: <String, Object?>{
        'branchId': branchId,
        'activeCount': active.length,
        'floorIds': floorIds,
        'selectedFloorId': floors.isNotEmpty ? floors.first.id : null,
        'tableCodesOnFloor': tableCodes,
        'allocationKeys': _activeOrdersPerTable.keys.toList(),
        'allocationCounts': _activeOrdersPerTable,
        'orders': orderDiag,
      },
    );
    // #endregion
  }

  void _rebuildAllocationMaps() {
    final counts = <String, int>{};
    final paxPerTable = <String, int>{};
    if (_floors.isEmpty || _selectedFloorIndex < 0 || _selectedFloorIndex >= _floors.length) {
      _activeOrdersPerTable = counts;
      _occupiedPaxPerTable = paxPerTable;
      return;
    }
    final floorId = _floors[_selectedFloorIndex].id;

    for (final t in _tables) {
      final tableCode = _tableKey(t.code);
      for (final o in _activeDineInOrders) {
        if (!DineInRefParser.orderMatchesFloorTable(o, floorId, tableCode, _tableCodeToFloorIds)) {
          continue;
        }
        counts[tableCode] = (counts[tableCode] ?? 0) + 1;
        final ref = DineInRefParser.dineInRoutingAnchorForMatching(o);
        var pax = DineInRefParser.extractPaxFromReference(ref);
        if (pax <= 0) pax = 1;
        paxPerTable[tableCode] = (paxPerTable[tableCode] ?? 0) + pax;
      }
    }

    _activeOrdersPerTable = counts;
    _occupiedPaxPerTable = paxPerTable;

    // #region agent log
    if (_activeDineInOrders.isNotEmpty && counts.isEmpty) {
      final failSamples = <Map<String, Object?>>[];
      for (final o in _activeDineInOrders.take(6)) {
        final anchor = DineInRefParser.dineInRoutingAnchorForMatching(o);
        final lead = anchor == null ? null : DineInRefParser.extractLeadingFloorId(anchor);
        final code = anchor == null
            ? null
            : DineInRefParser.tableKey(
                DineInRefParser.extractTableCode(DineInRefParser.stripLeadingFloorId(anchor)),
              );
        failSamples.add(<String, Object?>{
          'id': o.id,
          'invoice': o.invoiceNumber,
          'anchor': anchor,
          'leadFloor': lead,
          'parsedTableCode': code,
          'floorsForCode': code == null ? null : _tableCodeToFloorIds[code]?.toList(),
          'viewFloorId': floorId,
        });
      }
      agentDebugLog(
        hypothesisId: 'H_match',
        location: 'dine_in_screen.dart:_rebuildAllocationMaps',
        message: 'orders_loaded_but_no_table_match',
        data: <String, Object?>{
          'floorId': floorId,
          'activeOrders': _activeDineInOrders.length,
          'tablesOnFloor': _tables.map((t) => t.code).toList(),
          'failSamples': failSamples,
        },
      );
    }
    // #endregion
  }

  /// Matches floor-plan occupancy (same as grid cards).
  int _occupiedPaxForTable(DiningTable t) {
    final tableCode = _tableKey(t.code);
    final activeOrders = _activeOrdersPerTable[tableCode] ?? 0;
    final rawPax = _occupiedPaxPerTable[tableCode] ?? 0;
    var occupiedPax = rawPax.clamp(0, t.chairs);
    if (occupiedPax == 0 && activeOrders > 0) {
      occupiedPax = activeOrders.clamp(1, t.chairs);
    }
    return occupiedPax;
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
    late final String reference;
    if (_seatHandlingEnabled) {
      final occupiedPax = _occupiedPaxForTable(table);
      if (occupiedPax >= table.chairs) {
        CustomSnackBar.showWarning(
          message: 'All seats are occupied. Complete or clear orders before adding a new one.',
          context: context,
        );
        return;
      }
      final pax = await _showChairAssignmentDialog(
        chairs: table.chairs,
        occupiedSeats: occupiedPax,
        tableLabel: table.code,
      );
      if (pax == null || pax < 1 || !mounted) return;
      reference = '${table.floorId}|${table.code} | $pax pax';
    } else {
      reference = '${table.floorId}|${table.code}';
    }
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
    final tableCode = _tableKey(table.code);

    final list = _activeDineInOrders
        .where((o) => DineInRefParser.orderMatchesFloorTable(o, floorId, tableCode, _tableCodeToFloorIds))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> _showTableOrders(DiningTable table) async {
    final orders = _ordersForTable(table);
    // #region agent log
    final floorId = _floors.isNotEmpty ? _floors[_selectedFloorIndex].id : null;
    agentDebugLog(
      hypothesisId: 'H_view',
      location: 'dine_in_screen.dart:_showTableOrders',
      message: 'view_table_orders',
      data: <String, Object?>{
        'tableCode': table.code,
        'floorId': floorId,
        'matchedCount': orders.length,
        'matchedInvoices': orders.map((o) => o.invoiceNumber).toList(),
        'activeOrdersTotal': _activeDineInOrders.length,
        'allocationForTable': _activeOrdersPerTable[_tableKey(table.code)],
      },
    );
    // #endregion
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

  Future<int?> _showChairAssignmentDialog({
    required int chairs,
    required int occupiedSeats,
    required String tableLabel,
  }) {
    return showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ChairAssignmentDialog(
        chairs: chairs,
        occupiedSeats: occupiedSeats,
        tableLabel: tableLabel,
      ),
    );
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
                              final occupiedPax = _occupiedPaxForTable(t);
                              final canAddOrder = _seatHandlingEnabled ? occupiedPax < t.chairs : true;
                              return _TableCard(
                                key: ValueKey('dine_table_${t.id}_$occupiedPax'),
                                code: t.code,
                                chairs: t.chairs,
                                occupiedPax: occupiedPax,
                                activeOrders: activeOrders,
                                canAddOrder: canAddOrder,
                                seatHandlingEnabled: _seatHandlingEnabled,
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

/// Modal: one chair asset per seat, checkboxes on free seats, "select all available".
class _ChairAssignmentDialog extends StatefulWidget {
  const _ChairAssignmentDialog({
    required this.chairs,
    required this.occupiedSeats,
    required this.tableLabel,
  });

  final int chairs;
  final int occupiedSeats;
  final String tableLabel;

  @override
  State<_ChairAssignmentDialog> createState() => _ChairAssignmentDialogState();
}

class _ChairAssignmentDialogState extends State<_ChairAssignmentDialog> {
  late List<bool> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<bool>.filled(widget.chairs, false);
  }

  bool _isOccupied(int index) => index < widget.occupiedSeats;

  int get _freeCount {
    var n = 0;
    for (var i = 0; i < widget.chairs; i++) {
      if (!_isOccupied(i)) n++;
    }
    return n;
  }

  int get _selectedPax {
    var n = 0;
    for (var i = 0; i < widget.chairs; i++) {
      if (!_isOccupied(i) && _selected[i]) n++;
    }
    return n;
  }

  bool? get _selectAllValue {
    if (_freeCount == 0) return false;
    var on = 0;
    for (var i = 0; i < widget.chairs; i++) {
      if (!_isOccupied(i) && _selected[i]) on++;
    }
    if (on == 0) return false;
    if (on == _freeCount) return true;
    return null;
  }

  void _applySelectAll(bool on) {
    setState(() {
      for (var i = 0; i < widget.chairs; i++) {
        if (!_isOccupied(i)) _selected[i] = on;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Assign seats', style: AppStyles.getSemiBoldTextStyle(fontSize: 18)),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Table ${widget.tableLabel} — choose seats for this order (red = already in use).',
                style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.hintFontColor),
              ),
              const SizedBox(height: 12),
              if (_freeCount > 0)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text('Select all available seats', style: AppStyles.getMediumTextStyle(fontSize: 14)),
                  tristate: true,
                  value: _selectAllValue,
                  onChanged: (v) {
                    if (v == true) {
                      _applySelectAll(true);
                    } else {
                      _applySelectAll(false);
                    }
                  },
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: List.generate(widget.chairs, (i) {
                  final occ = _isOccupied(i);
                  return _ChairPickTile(
                    seatNumber: i + 1,
                    occupied: occ,
                    selected: occ ? false : _selected[i],
                    onChanged: occ
                        ? null
                        : (v) => setState(() {
                              _selected[i] = v ?? false;
                            }),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _selectedPax < 1 ? null : () => Navigator.pop(context, _selectedPax),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Open counter'),
        ),
      ],
    );
  }
}

class _ChairPickTile extends StatelessWidget {
  const _ChairPickTile({
    required this.seatNumber,
    required this.occupied,
    required this.selected,
    required this.onChanged,
  });

  final int seatNumber;
  final bool occupied;
  final bool selected;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    const imgSize = 36.0;
    final tint = occupied ? _chairSeatOrdered : (selected ? AppColors.primaryColor : _chairSeatAvailable);
    return SizedBox(
      width: 86,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: occupied ? 0.85 : 1,
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
              child: Image.asset(_kChairAsset, width: imgSize, height: imgSize, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            occupied ? 'In use' : 'Seat $seatNumber',
            style: AppStyles.getRegularTextStyle(fontSize: 10, color: occupied ? _chairSeatOrdered : AppColors.hintFontColor),
          ),
          if (occupied)
            const SizedBox(height: 20)
          else
            Checkbox(
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              value: selected,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    super.key,
    required this.code,
    required this.chairs,
    required this.occupiedPax,
    required this.activeOrders,
    required this.canAddOrder,
    required this.seatHandlingEnabled,
    required this.onViewOrders,
    required this.onAdd,
  });

  final String code;
  final int chairs;

  /// Guests / pax from orders (clamped to [chairs]); first N seats show as ordered (red), rest available (green).
  final int occupiedPax;
  final int activeOrders;
  final bool canAddOrder;
  final bool seatHandlingEnabled;
  final VoidCallback onViewOrders;
  final VoidCallback onAdd;

  static const Color _cardAccentFree = Color(0xFF64748B);

  @override
  Widget build(BuildContext context) {
    final showOccupiedOnTable = activeOrders > 0;
    final (topCount, bottomCount) = _chairRowsSplit(chairs);
    final occupiedSeats = occupiedPax.clamp(0, chairs);
    final tableW = _tableWidthForChairs(chairs);

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
                  occupiedSeats: occupiedSeats,
                  facingDown: true,
                ),
              if (topCount > 0) const SizedBox(height: 4),
              Container(
                height: 44,
                width: tableW,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: showOccupiedOnTable ? AppColors.danger : _cardAccentFree.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: showOccupiedOnTable ? AppColors.danger.withValues(alpha: 0.85) : _cardAccentFree.withValues(alpha: 0.35),
                    width: showOccupiedOnTable ? 1.5 : 1,
                  ),
                ),
                child: showOccupiedOnTable
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Occupied',
                                maxLines: 1,
                                softWrap: false,
                                style: AppStyles.getSemiBoldTextStyle(fontSize: 11, color: Colors.white),
                              ),
                              Text(
                                '$activeOrders active',
                                maxLines: 1,
                                softWrap: false,
                                style: AppStyles.getMediumTextStyle(fontSize: 10, color: Colors.white),
                              ),
                            ],
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
                  occupiedSeats: occupiedSeats,
                  facingDown: false,
                ),
              if (seatHandlingEnabled && activeOrders > 0 && canAddOrder)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${chairs - occupiedPax} seat${chairs - occupiedPax == 1 ? '' : 's'} free',
                    style: AppStyles.getRegularTextStyle(fontSize: 10, color: AppColors.hintFontColor),
                  ),
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

/// Chairs above/below the table. Seat indices are global: top row 0..top-1, then bottom row.
class _ChairRow extends StatelessWidget {
  const _ChairRow({
    required this.startSeatIndex,
    required this.count,
    required this.occupiedSeats,
    required this.facingDown,
  });

  final int startSeatIndex;
  final int count;
  final int occupiedSeats;
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
                final seatIndex = startSeatIndex + i;
                final ordered = seatIndex < occupiedSeats;
                final tint = ordered ? _chairSeatOrdered : _chairSeatAvailable;
                return _ChairSeat(tint: tint, facingDown: facingDown);
              }),
            ),
          ),
        );
      },
    );
  }
}

class _ChairSeat extends StatelessWidget {
  const _ChairSeat({required this.tint, required this.facingDown});

  final Color tint;
  final bool facingDown;

  @override
  Widget build(BuildContext context) {
    const size = 22.0;
    Widget img = ColorFiltered(
      colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
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
    return SizedBox(width: size + 4, height: size, child: Center(child: img));
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
              width: 18,
              height: 18,
              child: _ChairSeat(
                tint: chairOrdered ? _chairSeatOrdered : _chairSeatAvailable,
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
