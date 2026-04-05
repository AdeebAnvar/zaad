import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository/order_repository.dart';
import 'package:pos/presentation/dine_in_log/dine_in_log_cubit.dart';
import 'package:pos/presentation/dine_in_log/dine_in_reference_utils.dart';
import 'package:pos/presentation/widgets/app_snackbar.dart';
import 'package:pos/presentation/widgets/app_standard_dialog.dart';
import 'package:pos/presentation/widgets/custom_button.dart';

/// Bottom sheet on narrow screens, dialog on wide — pick floor + table to reassign a dine-in order.
Future<void> showDineInMoveFloorTableUi(BuildContext context, Order order) async {
  final cubit = context.read<DineInLogCubit>();
  // Dialog/sheet routes sit above the log screen; re-provide the cubit so the body can read it.
  final body = BlocProvider<DineInLogCubit>.value(
    value: cubit,
    child: _DineInMoveFloorTableBody(order: order),
  );

  await showAppAdaptiveSheetOrDialog<void>(
    context: context,
    breakpoint: 900,
    title: Text('Move to floor / table', style: AppStyles.getSemiBoldTextStyle(fontSize: 18)),
    dialogActions: (dCtx) => [
      TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Close')),
    ],
    child: body,
  );
}

class _DineInMoveFloorTableBody extends StatefulWidget {
  const _DineInMoveFloorTableBody({required this.order});

  final Order order;

  @override
  State<_DineInMoveFloorTableBody> createState() => _DineInMoveFloorTableBodyState();
}

class _DineInMoveFloorTableBodyState extends State<_DineInMoveFloorTableBody> {
  final _db = locator<AppDatabase>();
  final _orderRepo = locator<OrderRepository>();

  bool _loading = true;
  String? _error;
  List<DiningFloor> _floors = [];
  List<DiningTable> _tables = [];
  int? _floorId;
  int? _tableId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final floors = await _db.diningTablesDao.getFloors();
      if (floors.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'No floors synced.';
        });
        return;
      }
      final currentTableCode = DineInRefParser.extractTableCode(widget.order.referenceNumber);
      final lead = DineInRefParser.extractLeadingFloorId(widget.order.referenceNumber);

      var startFloor = floors.first;
      if (lead != null) {
        final match = floors.firstWhereOrNull((f) => f.id == lead);
        if (match != null) startFloor = match;
      }

      final tables = await _db.diningTablesDao.getTablesByFloor(startFloor.id);
      DiningTable? startTable;
      for (final t in tables) {
        if (DineInRefParser.tableKey(t.code) == DineInRefParser.tableKey(currentTableCode)) {
          startTable = t;
          break;
        }
      }
      startTable ??= tables.isNotEmpty ? tables.first : null;

      if (!mounted) return;
      setState(() {
        _floors = floors;
        _floorId = startFloor.id;
        _tables = tables;
        _tableId = startTable?.id;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _onFloorChanged(int? id) async {
    if (id == null) return;
    setState(() {
      _floorId = id;
      _tableId = null;
    });
    final tables = await _db.diningTablesDao.getTablesByFloor(id);
    if (!mounted) return;
    setState(() {
      _tables = tables;
      _tableId = tables.isNotEmpty ? tables.first.id : null;
    });
  }

  Future<void> _confirm(BuildContext context) async {
    final table = _tables.firstWhereOrNull((t) => t.id == _tableId);
    final fid = _floorId;
    if (table == null || fid == null) {
      showAppSnackBar(context, 'Select a table');
      return;
    }

    final pax = DineInRefParser.extractPaxFromReference(widget.order.referenceNumber);
    final active = await _orderRepo.filterOrders(orderType: 'dine_in');
    final activeList = active.where((o) {
      final s = o.status.toLowerCase();
      return s != 'completed' && s != 'cancelled';
    }).toList();

    final used = await DineInRefParser.occupiedPaxOnTableExcluding(
      floorId: fid,
      tableCodeUpper: DineInRefParser.tableKey(table.code),
      excludeOrderId: widget.order.id,
      db: _db,
      activeDineInOrders: activeList,
    );

    if (used + pax > table.chairs) {
      if (!context.mounted) return;
      showAppSnackBar(
        context,
        'Not enough seats on ${table.code} ($used + $pax pax needed, ${table.chairs} seats).',
        isError: true,
      );
      return;
    }

    final newRef = DineInRefParser.buildReference(fid, table.code, pax);
    final cubit = context.read<DineInLogCubit>();
    final nav = Navigator.of(context);
    final err = await cubit.moveDineInOrderToTable(
      orderId: widget.order.id,
      newReferenceNumber: newRef,
    );

    if (!mounted) return;
    if (err != null) {
      showAppSnackBar(context, err, isError: true);
      return;
    }
    nav.pop();
    showAppSnackBar(context, 'Order moved to selected floor / table');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }

    final pax = DineInRefParser.extractPaxFromReference(widget.order.referenceNumber);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Invoice ${widget.order.invoiceNumber}',
            style: AppStyles.getMediumTextStyle(fontSize: 14, color: AppColors.hintFontColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Keeps $pax pax on the new table.',
            style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.hintFontColor),
          ),
          const SizedBox(height: 16),
          Text('Floor', style: AppStyles.getSemiBoldTextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            value: _floorId,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _floors
                .map(
                  (f) => DropdownMenuItem<int>(
                    value: f.id,
                    child: Text(f.name),
                  ),
                )
                .toList(),
            onChanged: _onFloorChanged,
          ),
          const SizedBox(height: 16),
          Text('Table', style: AppStyles.getSemiBoldTextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          if (_tables.isEmpty)
            Text(
              'No tables on this floor.',
              style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.hintFontColor),
            )
          else
            DropdownButtonFormField<int>(
              value: _tableId,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: _tables
                  .map(
                    (t) => DropdownMenuItem<int>(
                      value: t.id,
                      child: Text('${t.code} · ${t.chairs} seats'),
                    ),
                  )
                  .toList(),
              onChanged: (id) => setState(() => _tableId = id),
            ),
          const SizedBox(height: 24),
          CustomButton(
            width: double.infinity,
            onPressed: _tables.isEmpty ? null : () => _confirm(context),
            text: 'Move order',
          ),
        ],
      ),
    );
  }
}
