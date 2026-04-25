import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/print/print_service.dart';
import 'package:pos/core/utils/error_dialog_utils.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/presentation/widgets/app_dropdown_field.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';

enum _ConnectionType { network, usb, ble }

class KitchenSettingsDialog extends StatefulWidget {
  const KitchenSettingsDialog({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  State<KitchenSettingsDialog> createState() => _KitchenSettingsDialogState();
}

class _KitchenSettingsDialogState extends State<KitchenSettingsDialog> {
  final _db = locator<AppDatabase>();
  final _printService = locator<PrintService>();
  final _printerPlugin = FlutterThermalPrinter.instance;
  List<_KitchenRow> _rows = [];
  bool _loading = true;
  StreamSubscription<List<Printer>>? _scanSubscription;

  _ConnectionType _parseConnectionType(String? printerIp) {
    if (printerIp == null || printerIp.isEmpty) return _ConnectionType.network;
    if (printerIp.startsWith('ble|')) return _ConnectionType.ble;
    if (printerIp.startsWith('usb|')) return _ConnectionType.usb;
    return _ConnectionType.network;
  }

  String _networkAddress(String? printerIp) {
    if (printerIp == null || printerIp.isEmpty) return '';
    if (printerIp.startsWith('ble|')) return printerIp.substring(4);
    if (printerIp.startsWith('usb|')) return '';
    return printerIp;
  }

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
      dynamic fallbackPrinter;
      for (final kitchen in kitchens) {
        final ip = kitchen.printerIp;
        if (ip != null && ip.trim().isNotEmpty) {
          fallbackPrinter = kitchen;
          break;
        }
      }
      final defaultReceiptIp = billPrinter?.printerIp ?? fallbackPrinter?.printerIp;
      final defaultReceiptPort = billPrinter?.printerPort ?? fallbackPrinter?.printerPort ?? 9100;

      final rows = <_KitchenRow>[
        ...kitchens.map((k) {
          final connType = _parseConnectionType(k.printerIp);
          return _KitchenRow(
            kitchenId: k.id,
            name: k.name,
            connectionType: connType,
            ipController: TextEditingController(
              text: k.printerIp != null ? _networkAddress(k.printerIp) : '',
            ),
            portController: TextEditingController(
              text: k.printerIp != null ? '${k.printerPort}' : '9100',
            ),
            selectedAddress: (connType == _ConnectionType.network) ? null : k.printerIp,
          );
        }),
        _KitchenRow(
          kitchenId: 0,
          name: 'Receipt Printer',
          connectionType: _parseConnectionType(defaultReceiptIp),
          ipController: TextEditingController(
            text: _networkAddress(defaultReceiptIp),
          ),
          portController: TextEditingController(
            text: '$defaultReceiptPort',
          ),
          selectedAddress: defaultReceiptIp,
        ),
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
    String address;
    int port;
    if (row.connectionType == _ConnectionType.network) {
      address = row.ipController.text.trim();
      if (address.isEmpty) {
        CustomSnackBar.showError(message: 'Please enter IP address');
        return;
      }
      port = int.tryParse(row.portController.text.trim()) ?? 9100;
    } else {
      address = row.selectedAddress ?? '';
      if (address.isEmpty) {
        CustomSnackBar.showWarning(
          message: 'Please scan and select a ${row.connectionType == _ConnectionType.usb ? "USB" : "Bluetooth"} printer',
        );
        return;
      }
      port = 0;
    }

    try {
      await _printService.setKitchenPrinter(
        kitchenId: row.kitchenId,
        ip: address,
        port: port,
      );
      if (mounted) {
        CustomSnackBar.showSuccess(message: '${row.name} saved');
      }
    } catch (e) {
      if (mounted) showErrorDialog(context, e);
    }
  }

  /// Returns false if permission was denied and scan did not start; true otherwise.
  Future<bool> _startScan(void Function(List<Printer>) onResults) async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      final ok = await _requestPrinterPermissions();
      if (!ok && mounted) {
        CustomSnackBar.showWarning(
          message: 'Bluetooth permission is needed to scan for printers. Grant it in app settings.',
        );
        return false;
      }
    }
    _scanSubscription?.cancel();
    _printerPlugin.getPrinters(
      connectionTypes: [ConnectionType.USB, ConnectionType.BLE],
      refreshDuration: const Duration(seconds: 5),
    );
    _scanSubscription = _printerPlugin.devicesStream.listen((list) {
      for (final p in list) {
        debugPrint(
          'Printer from plugin: name=${p.name}, connectionType=${p.connectionType}, '
          'address=${p.address}, vendorId=${p.vendorId}, productId=${p.productId}, isConnected=${p.isConnected}',
        );
      }
      final filtered = list.where((p) => (p.name != null && p.name!.isNotEmpty) && (p.connectionType == ConnectionType.USB || p.connectionType == ConnectionType.BLE)).toList();
      onResults(filtered);
    });
    return true;
  }

