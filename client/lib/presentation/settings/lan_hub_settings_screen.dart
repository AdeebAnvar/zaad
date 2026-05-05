import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/network/lan_hub_health.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/sync/local_hub_primary_inbound_coordinator.dart';
import 'package:pos/core/sync/local_hub_sync_coordinator.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';

/// LAN hub: device role + MAIN PC IP. URL is always `ws://<ip>:3001/ws`.
class LanHubSettingsScreen extends StatefulWidget {
  const LanHubSettingsScreen({super.key});

  @override
  State<LanHubSettingsScreen> createState() => _LanHubSettingsScreenState();
}

class _LanHubSettingsScreenState extends State<LanHubSettingsScreen> {
  late final LocalHubSettings _hub;
  late bool _cashierTablet;
  late bool _skipHeavyLanMirrorIfSolitary;
  final TextEditingController _ipCtrl = TextEditingController();
  bool _loading = false;
  bool _checkingHubPeers = false;

  @override
  void initState() {
    super.initState();
    _hub = locator<LocalHubSettings>();
    _cashierTablet = _hub.isHubSub;
    _skipHeavyLanMirrorIfSolitary = _hub.skipHeavyLanMirrorUnlessExtraWsPeers;
    _ipCtrl.text = LocalHubSettings.hostFieldFromStoredWsUrl(_hub.hubWsUrl);
  }

  @override
  void dispose() {
    _ipCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ipRaw = _ipCtrl.text.trim();

    if (_cashierTablet) {
      final url = LocalHubSettings.canonicalHubWsUrl(ipRaw);
      if (url.isEmpty) {
        CustomSnackBar.showError(
          message:
              'Enter the MAIN hub IP (e.g. 192.168.1.10). Port ${LocalHubSettings.defaultHubWsPort} and path ${LocalHubSettings.defaultHubWsPath} are added automatically.',
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
        await _hub.setSkipHeavyLanMirrorUnlessExtraWsPeers(_skipHeavyLanMirrorIfSolitary);
      }

      if (locator.isRegistered<LocalHubSyncCoordinator>()) {
        await locator<LocalHubSyncCoordinator>().reconnectFromSettings();
      }
      if (locator.isRegistered<LocalHubPrimaryInboundCoordinator>()) {
        await locator<LocalHubPrimaryInboundCoordinator>().reconnectFromSettings();
      }

      if (!mounted) return;
      final summary = _cashierTablet
          ? 'Cashier uses ${LocalHubSettings.canonicalHubWsUrl(ipRaw)}'
          : (ipRaw.isEmpty
              ? 'Primary uses ${LocalHubSettings.defaultMainPublishHubLoopback} when IP is blank'
              : 'Primary uses ${LocalHubSettings.canonicalHubWsUrl(ipRaw)}');
      CustomSnackBar.showSuccess(message: 'Saved. $summary');
      Navigator.maybePop(context);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _queryHubOpenSocketCount() async {
    final wsRaw = _cashierTablet ? LocalHubSettings.canonicalHubWsUrl(_ipCtrl.text.trim()) : _hub.publishHubWsUrlOrLoopback;
    if (wsRaw.isEmpty) {
      CustomSnackBar.showError(message: _cashierTablet ? 'Enter MAIN IP first.' : 'No hub URL (set IP or defaults).');
      return;
    }
    final uri = lanHubHealthUriFromStoredWsUrl(wsRaw);
    if (uri == null) {
      CustomSnackBar.showError(message: 'Invalid hub URL.');
      return;
    }
    setState(() => _checkingHubPeers = true);
    try {
      final summary = await fetchLanHubWsHealthSummary(uri);
      if (!mounted) return;
      if (summary == null) {
        CustomSnackBar.showError(
          message: 'Could not read /health — is Node MAIN running on ${_cashierTablet ? wsRaw : uri.authority}?',
        );
        return;
      }
      final buf = StringBuffer('Open WebSockets: ${summary.openSockets}');
      for (final p in summary.peers.take(12)) {
        buf.write('\n• ${p.deviceId ?? '?'} ${p.ip ?? ''}');
      }
      if (summary.peers.length > 12) buf.write('\n…');
      CustomSnackBar.showSuccess(message: buf.toString());
    } finally {
      if (mounted) setState(() => _checkingHubPeers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
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
          ),
          const SizedBox(height: 6),
          Text(
            'Uses ws://<IP>:${LocalHubSettings.defaultHubWsPort}${LocalHubSettings.defaultHubWsPath}. '
            '${_cashierTablet ? 'Required on SUB.' : 'Leave empty if Node runs on this PC.'}',
            style: AppStyles.getRegularTextStyle(fontSize: 12, color: AppColors.hintFontColor),
          ),
          const SizedBox(height: 20),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text('SUB cashier device', style: AppStyles.getMediumTextStyle(fontSize: 15)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _cashierTablet
                    ? 'This tablet joins the MAIN hub only (no tenant cloud REST).'
                    : 'OFF = MAIN POS: tenant login/sync and sends data to the hub.',
                style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.hintFontColor),
              ),
            ),
            value: _cashierTablet,
            activeThumbColor: AppColors.primaryColor,
            onChanged: _loading
                ? null
                : (v) {
                    setState(() => _cashierTablet = v);
                  },
          ),
          if (!_cashierTablet) ...[
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Skip heavy LAN hub mirror when alone',
                style: AppStyles.getMediumTextStyle(fontSize: 15),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'When ON, MAIN asks the hub GET /health: if ws.openSockets ≤ 1 '
                  '(only this PC’s inbound link), catalog + company snapshot skips over WS '
                  '(tenant REST pull/punch unchanged). Cashier tablets still sync only via WebSocket.',
                  style: AppStyles.getRegularTextStyle(fontSize: 13, color: AppColors.hintFontColor),
                ),
              ),
              value: _skipHeavyLanMirrorIfSolitary,
              activeThumbColor: AppColors.primaryColor,
              onChanged: _loading ? null : (v) => setState(() => _skipHeavyLanMirrorIfSolitary = v),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: (_loading || _checkingHubPeers) ? null : _queryHubOpenSocketCount,
                icon: _checkingHubPeers
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.wifi_rounded),
                label: Text(_checkingHubPeers ? 'Querying hub…' : 'Show hub WebSocket count'),
              ),
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
