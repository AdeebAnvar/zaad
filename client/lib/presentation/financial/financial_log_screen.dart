import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/data/repository_impl/financial_record_repository_impl.dart';
import 'package:pos/domain/models/financial_record_type.dart';
import 'package:pos/presentation/financial/financial_create_launcher.dart';
import 'package:pos/presentation/financial/financial_records_cubit.dart';
import 'package:pos/presentation/financial/financial_records_state.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_scaffold.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';
import 'package:pos/presentation/widgets/log_filter_shell.dart';

class FinancialLogScreen extends StatelessWidget {
  const FinancialLogScreen({
    super.key,
    required this.config,
  });

  final FinancialFormConfig config;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FinancialRecordsCubit(
        FinancialRecordRepositoryImpl(locator<AppDatabase>()),
        config,
      )..load(),
      child: _FinancialLogView(config: config),
    );
  }
}

class _FinancialLogView extends StatefulWidget {
  const _FinancialLogView({required this.config});

  final FinancialFormConfig config;

  @override
  State<_FinancialLogView> createState() => _FinancialLogViewState();
}

class _FinancialLogViewState extends State<_FinancialLogView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    await showFinancialCreatePopup(context, widget.config);
    if (!mounted) return;
    await context.read<FinancialRecordsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      title: widget.config.logTitle,
      body: BlocBuilder<FinancialRecordsCubit, FinancialRecordsState>(
        builder: (context, state) {
          if (state is FinancialRecordsLoading || state is FinancialRecordsInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FinancialRecordsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.read<FinancialRecordsCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is! FinancialRecordsLoaded) return const SizedBox.shrink();

          final rows = state.filteredRecords;

          return RefreshIndicator(
            onRefresh: () => context.read<FinancialRecordsCubit>().load(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: AppPadding.screenAll,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.config.logTitle.toUpperCase(),
                    style: AppStyles.getBoldTextStyle(fontSize: 26, color: AppColors.primaryColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.config.logSubtitle,
                    style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.hintFontColor),
                  ),
                  const SizedBox(height: 16),
                  _FilterBar(
                    from: state.from,
                    to: state.to,
                    onSearch: (from, to) =>
                        context.read<FinancialRecordsCubit>().setDateRange(from, to),
                    onAdd: _openCreate,
                    addLabel: widget.config.addButtonLabel,
                  ),
                  const SizedBox(height: 16),
                  LogFilterShell(
                    title: 'Search',
                    subtitle: 'Filter table rows',
                    icon: Icons.search,
                    body: CustomTextField(
                      controller: _searchController,
                      labelText: 'Search',
                      onChanged: context.read<FinancialRecordsCubit>().setFilterQuery,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _RecordsTable(
                    config: widget.config,
                    records: rows,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Showing ${rows.isEmpty ? 0 : 1} to ${rows.length} of ${rows.length} entries',
                    style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.hintFontColor),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatefulWidget {
  const _FilterBar({
    required this.from,
    required this.to,
    required this.onSearch,
    required this.onAdd,
    required this.addLabel,
  });

  final DateTime from;
  final DateTime to;
  final void Function(DateTime from, DateTime to) onSearch;
  final VoidCallback onAdd;
  final String addLabel;

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  late DateTime _from;
  late DateTime _to;

  @override
  void initState() {
    super.initState();
    _from = widget.from;
    _to = widget.to;
  }

  Future<void> _pick(bool isFrom) async {
    final picked = await showLogFilterDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = DateTime(picked.year, picked.month, picked.day);
      } else {
        _to = DateTime(picked.year, picked.month, picked.day, 23, 59, 59, 999);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('yyyy-MM-dd HH:mm');
    return LogFilterShell(
      title: 'Date range',
      subtitle: 'Filter records by date',
      icon: Icons.date_range_outlined,
      body: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          SizedBox(
            width: 200,
            child: InkWell(
              onTap: () => _pick(true),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'From Date',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: Text(fmt.format(_from)),
              ),
            ),
          ),
          SizedBox(
            width: 200,
            child: InkWell(
              onTap: () => _pick(false),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'To Date',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: Text(fmt.format(_to)),
              ),
            ),
          ),
          CustomButton(
            width: 100,
            text: 'Search',
            onPressed: () => widget.onSearch(_from, _to),
          ),
          CustomButton(
            width: 180,
            text: widget.addLabel,
            onPressed: widget.onAdd,
          ),
        ],
      ),
    );
  }
}

class _RecordsTable extends StatelessWidget {
  const _RecordsTable({
    required this.config,
    required this.records,
  });

  final FinancialFormConfig config;
  final List<FinancialRecord> records;

  @override
  Widget build(BuildContext context) {
    final type = config.type;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _headerRow(type),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                config.emptyMessage,
                style: AppStyles.getSemiBoldTextStyle(fontSize: 14, color: AppColors.hintFontColor),
              ),
            )
          else
            ...List.generate(records.length, (i) {
              final r = records[i];
              return _dataRow(type, i + 1, r);
            }),
        ],
      ),
    );
  }

  Widget _headerRow(FinancialRecordType type) {
    final headers = switch (type) {
      FinancialRecordType.expense => [
          'S.NO',
          'CATEGORY',
          'INVOICE NO',
          'COMPANY',
          'DESCRIPTION',
          'PAYMENT',
          'BEFORE VAT',
          'VAT',
          'TOTAL',
          'DATE',
        ],
      FinancialRecordType.salary => [
          'S.NO',
          'STAFF NAME',
          'JOINING DATE',
          'EXIT DATE',
          'DAYS',
          'DESCRIPTION',
          'PAYMENT',
          'AMOUNT',
          'DATE',
        ],
      FinancialRecordType.otherIncome => [
          'S.NO',
          'DESCRIPTION',
          'PAYMENT TYPE',
          'AMOUNT',
          'DATE',
        ],
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: const Color(0xFFF5F6F8),
      child: Row(
        children: headers
            .map(
              (h) => Expanded(
                flex: h == 'DESCRIPTION' ? 2 : 1,
                child: Text(
                  h,
                  style: AppStyles.getSemiBoldTextStyle(fontSize: 11, color: AppColors.primaryColor),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _dataRow(FinancialRecordType type, int sn, FinancialRecord r) {
    final date = RuntimeAppSettings.formatDateTime(r.createdAt).toUpperCase();
    final payment = (r.paymentMethodName ?? '—').toUpperCase();

    List<String> cells;
    switch (type) {
      case FinancialRecordType.expense:
        cells = [
          '$sn',
          (r.expenseCategoryName ?? '—').toUpperCase(),
          (r.invoiceNo?.trim().isEmpty ?? true) ? 'N/A' : r.invoiceNo!,
          (r.companyName ?? '—').toUpperCase(),
          r.description ?? '',
          payment,
          RuntimeAppSettings.money(r.amountBeforeVat),
          RuntimeAppSettings.money(r.vatAmount),
          RuntimeAppSettings.money(r.finalAmount),
          date,
        ];
      case FinancialRecordType.salary:
        final j = r.joiningDate != null ? RuntimeAppSettings.formatDate(r.joiningDate!) : '—';
        final e = r.exitDate != null ? RuntimeAppSettings.formatDate(r.exitDate!) : '—';
        cells = [
          '$sn',
          (r.staffName ?? '—').toUpperCase(),
          j.toUpperCase(),
          e.toUpperCase(),
          '${r.days ?? '—'}',
          r.description ?? '',
          payment,
          RuntimeAppSettings.money(r.finalAmount),
          date,
        ];
      case FinancialRecordType.otherIncome:
        cells = [
          '$sn',
          r.description ?? '—',
          payment,
          RuntimeAppSettings.money(r.finalAmount),
          date,
        ];
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: List.generate(
          cells.length,
          (i) => Expanded(
            flex: i == (type == FinancialRecordType.expense ? 3 : (type == FinancialRecordType.salary ? 5 : 1)) ? 2 : 1,
            child: Text(
              cells[i],
              style: AppStyles.getRegularTextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
