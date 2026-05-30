import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/utils/app_directories.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shown on Android before cold start when [Documents/ZaadPOS] needs "All files access".
///
/// That permission does **not** appear under the normal app Permissions list on Android 11+.
/// It lives under **Special app access → All files access**.
class AndroidStorageStartupGate extends StatefulWidget {
  const AndroidStorageStartupGate({
    super.key,
    required this.onReady,
  });

  final VoidCallback onReady;

  static const skipInternalOnlyKey = 'zaadpos_android_storage_use_internal_only';

  static Future<bool> shouldShow() async {
    if (!Platform.isAndroid) return false;
    // Android 6–10: normal permission dialog — no special-access screen.
    if (!await AppDirectories.androidNeedsAllFilesAccessGate()) return false;
    if (await AppDirectories.androidHasAllFilesAccess()) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(skipInternalOnlyKey) != true;
  }

  @override
  State<AndroidStorageStartupGate> createState() => _AndroidStorageStartupGateState();
}

class _AndroidStorageStartupGateState extends State<AndroidStorageStartupGate>
    with WidgetsBindingObserver {
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_recheckAfterSettings());
    }
  }

  Future<void> _recheckAfterSettings() async {
    if (_checking || !mounted) return;
    _checking = true;
    try {
      AppDirectories.clearRuntimeProbeCache();
      if (await AppDirectories.androidHasAllFilesAccess()) {
        widget.onReady();
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> _openSettings() async {
    await AppDirectories.openAndroidAllFilesAccessSettings();
  }

  Future<void> _continueWithInternalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AndroidStorageStartupGate.skipInternalOnlyKey, true);
    AppDirectories.clearRuntimeProbeCache();
    if (mounted) widget.onReady();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.scaffoldColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Image.asset(
                    'assets/images/png/appicon2.webp',
                    width: 72,
                    height: 72,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Storage access',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                const Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      'Zaad POS saves its database in Documents/ZaadPOS.\n\n'
                      'On Android 11 through Android 16 this is not a normal permission '
                      'popup — it will not appear under Apps → Zaad POS → Permissions.\n\n'
                      'Enable it here:\n'
                      '1. Tap "Open storage settings" below\n'
                      '2. Turn ON "Allow access to manage all files" for Zaad POS\n'
                      '3. Return to this app (we continue automatically)\n\n'
                      'Or tap "Continue without" — the app still works using private '
                      'storage (no Documents folder).',
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: _openSettings,
                  child: const Text('Open storage settings'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _continueWithInternalStorage,
                  child: const Text('Continue without Documents folder'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