  /// Request Bluetooth (and location on Android <12 for BLE scan) so scan works on Android 12+ and iOS.
  Future<bool> _requestPrinterPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await Permission.bluetoothScan.request();
      await Permission.bluetoothConnect.request();
      await Permission.locationWhenInUse.request(); // BLE scan on Android < 12
      final scan = await Permission.bluetoothScan.status;
      final connect = await Permission.bluetoothConnect.status;
      return scan.isGranted && connect.isGranted;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final status = await Permission.bluetooth.request();
      return status.isGranted;
    }
    return true;
  }

  void _stopScan() {
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _printerPlugin.stopScan();
  }

  @override
  void dispose() {
    _stopScan();
    for (final row in _rows) {
      row.ipController.dispose();
      row.portController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return _buildContent(context, showClose: false);
    }
    return _buildContent(context, showClose: true);
  }

  Widget _buildContent(BuildContext context, {required bool showClose}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final horizontalPadding = isDesktop ? 24.0 : 12.0;
        const spacing = 14.0;
        final columns = isDesktop ? (constraints.maxWidth >= 1280 ? 3 : 2) : 1;
        final availableWidth = constraints.maxWidth - horizontalPadding * 2;
        final cardWidth = columns == 1 ? availableWidth : (availableWidth - (spacing * (columns - 1))) / columns;
        return Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 20),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    ..._rows.map(
                      (row) => SizedBox(
                        width: cardWidth,
                        child: _KitchenRowWidget(
                          row: row,
                          onSave: () => _saveKitchen(row),
                          onConnectionTypeChanged: (t) {
                            setState(() => row.connectionType = t);
                          },
                          onSelectedAddressChanged: (a) {
                            setState(() => row.selectedAddress = a);
                          },
                          onStartScan: _startScan,
                          onStopScan: _stopScan,
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

class _KitchenRow {
  final int kitchenId;
  final String name;
  _ConnectionType connectionType;
  final TextEditingController ipController;
  final TextEditingController portController;
  String? selectedAddress;

  _KitchenRow({
    required this.kitchenId,
    required this.name,
    required this.connectionType,
    required this.ipController,
    required this.portController,
    this.selectedAddress,
  });
}

class _KitchenRowWidget extends StatefulWidget {
  final _KitchenRow row;
  final VoidCallback onSave;
  final void Function(_ConnectionType) onConnectionTypeChanged;
  final void Function(String?) onSelectedAddressChanged;
  final Future<bool> Function(void Function(List<Printer>) onResults) onStartScan;
  final VoidCallback onStopScan;

  const _KitchenRowWidget({
    required this.row,
    required this.onSave,
    required this.onConnectionTypeChanged,
    required this.onSelectedAddressChanged,
    required this.onStartScan,
    required this.onStopScan,
  });

  @override
  State<_KitchenRowWidget> createState() => _KitchenRowWidgetState();
}

class _KitchenRowWidgetState extends State<_KitchenRowWidget> {
  List<Printer> _discoveredPrinters = [];
  bool _scanning = false;

  /// Encode printer for saving. Stored in DB as printerIp (e.g. "usb|vid|pid").
  /// For USB we always save three segments so productId is never null when decoding;
  /// if the plugin returns null/empty productId we use '0'.
  static String _encodePrinter(Printer p) {
    if (p.connectionType == ConnectionType.USB && p.vendorId != null && p.vendorId!.isNotEmpty) {
      final pid = (p.productId != null && p.productId!.trim().isNotEmpty && p.productId!.toLowerCase() != 'n/a') ? p.productId!.trim() : '0';
      debugPrint('KitchenSettings: encoding USB printer vendorId=${p.vendorId}, productId=${p.productId} -> saved as usb|${p.vendorId}|$pid');
      return 'usb|${p.vendorId}|$pid';
    }
    if (p.connectionType == ConnectionType.USB && (p.vendorId == null || p.vendorId!.isEmpty)) {
      debugPrint('KitchenSettings: USB printer "${p.name}" has no vendorId (address=${p.address}), cannot encode');
    }
    if (p.connectionType == ConnectionType.BLE && p.address != null) {
      return 'ble|${p.address}';
    }
    return '';
  }

  void _handleScan() async {
    if (_scanning) {
      widget.onStopScan();
      setState(() => _scanning = false);
      return;
    }
    setState(() {
      _scanning = true;
      _discoveredPrinters = [];
    });
    final started = await widget.onStartScan((list) {
      if (mounted) {
        setState(() => _discoveredPrinters = list);
      }
    });
    if (!started && mounted) {
      setState(() => _scanning = false);
    }
  }

  @override
  void dispose() {
    if (_scanning) widget.onStopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final isNetwork = row.connectionType == _ConnectionType.network;
    final isUsb = row.connectionType == _ConnectionType.usb;
    final isBle = row.connectionType == _ConnectionType.ble;
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final sectionSpacing = isDesktop ? 14.0 : 12.0;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 18 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.print_outlined,
                  size: 18,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  row.name,
                  style: AppStyles.getBoldTextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
          SizedBox(height: sectionSpacing),
          AppDropdownField<_ConnectionType>(
            labelText: 'Connection type',
            value: row.connectionType,
            items: const [
              DropdownMenuItem(value: _ConnectionType.network, child: Text('Network (Wi-Fi)')),
              DropdownMenuItem(value: _ConnectionType.usb, child: Text('USB')),
              DropdownMenuItem(value: _ConnectionType.ble, child: Text('Bluetooth')),
            ],
            onChanged: (v) {
              if (v != null) {
                widget.onConnectionTypeChanged(v);
              }
            },
          ),
          SizedBox(height: sectionSpacing),
          if (isNetwork) ...[
            CustomTextField(
              controller: row.ipController,
              labelText: 'IP Address',
            ),
            SizedBox(height: sectionSpacing),
            CustomTextField(
              controller: row.portController,
              labelText: 'Port',
              keyBoardType: TextInputType.number,
            ),
          ],
          if (isUsb || isBle) ...[
            Row(
              children: [
                CustomButton(
                  width: isDesktop ? 140 : 128,
                  text: _scanning ? 'Stop scan' : 'Scan printers',
                  onPressed: _handleScan,
                ),
              ],
            ),
            if (_discoveredPrinters.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Select printer:',
                style: AppStyles.getBoldTextStyle(fontSize: 12),
              ),
              const SizedBox(height: 6),
              AppDropdownField<String>(
                labelText: 'Choose printer',
                value: row.selectedAddress,
                items: () {
                  final encSet = <String>{};
                  final items = <DropdownMenuItem<String>>[];
                  for (final p in _discoveredPrinters) {
                    final enc = _encodePrinter(p);
                    if (enc.isNotEmpty && !encSet.contains(enc)) {
                      encSet.add(enc);
                      items.add(
                        DropdownMenuItem<String>(
                          value: enc,
                          child: Text(
                            p.name ?? enc,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }
                  }
                  final savedEnc = row.selectedAddress;
                  if (savedEnc != null && savedEnc.isNotEmpty && !encSet.contains(savedEnc)) {
                    items.add(
                      DropdownMenuItem<String>(
                        value: savedEnc,
                        child: const Text(
                          'Saved (scan to change)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }
                  return items;
                }(),
                onChanged: (v) => widget.onSelectedAddressChanged(v),
              ),
            ],
          ],
          SizedBox(height: sectionSpacing),
          Align(
            alignment: Alignment.centerRight,
            child: CustomButton(
              width: isDesktop ? 120 : 110,
              text: 'Save',
              onPressed: widget.onSave,
            ),
          ),
        ],
      ),
    );
  }
}
