import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/app/routes.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';

class DineInScreen extends StatefulWidget {
  const DineInScreen({super.key});

  @override
  State<DineInScreen> createState() => _DineInScreenState();
}

class _DineInScreenState extends State<DineInScreen> {
  final _db = locator<AppDatabase>();
  final _orderRepo = locator<OrderRepository>();

  bool _loading = true;
  int _selectedFloorIndex = 0;
  List<DiningFloor> _floors = [];
  List<DiningTable> _tables = [];
  Map<String, int> _activeOrdersPerTable = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final floors = await _db.diningTablesDao.getFloors();
    final orders = await _orderRepo.filterOrders(orderType: 'dine_in');
    final active = orders.where((o) {
      final s = o.status.toLowerCase();
      return s != 'completed' && s != 'cancelled';
    }).toList();

    final counts = <String, int>{};
    for (final o in active) {
      final tableCode = _extractTableCode(o.referenceNumber);
      if (tableCode.isEmpty) continue;
      counts[tableCode] = (counts[tableCode] ?? 0) + 1;
    }

    List<DiningTable> tables = [];
    if (floors.isNotEmpty) {
      tables = await _db.diningTablesDao.getTablesByFloor(floors.first.id);
    }

    if (!mounted) return;
    setState(() {
      _floors = floors;
      _tables = tables;
      _activeOrdersPerTable = counts;
      _selectedFloorIndex = 0;
      _loading = false;
    });
  }

  String _extractTableCode(String? referenceNumber) {
    final v = (referenceNumber ?? '').trim();
    if (v.isEmpty) return '';
    if (v.contains('|')) {
      return v.split('|').first.trim().toUpperCase();
    }
    return v.toUpperCase();
  }

  Future<void> _changeFloor(int index) async {
    if (index < 0 || index >= _floors.length) return;
    final floorId = _floors[index].id;
    final tables = await _db.diningTablesDao.getTablesByFloor(floorId);
    if (!mounted) return;
    setState(() {
      _selectedFloorIndex = index;
      _tables = tables;
    });
  }

  Future<void> _openCounterForTable(DiningTable table) async {
    final chairs = await _pickChairCount(table.chairs);
    if (chairs == null || !mounted) return;
    final reference = '${table.code} | $chairs pax';
    AppNavigator.pushNamed(
      Routes.counter,
      args: {
        'orderType': 'dine_in',
        'referenceNumber': reference,
      },
    ).then((_) => _load());
  }

  Future<int?> _pickChairCount(int maxChairs) async {
    int selected = maxChairs > 0 ? 1 : 0;
    return showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Accommodate customers'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select chair count for this order'),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: selected,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: List.generate(
                  maxChairs,
                  (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
                ),
                onChanged: (v) {
                  if (v != null) selected = v;
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, selected),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Open Counter'),
            ),
          ],
        );
      },
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
                      const SizedBox(height: 6),
                      Text(
                        'Synced floors/tables/chairs with live allocation status.',
                        style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.hintFontColor),
                      ),
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
                              childAspectRatio: isMobile ? 1 : 1.05,
                            ),
                            itemBuilder: (_, i) {
                              final t = _tables[i];
                              final tableCode = t.code.toUpperCase();
                              final activeOrders = _activeOrdersPerTable[tableCode] ?? 0;
                              final allocated = activeOrders > 0 || t.status.toLowerCase() == 'allocated';
                              return _TableCard(
                                code: t.code,
                                chairs: t.chairs,
                                allocated: allocated,
                                activeOrders: activeOrders,
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
      children: const [
        _LegendChip(label: 'Free', color: Color(0xFF22C55E)),
        _LegendChip(label: 'Allocated', color: Color(0xFFF59E0B)),
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

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.code,
    required this.chairs,
    required this.allocated,
    required this.activeOrders,
    required this.onAdd,
  });

  final String code;
  final int chairs;
  final bool allocated;
  final int activeOrders;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final accent = allocated ? const Color(0xFFF59E0B) : const Color(0xFF22C55E);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.5),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(code, style: AppStyles.getSemiBoldTextStyle(fontSize: 12, color: accent)),
              ),
              const Spacer(),
              Tooltip(
                message: 'Add customer order',
                child: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.primaryColor,
                  onPressed: onAdd,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            height: 44,
            width: 72,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: List.generate(
              chairs,
              (_) => Container(
                height: 10,
                width: 10,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            allocated ? 'Allocated' : 'Free',
            style: AppStyles.getMediumTextStyle(fontSize: 12, color: accent),
          ),
          if (activeOrders > 0)
            Text(
              '$activeOrders active order${activeOrders > 1 ? 's' : ''}',
              style: AppStyles.getRegularTextStyle(fontSize: 11, color: AppColors.hintFontColor),
            ),
        ],
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.color});
  final String label;
  final Color color;

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
