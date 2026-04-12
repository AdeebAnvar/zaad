import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/app/routes.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/settings/app_settings_prefs.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final seatHandling = await AppSettingsPrefs.getDineInSeatHandlingEnabled();
    final floors = await _db.diningTablesDao.getFloors();
    final allTables = await _db.diningTablesDao.getAllDiningTables();
    final orders = await _orderRepo.filterOrders(orderType: 'dine_in');
    final active = orders.where((o) {
      final s = o.status.toLowerCase();
      return s != 'completed' && s != 'cancelled';
    }).toList();

    final codeToFloors = <String, Set<int>>{};
    for (final t in allTables) {
      codeToFloors.putIfAbsent(_tableKey(t.code), () => {}).add(t.floorId);
    }

    List<DiningTable> tables = [];
    if (floors.isNotEmpty) {
      tables = await _db.diningTablesDao.getTablesByFloor(floors.first.id);
    }

    if (!mounted) return;
    setState(() {
      _seatHandlingEnabled = seatHandling;
      _floors = floors;
      _tables = tables;
      _activeDineInOrders = active;
      _tableCodeToFloorIds = codeToFloors;
      _selectedFloorIndex = 0;
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
    if (_floors.isEmpty || _selectedFloorIndex < 0 || _selectedFloorIndex >= _floors.length) {
      _activeOrdersPerTable = counts;
      _occupiedPaxPerTable = paxPerTable;
      return;
    }
    final floorId = _floors[_selectedFloorIndex].id;
    final keysOnFloor = _tables.map((t) => _tableKey(t.code)).toSet();

    for (final o in _activeDineInOrders) {
      final ref = o.referenceNumber;
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

    _activeOrdersPerTable = counts;
    _occupiedPaxPerTable = paxPerTable;
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
    final tables = await _db.diningTablesDao.getTablesByFloor(floorId);
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
    final keysOnFloor = _tables.map((t) => _tableKey(t.code)).toSet();
    final tableCode = _tableKey(table.code);

    final list = _activeDineInOrders.where((o) {
      final ref = o.referenceNumber;
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
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 900;
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dine in allocation', style: AppStyles.getSemiBoldTextStyle(fontSize: 24)),
                      const SizedBox(height: 14),
                      _legend(),
                      const SizedBox(height: 14),
                      _floorTabs(),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (_, c) {
                          final cols = c.maxWidth > 1400
                              ? 5
                              : c.maxWidth > 1100
                                  ? 4
                                  : c.maxWidth > 800
                                      ? 3
                                      : 2;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _tables.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isMobile ? 2 : cols,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: isMobile ? 0.65 : 1.05,
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
      height: 42,
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
              fontSize: 13,
              color: selected ? AppColors.primaryColor : AppColors.textColor,
            ),
            side: BorderSide(
              color: selected ? AppColors.primaryColor.withValues(alpha: 0.25) : AppColors.divider,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                    final ref = (o.referenceNumber ?? '').trim();
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
                              '₹ ${o.finalAmount.toStringAsFixed(2)}',
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
    final showOccupiedOnTable = seatHandlingEnabled
        ? (chairs > 0 && !canAddOrder)
        : (activeOrders > 0);
    final (topCount, bottomCount) = _chairRowsSplit(chairs);
    final occupiedSeats = occupiedPax.clamp(0, chairs);
    final tableW = _tableWidthForChairs(chairs);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: canAddOrder
            ? () {
                onAdd();
              }
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _cardAccentFree.withValues(alpha: 0.35), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _cardAccentFree.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.getSemiBoldTextStyle(fontSize: 12, color: _cardAccentFree),
                  ),
                ),
              ),
              Tooltip(
                message: 'Orders on this table',
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Icon(Icons.receipt_long_outlined, size: 22, color: AppColors.primaryColor),
                  onPressed: onViewOrders,
                ),
              ),
              Tooltip(
                message: !seatHandlingEnabled
                    ? 'Add customer order'
                    : (canAddOrder ? 'Add customer order' : 'All seats occupied'),
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Icon(canAddOrder ? Icons.add_circle_outline : Icons.block, size: 22),
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
          const SizedBox(height: 8),
          if (topCount > 0)
            _ChairRow(
              startSeatIndex: 0,
              count: topCount,
              occupiedSeats: occupiedSeats,
              facingDown: true,
            ),
          if (topCount > 0) const SizedBox(height: 6),
          Container(
            height: 44,
            width: tableW,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: showOccupiedOnTable
                  ? AppColors.danger
                  : _cardAccentFree.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: showOccupiedOnTable
                    ? AppColors.danger.withValues(alpha: 0.85)
                    : _cardAccentFree.withValues(alpha: 0.35),
              ),
            ),
            child: showOccupiedOnTable
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Occupied',
                        maxLines: 1,
                        softWrap: false,
                        style: AppStyles.getSemiBoldTextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  )
                : null,
          ),
          if (bottomCount > 0) const SizedBox(height: 6),
          if (bottomCount > 0)
            _ChairRow(
              startSeatIndex: topCount,
              count: bottomCount,
              occupiedSeats: occupiedSeats,
              facingDown: false,
            ),
          const Spacer(),
          if (activeOrders > 0)
            Text(
              '$activeOrders active order${activeOrders > 1 ? 's' : ''}',
              style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.hintFontColor),
            ),
            ],
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
    const size = 32.0;
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              width: 22,
              height: 22,
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
          Text(label, style: AppStyles.getMediumTextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
