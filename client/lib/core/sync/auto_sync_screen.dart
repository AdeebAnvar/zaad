import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/core/settings/app_settings_prefs.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/data/repository/pull_data_repository.dart';
import 'package:pos/data/repository/push_records_repository.dart';

class AutoSyncScreen extends StatefulWidget {
  const AutoSyncScreen({
    super.key,
    this.goToDashboardOnComplete = true,
  });

  final bool goToDashboardOnComplete;

  @override
  State<AutoSyncScreen> createState() => _AutoSyncScreenState();
}

class _AutoSyncScreenState extends State<AutoSyncScreen> {
  StreamSubscription<PullSyncProgress>? _progressSub;
  Timer? _pushProgressTimer;

  void _scheduleDeferredLanHubMirror() {
    unawaited(
      locator<PullDataRepository>().runDeferredLanHubMirrorBestEffort().then(
            (_) {},
            onError: (Object e, StackTrace st) {
              if (kDebugMode) {
                debugPrint('[auto_sync] deferred LAN hub mirror: $e\n$st');
              }
            },
          ),
    );
  }

  String message = 'Preparing sync...';
  double pullProgress = 0;
  double pushProgress = 0;
  bool _pushPhase = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSync());
  }

  void _startPushProgressTicker() {
    _pushProgressTimer?.cancel();
    _pushProgressTimer = Timer.periodic(const Duration(milliseconds: 140), (_) {
      if (!mounted) return;
      setState(() {
        if (pushProgress < 0.92) {
          pushProgress = (pushProgress + 0.035).clamp(0.0, 0.92);
        }
      });
    });
  }

  Future<void> _cancelPullSubscription() async {
    await _progressSub?.cancel();
    _progressSub = null;
  }

  Future<void> _executeTenantPullAndPush() async {
    final repo = locator<PullDataRepository>();

    setState(() {
      message = 'Pulling data from server...';
      pullProgress = 0.0;
      pushProgress = 0.0;
      _pushPhase = false;
    });

    await _cancelPullSubscription();
    _progressSub = repo.progressStream.listen((e) {
      if (!mounted) return;

      final total = e.total <= 0 ? 1 : e.total;
      final target = (e.current / total).clamp(0.0, 1.0);

      final p = target > pullProgress ? target : (target < 1.0 ? (pullProgress + 0.003).clamp(0.0, 0.98) : 1.0);

      setState(() {
        message = e.message;
        pullProgress = p;
      });
    });

    try {
      await repo.pullAndPersist(deferLanHubMirrorUntilAfterCloudSync: true);
      await AppSettingsPrefs.setLastManualSyncAt(DateTime.now());
      await RuntimeAppSettings.refreshFromLocalSettings();

      if (mounted) {
        setState(() {
          pullProgress = 1.0;
          _pushPhase = true;
          message = 'Pushing sales to server...';
          pushProgress = 0.0;
        });
      } else if (kDebugMode) {
        debugPrint('[auto_sync] widget not mounted before push — still calling push_records');
      }

      _startPushProgressTicker();

      final pushOut = await locator<PushRecordsRepository>().pushSalesAndCreditSalesFromLocal();
      _pushProgressTimer?.cancel();
      _pushProgressTimer = null;
      _scheduleDeferredLanHubMirror();

      if (kDebugMode) {
        debugPrint(
          '[auto_sync] push outcome ok=${pushOut.ok} orders=${pushOut.ordersPosted} http=${pushOut.httpStatus}',
        );
      }

      if (!mounted) return;

      setState(() {
        pushProgress = 1.0;
        message = !pushOut.ok
            ? 'Pull OK · push failed (${pushOut.message})'
            : pushOut.ordersPosted <= 0
                ? 'Sync completed · push OK (no pending sales)'
                : 'Sync completed · pushed ${pushOut.ordersPosted} sale(s)';
      });

      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) await _goToDashboard();
    } catch (e) {
      _pushProgressTimer?.cancel();
      _pushProgressTimer = null;
      _scheduleDeferredLanHubMirror();
      if (!mounted) return;

      setState(() {
        message = 'Sync failed: $e';
        pullProgress = _pushPhase ? 1.0 : pullProgress;
        pushProgress = _pushPhase ? pushProgress : 0.0;
      });

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) await _goToDashboard();
    } finally {
      await _cancelPullSubscription();
      _pushProgressTimer?.cancel();
      _pushProgressTimer = null;
    }
  }

  Future<void> _startSync() async {
    if (locator<LocalHubSettings>().blocksTenantCloudRest) {
      if (!mounted) return;
      setState(() {
        message =
            'LAN SUB mode: tenant cloud sync is disabled. Inventory and orders reach this device through the MAIN hub (WebSocket) only.';
        pullProgress = 1;
        pushProgress = 1;
        _pushPhase = true;
      });
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) await _goToDashboard();
      return;
    }
    await _executeTenantPullAndPush();
  }

  Future<void> _goToDashboard() async {
    if (widget.goToDashboardOnComplete) {
      AppNavigator.pushReplacementNamed('/dashboard');
      return;
    }
    AppNavigator.pop();
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    _pushProgressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: AppPadding.screenAll,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SyncProgressCard(
                  primary: primary,
                  pullProgress: pullProgress,
                  pushProgress: pushProgress,
                  pushStarted: _pushPhase,
                ),
                const SizedBox(height: 28),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    message,
                    key: ValueKey(message),
                    textAlign: TextAlign.center,
                    style: AppStyles.getBoldTextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please keep the app open',
                  style: AppStyles.getRegularTextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SyncProgressCard extends StatelessWidget {
  const _SyncProgressCard({
    required this.primary,
    required this.pullProgress,
    required this.pushProgress,
    required this.pushStarted,
  });

  final Color primary;
  final double pullProgress;
  final double pushProgress;
  final bool pushStarted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 440),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 30,
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_sync_rounded, size: 40, color: primary),
          const SizedBox(height: 20),
          _SyncLinearBar(
            label: 'Pull',
            value: pullProgress.clamp(0.0, 1.0),
            active: true,
            color: primary,
          ),
          const SizedBox(height: 22),
          _SyncLinearBar(
            label: 'Push',
            value: pushProgress.clamp(0.0, 1.0),
            active: pushStarted,
            color: primary,
          ),
        ],
      ),
    );
  }
}

class _SyncLinearBar extends StatelessWidget {
  const _SyncLinearBar({
    required this.label,
    required this.value,
    required this.active,
    required this.color,
  });

  final String label;
  final double value;
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = active ? '${(value * 100).round()}%' : '—';
    final trackColor = Colors.grey.shade200;
    final barColor = active ? color : Colors.grey.shade400;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppStyles.getSemiBoldTextStyle(fontSize: 14, color: active ? null : Colors.grey.shade600),
            ),
            Text(
              pct,
              style: AppStyles.getBoldTextStyle(fontSize: 14, color: active ? null : Colors.grey.shade500),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: active ? value : 0,
            minHeight: 10,
            backgroundColor: trackColor,
            color: barColor,
          ),
        ),
      ],
    );
  }
}
