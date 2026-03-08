import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';

class KitchenSettingsDialog extends StatefulWidget {
  const KitchenSettingsDialog({super.key});

  @override
  State<KitchenSettingsDialog> createState() => _KitchenSettingsDialogState();
}

class _KitchenSettingsDialogState extends State<KitchenSettingsDialog> {
  final _db = locator<AppDatabase>();
  final _printService = locator<PrintService>();
  List<_KitchenRow> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadKitchens();
  }

  Future<void> _loadKitchens() async {
    setState(() => _loading = true);
    try {
      final kitchens = await _db.itemDao.getAllKitchens();
      final billPrinter = await _db.itemDao.getBillPrinter();

      final rows = <_KitchenRow>[
        _KitchenRow(
          kitchenId: 0,
          name: 'Bill Printer',
          ipController: TextEditingController(text: billPrinter?.printerIp ?? ''),
          portController: TextEditingController(
            text: billPrinter != null ? '${billPrinter.printerPort}' : '9100',
          ),
        ),
        ...kitchens.map((k) => _KitchenRow(
              kitchenId: k.id,
              name: k.name,
              ipController: TextEditingController(text: k.printerIp ?? ''),
              portController: TextEditingController(
                text: k.printerIp != null ? '${k.printerPort}' : '9100',
              ),
            )),
      ];
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) showErrorDialog(context, e);
    }
  }

  Future<void> _saveKitchen(_KitchenRow row) async {
    final ip = row.ipController.text.trim();
    if (ip.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter IP address')),
      );
      return;
    }
    final portStr = row.portController.text.trim();
    final port = int.tryParse(portStr) ?? 9100;

    try {
      await _printService.setKitchenPrinter(
        kitchenId: row.kitchenId,
        ip: ip,
        port: port,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${row.name} saved')),
        );
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, e);
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.ipController.dispose();
      row.portController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Kitchen Printers',
                    style: AppStyles.getBoldTextStyle(fontSize: 20),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _rows.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (_, i) {
                          final row = _rows[i];
                          return _KitchenRowWidget(
                            row: row,
                            onSave: () => _saveKitchen(row),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KitchenRow {
  final int kitchenId;
  final String name;
  final TextEditingController ipController;
  final TextEditingController portController;

  _KitchenRow({
    required this.kitchenId,
    required this.name,
    required this.ipController,
    required this.portController,
  });
}

class _KitchenRowWidget extends StatelessWidget {
  final _KitchenRow row;
  final VoidCallback onSave;

  const _KitchenRowWidget({required this.row, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.name,
            style: AppStyles.getBoldTextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: row.ipController,
            labelText: 'IP Address',
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: row.portController,
            labelText: 'Port',
            keyBoardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          CustomButton(
            width: 100,
            text: 'Save',
            onPressed: onSave,
          ),
        ],
      ),
    );
  }
}
