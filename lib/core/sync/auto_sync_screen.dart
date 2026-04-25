import 'dart:math' show pi;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos/app/di.dart';
import 'package:pos/app/navigation.dart';
import 'package:pos/core/settings/app_settings_prefs.dart';
import 'package:pos/core/settings/runtime_app_settings.dart';
import 'package:pos/core/constants/styles.dart';
import 'package:pos/data/repository/pull_data_repository.dart';

class AutoSyncScreen extends StatefulWidget {
  const AutoSyncScreen({
    super.key,
    this.goToDashboardOnComplete = true,
  });

  final bool goToDashboardOnComplete;

  @override
  State<AutoSyncScreen> createState() => _AutoSyncScreenState();
}

class _AutoSyncScreenState extends State<AutoSyncScreen> with SingleTickerProviderStateMixin {
  StreamSubscription<PullSyncProgress>? _progressSub;

  String message = 'Preparing sync...';
  double progress = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSync());
  }

  Future<void> _startSync() async {
    final repo = locator<PullDataRepository>();

    setState(() {
      message = 'Pulling data from server...';
      progress = 0.0;
    });

    _progressSub = repo.progressStream.listen((e) {
      if (!mounted) return;

      final total = e.total <= 0 ? 1 : e.total;
      final target = (e.current / total).clamp(0.0, 1.0);

      final p = target > progress ? target : (target < 1.0 ? (progress + 0.003).clamp(0.0, 0.98) : 1.0);

      setState(() {
        message = e.message;
        progress = p;
      });
    });

    try {
      await repo.pullAndPersist();
      await AppSettingsPrefs.setLastManualSyncAt(DateTime.now());
      await RuntimeAppSettings.refreshFromLocalSettings();

      if (!mounted) return;

      setState(() {
        message = 'Sync completed';
        progress = 1.0;
      });

      await Future.delayed(const Duration(milliseconds: 600));

      if (mounted) await _goToDashboard();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        message = 'Sync failed: $e';
        progress = 0;
      });

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) await _goToDashboard();
    } finally {
      await _progressSub?.cancel();
      _progressSub = null;
    }
  }

  Future<void> _goToDashboard() async {
    if (widget.goToDashboardOnComplete) {
      AppNavigator.pushReplacementNamed("/dashboard");
      return;
    }
    AppNavigator.pop();
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                _AnimatedCardLoader(progress: progress),
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

class _AnimatedCardLoader extends StatelessWidget {
  final double progress;

  const _AnimatedCardLoader({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            blurRadius: 30,
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ModernSyncLoader(progress: progress),
    );
  }
}

class ModernSyncLoader extends StatefulWidget {
  final double progress;

  const ModernSyncLoader({super.key, required this.progress});

  @override
  State<ModernSyncLoader> createState() => _ModernSyncLoaderState();
}

class _ModernSyncLoaderState extends State<ModernSyncLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return Transform.rotate(
              angle: _controller.value * 2 * pi,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: widget.progress,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation(primary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.cloud_sync_rounded,
                      size: 32,
                      color: primary,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: widget.progress),
          duration: const Duration(milliseconds: 300),
          builder: (_, value, __) {
            return Text(
              '${(value * 100).toInt()}%',
              style: AppStyles.getBoldTextStyle(fontSize: 20),
            );
          },
        ),
      ],
    );
  }
}
