import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pos/app/di.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/app/routes.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/network/lan_hub_health.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/sync/hub_order_lan_publisher.dart';
import 'package:pos/core/sync/local_hub_primary_inbound_coordinator.dart';
import 'package:pos/core/sync/local_hub_sync_coordinator.dart';
import 'package:pos/data/local/drift_database.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// LAN hub: device role + MAIN PC IP. URL is always `ws://<ip>:3001/ws`.
class LanHubSettingsScreen extends StatefulWidget {
  const LanHubSettingsScreen({super.key});

  @override
  State<LanHubSettingsScreen> createState() => _LanHubSettingsScreenState();
}

class _LanHubSettingsScreenState extends State<LanHubSettingsScreen> {
  late final LocalHubSettings _hub;
  late bool _cashierTablet;
  final TextEditingController _ipCtrl = TextEditingController();
  bool _loading = false;
  bool _retryingUnsynced = false;
  int _unsyncedCount = 0;

  LanHubWsHealthSummary? _healthSummary;
  String? _healthError;
  bool _healthLoading = false;

  @override
  void initState() {
    super.initState();
    _hub = locator<LocalHubSettings>();
    _cashierTablet = _hub.isHubSub;
    _ipCtrl.text = LocalHubSettings.hostFieldFromStoredWsUrl(_hub.hubWsUrl);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadConnectedDevices();
      await _loadUnsyncedCount();
    });
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    super.dispose();
  }

  /// WebSocket URL used for `/health`, QR preview, etc. Reflects draft IP field on MAIN before Save.
  String _effectiveWsUrlForUi() {
    if (_cashierTablet) {
      return LocalHubSettings.canonicalHubWsUrl(_ipCtrl.text.trim());
    }
    final ipRaw = _ipCtrl.text.trim();
    if (ipRaw.isEmpty) {
      return LocalHubSettings.defaultMainPublishHubLoopback;
    }
    return LocalHubSettings.canonicalHubWsUrl(ipRaw);
  }

  String? _pairingQrWsUrl() {
    if (_cashierTablet) return null;
    final url = _effectiveWsUrlForUi();
    final u = Uri.tryParse(url.startsWith('ws') || url.startsWith('wss') ? url : 'ws://$url');
    if (u == null || u.host.isEmpty) return null;
    if (_isLoopbackHost(u.host)) return null;
    return url;
  }

  bool _isLoopbackHost(String host) {
    final h = host.toLowerCase();
    return h == '127.0.0.1' || h == 'localhost' || h == '[::1]';
  }

  Future<void> _loadConnectedDevices() async {
    final wsRaw = _effectiveWsUrlForUi();
    if (wsRaw.isEmpty) {
      setState(() {
        _healthSummary = null;
        _healthError = _cashierTablet ? 'Enter the MAIN hub IP.' : 'No hub URL.';
      });
      return;
    }
    final uri = lanHubHealthUriFromStoredWsUrl(wsRaw);
    if (uri == null) {
      setState(() {
        _healthSummary = null;
        _healthError = 'Invalid hub URL.';
      });
      return;
    }
    setState(() {
      _healthLoading = true;
      _healthError = null;
    });
    final summary = await fetchLanHubWsHealthSummary(uri);
    if (!mounted) return;
    setState(() {
      _healthLoading = false;
      if (summary == null) {
        _healthSummary = null;
        _healthError = 'Could not reach hub at ${uri.authority}.';
      } else {
        _healthSummary = summary;
      }
    });
  }

  Future<void> _loadUnsyncedCount() async {
    if (!locator.isRegistered<AppDatabase>()) return;
    final c = await locator<AppDatabase>().syncQueueDao.unsyncedOutboxCount();
    if (!mounted) return;
    setState(() => _unsyncedCount = c);
  }

  Future<void> _retryUnsyncedNow() async {
    if (_retryingUnsynced) return;
    setState(() => _retryingUnsynced = true);
    try {
      if (_cashierTablet && locator.isRegistered<LocalHubSyncCoordinator>()) {
        await locator<LocalHubSyncCoordinator>().retryUnsyncedNow();
      } else {
        await HubOrderLanPublisher.retryUnsyncedNow();
      }
      await _loadUnsyncedCount();
      if (!mounted) return;
      if (_unsyncedCount == 0) {
        CustomSnackBar.showSuccess(message: 'All queued WS events are synced.');
      } else {
        CustomSnackBar.showError(message: 'Still pending: $_unsyncedCount unsynced event(s).');
      }
    } finally {
      if (mounted) setState(() => _retryingUnsynced = false);
    }
  }

  Future<void> _save() async {
    final ipRaw = _ipCtrl.text.trim();

    if (_cashierTablet) {
      final url = LocalHubSettings.canonicalHubWsUrl(ipRaw);
      if (url.isEmpty) {
        CustomSnackBar.showError(
          message: 'Enter the MAIN hub IP (e.g. 192.168.1.10). Port ${LocalHubSettings.defaultHubWsPort} and path ${LocalHubSettings.defaultHubWsPath} are added automatically.',
        );
        return;
      }
    }

    setState(() => _loading = true);
    try {
      await _hub.setRoleHubSub(_cashierTablet);

      if (_cashierTablet) {
        await _hub.setHubWsUrl(LocalHubSettings.canonicalHubWsUrl(ipRaw));
        await _hub.setPublishesCatalogAfterTenantPull(false);
      } else {
        await _hub.setHubWsUrl(
          ipRaw.isEmpty ? null : LocalHubSettings.canonicalHubWsUrl(ipRaw),
        );
        await _hub.setPublishesCatalogAfterTenantPull(true);
      }

      if (locator.isRegistered<LocalHubSyncCoordinator>()) {
        await locator<LocalHubSyncCoordinator>().reconnectFromSettings();
      }
      if (locator.isRegistered<LocalHubPrimaryInboundCoordinator>()) {
        await locator<LocalHubPrimaryInboundCoordinator>().reconnectFromSettings();
      }

      if (!mounted) return;
      final summaryText = _cashierTablet
          ? 'Cashier uses ${LocalHubSettings.canonicalHubWsUrl(ipRaw)}'
          : (ipRaw.isEmpty ? 'Primary uses ${LocalHubSettings.defaultMainPublishHubLoopback} when IP is blank' : 'Primary uses ${LocalHubSettings.canonicalHubWsUrl(ipRaw)}');
      CustomSnackBar.showSuccess(message: 'Saved. $summaryText');
      Navigator.maybePop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showPairingQr() async {
    final url = _pairingQrWsUrl();
    if (url == null) {
      CustomSnackBar.showError(
        message: 'Set this PC\'s LAN IP (not 127.0.0.1) so tablets can scan and connect.',
      );
      return;
    }
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.paddingOf(sheetContext).bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pair cashier (SUB)',
                style: AppStyles.getSemiBoldTextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              SelectableText(
                url,
                style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.hintFontColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                  }
                  if (mounted) {
                    CustomSnackBar.showSuccess(message: 'WebSocket URL copied');
                  }
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy URL'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showLoopbackQrAnyway() async {
    final ws = _effectiveWsUrlForUi();
    if (ws.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('QR with loopback URL?'),
        content: Text(
          'Other devices cannot use ws://127.0.0.1 — use your PC LAN IP instead. '
          'Show QR anyway?',
          style: AppStyles.getRegularTextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Show')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final url = ws;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, MediaQuery.paddingOf(sheetContext).bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pair cashier (SUB) — localhost only',
                style: AppStyles.getSemiBoldTextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              QrImageView(
                data: url,
                version: QrVersions.auto,
                size: 220,
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: url));
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  if (mounted) CustomSnackBar.showSuccess(message: 'URL copied');
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy URL'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openPairingScanner() async {
    final scanned = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _HubPairingScannerScreen(),
      ),
    );
    if (scanned == null || !mounted) return;
    final normalized = _parseScannedHubUrl(scanned);
    if (normalized == null) {
      CustomSnackBar.showError(message: 'Not a valid hub WebSocket URL.');
      return;
    }
    _ipCtrl.text = LocalHubSettings.hostFieldFromStoredWsUrl(normalized);
    setState(() {});
    await _loadConnectedDevices();
    CustomSnackBar.showSuccess(message: 'IP filled from QR. Tap Save to apply.');
  }

  /// Returns canonical `ws://…` or null.
  String? _parseScannedHubUrl(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return null;
    final withScheme = (t.startsWith('ws://') || t.startsWith('wss://')) ? t : 'ws://$t';
    final u = Uri.tryParse(withScheme);
    if (u == null || u.host.isEmpty) return null;
    return LocalHubSettings.canonicalHubWsUrl('${u.host}:${u.hasPort ? u.port : LocalHubSettings.defaultHubWsPort}');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final wsPreview = _effectiveWsUrlForUi();
    final uriPreview = Uri.tryParse(
      wsPreview.startsWith('ws') || wsPreview.startsWith('wss') ? wsPreview : 'ws://$wsPreview',
    );
    final mainLoopbackPreview = !_cashierTablet && uriPreview != null && uriPreview.host.isNotEmpty && _isLoopbackHost(uriPreview.host);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.primaryColor),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              AppNavigator.pushReplacementNamed(Routes.dashboard);
            }
          },
        ),
        title: Text(
          'LAN hub',
          style: AppStyles.getSemiBoldTextStyle(fontSize: 18),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
        children: [
          CustomTextField(
            controller: _ipCtrl,
            labelText: _cashierTablet ? 'MAIN PC IP address' : 'Hub IP address (optional on MAIN)',
            showAsUpperLabel: true,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text('I am sub device', style: AppStyles.getMediumTextStyle(fontSize: 15)),
            value: _cashierTablet,
            activeThumbColor: AppColors.primaryColor,
            onChanged: _loading
                ? null
                : (v) {
                    setState(() => _cashierTablet = v);
                    _loadConnectedDevices();
                    _loadUnsyncedCount();
                  },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Connected devices',
                  style: AppStyles.getSemiBoldTextStyle(fontSize: 15),
                ),
              ),
              if (_healthLoading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: _loadConnectedDevices,
                  icon: const Icon(Icons.refresh_rounded),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: _healthError != null
                  ? Text(
                      _healthError!,
                      style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.red.shade700),
                    )
                  : _healthSummary == null
                      ? Text(
                          'Tap refresh to query the hub.',
                          style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.hintFontColor),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Open WebSockets: ${_healthSummary!.openSockets}',
                              style: AppStyles.getMediumTextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            ..._healthSummary!.peers.map(
                              (p) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  '${p.deviceId ?? '?'}  ${p.ip ?? ''}:${p.port ?? ''}',
                                  style: AppStyles.getRegularTextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Unsynced WS events: $_unsyncedCount',
                      style: AppStyles.getMediumTextStyle(fontSize: 14),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: (_loading || _retryingUnsynced) ? null : _retryUnsyncedNow,
                    icon: _retryingUnsynced
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                    label: const Text('Retry now'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (!_cashierTablet) ...[
            OutlinedButton.icon(
              onPressed: _loading ? null : () => _showPairingQr(),
              icon: const Icon(Icons.qr_code_2_rounded),
              label: const Text('Show pairing QR'),
            ),
            if (mainLoopbackPreview) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: _loading ? null : _showLoopbackQrAnyway,
                child: const Text('Show QR anyway (localhost URL)'),
              ),
            ],
          ] else ...[
            OutlinedButton.icon(
              onPressed: _loading ? null : _openPairingScanner,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scan pairing QR'),
            ),
          ],
          const SizedBox(height: 28),
          CustomButton(
            text: 'Save',
            isLoading: _loading,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

/// One-shot pairing scan for SUB terminals.
class _HubPairingScannerScreen extends StatefulWidget {
  @override
  State<_HubPairingScannerScreen> createState() => _HubPairingScannerScreenState();
}

class _HubPairingScannerScreenState extends State<_HubPairingScannerScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    for (final code in capture.barcodes) {
      final raw = code.rawValue;
      if (raw == null || raw.trim().isEmpty) continue;
      _handled = true;
      Navigator.of(context).pop(raw.trim());
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan hub pairing QR'),
      ),
      body: MobileScanner(
        onDetect: _onDetect,
      ),
    );
  }
}
