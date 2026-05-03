import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/app/routes.dart';
import 'package:pos/core/config/app_mode.dart';
import 'package:pos/core/config/lan_pos_role.dart';
import 'package:pos/core/config/pos_app_runtime_config.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/network/base_url_resolver.dart';
import 'package:pos/core/network/pos_server_settings.dart';
import 'package:pos/presentation/setup/setup_hub_socket.dart';
import 'package:pos/presentation/widgets/custom_button.dart';
import 'package:pos/presentation/widgets/custom_textfield.dart';

/// First-run / admin: choose **Cloud** vs **Local POS**; local uses **POS-SERVER** hostname first, optional IP fallback.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _fallbackIpController = TextEditingController();

  late AppMode _mode;
  late LanPosRole _lanRole;
  bool _busy = false;

  /// LOCAL only — must run **Test connection** successfully before save.
  bool _healthOk = false;
  String? _resolvedHubUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    final cfg = locator<PosAppRuntimeConfig>();
    _mode = cfg.mode;
    _lanRole = cfg.lanPosRole;
    _healthOk = _mode == AppMode.cloud;
    final fb = cfg.fallbackBaseUrl;
    if ((fb ?? '').isNotEmpty) {
      _fallbackIpController.text = fb!;
    }
  }

  @override
  void dispose() {
    _fallbackIpController.dispose();
    super.dispose();
  }

  void _onModeChanged(AppMode m) {
    setState(() {
      _mode = m;
      if (m == AppMode.cloud) {
        _lanRole = LanPosRole.hubHost;
      }
      _error = null;
      _healthOk = m == AppMode.cloud;
      _resolvedHubUrl = null;
    });
  }

  void _onLanRoleChanged(LanPosRole r) {
    setState(() {
      _lanRole = r;
      _error = null;
      if (r == LanPosRole.satellite) {
        _mode = AppMode.local;
        _healthOk = false;
        _resolvedHubUrl = null;
      }
    });
  }

  String? _normalizeLanRoot(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return null;
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      s = 'http://$s';
    }
    final u = Uri.tryParse(s);
    if (u == null || u.host.isEmpty) return null;
    if (!u.hasPort || u.port == 0) {
      return PosServerSettings.normalizeRoot(
        '${u.scheme}://${u.host}:${PosAppRuntimeConfig.preferredPort}',
      );
    }
    return PosServerSettings.normalizeRoot(s);
  }

  Future<void> _testConnection() async {
    final cfg = locator<PosAppRuntimeConfig>();
    final resolver = locator<BaseUrlResolver>();

    final manual = _normalizeLanRoot(_fallbackIpController.text);
    if (manual != null) {
      await cfg.setFallbackBaseUrl(manual);
    } else {
      await cfg.clearFallbackBaseUrl();
    }

    setState(() {
      _busy = true;
      _error = null;
      _healthOk = false;
      _resolvedHubUrl = null;
    });

    try {
      final url = await resolver.resolveLocalBaseUrl();
      if (!mounted) return;
      setState(() {
        _healthOk = true;
        _resolvedHubUrl = url;
        _busy = false;
        _error = null;
      });
      debugPrint('[POS] Setup test OK → selected hub $url');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _healthOk = false;
        _resolvedHubUrl = null;
        _error = '$e';
      });
      debugPrint('[POS] Setup test failed: $e');
    }
  }

  Future<void> _saveAndGoLogin() async {
    if (_mode == AppMode.cloud && _lanRole == LanPosRole.satellite) {
      setState(
        () => _error =
            'Sub terminals cannot use Cloud mode. Choose Local POS and connect to the main PC.',
      );
      return;
    }
    if (_mode == AppMode.local && !_healthOk) {
      setState(() => _error = 'Run “Test connection” successfully first.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final cfg = locator<PosAppRuntimeConfig>();
      final hub = locator<PosServerSettings>();

      await cfg.setMode(_mode);
      await cfg.setLanPosRole(_lanRole);

      if (_mode == AppMode.local) {
        final url = _resolvedHubUrl;
        if (url == null || url.isEmpty) {
          throw StateError('No resolved hub URL');
        }
        await hub.setBaseUrl(url);
        final manual = _normalizeLanRoot(_fallbackIpController.text);
        if (manual != null) {
          await cfg.setFallbackBaseUrl(manual);
        }
      }

      await cfg.markSetupCompleted();

      cfg.logDiagnostics();
      debugPrint('[POS] BASE URL (hub HTTP) after setup: ${hub.hubRoot ?? '(none)'}');

      await applyHubSocketAfterLocalSetupChange();

      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        AppNavigator.pushReplacementNamed(Routes.login);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool get _saveEnabled {
    if (_busy) return false;
    if (_mode == AppMode.cloud) return true;
    return _healthOk;
  }

  @override
  Widget build(BuildContext context) {
    final preferredLan =
        'http://${PosAppRuntimeConfig.preferredHost}:${PosAppRuntimeConfig.preferredPort}';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              AppNavigator.pushReplacementNamed(Routes.login);
            }
          },
        ),
        title: Text('POS setup', style: AppStyles.getSemiBoldTextStyle(fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Step 1 — Deployment mode',
                  style: AppStyles.getSemiBoldTextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ModeCard(
                        title: 'Cloud mode',
                        subtitle: 'Tenant sync + optional LAN hub',
                        selected: _mode == AppMode.cloud,
                        onTap: () => _onModeChanged(AppMode.cloud),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ModeCard(
                        title: 'Local POS',
                        subtitle: 'LAN Node · $preferredLan',
                        selected: _mode == AppMode.local,
                        onTap: () => _onModeChanged(AppMode.local),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Step 2 — Device role',
                  style: AppStyles.getSemiBoldTextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Main PC runs Node and syncs with the cloud. Sub devices only talk to that PC on LAN.',
                  style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ModeCard(
                        title: 'Main / till',
                        subtitle: 'This machine (Node or head terminal)',
                        selected: _lanRole == LanPosRole.hubHost,
                        onTap: () => setState(() {
                          _lanRole = LanPosRole.hubHost;
                          _error = null;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ModeCard(
                        title: 'Sub device',
                        subtitle: 'Extra terminal — LAN only, no cloud',
                        selected: _lanRole == LanPosRole.satellite,
                        onTap: () => _onLanRoleChanged(LanPosRole.satellite),
                      ),
                    ),
                  ],
                ),
                if (_mode == AppMode.local) ...[
                  const SizedBox(height: 28),
                  Text(
                    'Step 3 — LAN server',
                    style: AppStyles.getSemiBoldTextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Auto-detect server ($preferredLan). '
                    'Optional: manual IP or URL below only if the hostname does not resolve.',
                    style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _fallbackIpController,
                    labelText: 'Optional fallback (IP or URL)',
                    prefixIcon: const Icon(Icons.edit_location_alt_outlined),
                    onChanged: (_) {
                      setState(() {
                        _healthOk = false;
                        _resolvedHubUrl = null;
                        _error = null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: _busy ? 'Testing…' : 'Test connection',
                    onPressed: _busy ? null : _testConnection,
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Scan QR to connect',
                    backgroundColor: Colors.white,
                    textColor: AppColors.primaryColor,
                    elevation: 0,
                    onPressed: _busy
                        ? null
                        : () => AppNavigator.pushNamed(Routes.setupQrScan),
                  ),
                  const SizedBox(height: 10),
                  CustomButton(
                    text: 'Show QR for other devices',
                    backgroundColor: Colors.white,
                    textColor: AppColors.primaryColor,
                    elevation: 0,
                    onPressed: () => AppNavigator.pushNamed(Routes.setupQrGenerate),
                  ),
                  const SizedBox(height: 8),
                  if (_healthOk && (_resolvedHubUrl ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Reachable at $_resolvedHubUrl',
                              style: AppStyles.getMediumTextStyle(fontSize: 13, color: Colors.green.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: 28),
                Text(
                  'Step 4 — Save',
                  style: AppStyles.getSemiBoldTextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: AppStyles.getRegularTextStyle(fontSize: 13, color: Colors.red.shade800),
                    ),
                  ),
                CustomButton(
                  text: _busy ? 'Saving…' : 'Save & continue',
                  onPressed: (!_saveEnabled || _busy) ? null : _saveAndGoLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected ? AppColors.primaryColor : Colors.grey.shade300;
    return Material(
      color: selected ? AppColors.primaryColor.withValues(alpha: 0.06) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border, width: selected ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppStyles.getSemiBoldTextStyle(fontSize: 14)),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: AppStyles.getRegularTextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
