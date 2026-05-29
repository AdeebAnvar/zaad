import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:pos/app/app.dart';
import 'package:pos/app/app_startup.dart';
import 'package:pos/app/di.dart';
import 'package:pos/app/post_login_deferred_startup.dart';
import 'package:pos/core/auth/counter_access.dart';
import 'package:pos/core/constants/colors.dart';
import 'package:pos/core/constants/enums.dart';
import 'package:pos/core/utils/android_storage_startup_gate.dart';
import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/data/local/drift_database.dart';

/// Shows UI immediately, then runs cold-start work so a blocked DB does not look
/// like "the shortcut does nothing".
class PosBootstrapRoot extends StatefulWidget {
  const PosBootstrapRoot({super.key});

  @override
  State<PosBootstrapRoot> createState() => _PosBootstrapRootState();
}

class _PosBootstrapRootState extends State<PosBootstrapRoot> {
  Widget _child = const _StartupSplash(status: 'Starting Zaad POS…');
  bool _coldStartStarted = false;

  void _setStartupStatus(String status) {
    if (!mounted) return;
    setState(() => _child = _StartupSplash(status: status));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_beginStartup());
    });
  }

  Future<void> _beginStartup() async {
    if (!Platform.isAndroid) {
      await _runColdStart();
      return;
    }
    // Android 6–10: system storage dialog. Android 11–16: startup gate or internal fallback.
    await AppDirectories.requestLegacyAndroidStoragePermission();
    if (!await AndroidStorageStartupGate.shouldShow()) {
      await _runColdStart();
      return;
    }
    if (!mounted) return;
    setState(() {
      _child = AndroidStorageStartupGate(
        onReady: () {
          if (_coldStartStarted) return;
          _coldStartStarted = true;
          unawaited(_runColdStart());
        },
      );
    });
  }

  Future<void> _runColdStart() async {
    await Future<void>.delayed(Duration.zero);
    try {
      final boot = await coldStartBootstrap(onStatus: _setStartupStatus);
      if (!mounted) return;
      setState(() {
        _child = ZaadPOSApp(
          userType: boot.userType,
          initialRouteOverride: boot.setupRoute,
        );
      });
      PostLoginDeferredStartup.scheduleAfterFirstFrame(
        landedOnLogin: boot.userType == null,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[PosBootstrap] failed: $e\n$st');
      }
      if (!mounted) return;
      setState(() {
        _child = _StartupErrorScreen(
          message: _userFacingBootstrapError(e),
        );
      });
    }
  }

  static String _userFacingBootstrapError(Object e) {
    final text = e.toString();
    if (text.contains('database is busy') ||
        text.contains('Database is busy') ||
        text.contains('could not open its database') ||
        text.contains('could not open its local database')) {
      return text.contains('Database folder:') || text.contains('database folder:')
          ? text.replaceFirst('StateError: ', '')
          : 'Zaad POS could not open its local database.\n\n'
              '1. Open Task Manager → end every "pos" task (Details tab too).\n'
              '2. Wait 10 seconds.\n'
              '3. If Documents is on OneDrive, pause sync or move ZaadPOS to C:\\ZaadPOS.\n'
              '4. Open Zaad POS again.\n\n'
              'If this keeps happening, restart the PC.\n\n'
              'Technical detail:\n$text';
    }
    if (text.contains('unable to open database') ||
        text.contains('SqliteException(14)')) {
      return 'Zaad POS could not create or open its database file.\n\n'
          'This often happens on Android when storage permission is not granted, '
          'or after deleting the ZaadPOS folder.\n\n'
          'Try:\n'
          '1. Settings → Apps → Special app access → All files access → Zaad POS → Allow\n'
          '   (this is NOT listed under normal app Permissions on Android 11+)\n'
          '2. Or tap "Continue without Documents folder" on the first screen\n'
          '3. Reopen the app\n\n'
          'Technical detail:\n$text';
    }
    if (text.contains('PathNotFoundException') ||
        text.contains('cannot find the file specified') ||
        text.contains('No writable folder')) {
      return 'Zaad POS could not create its data folder.\n\n'
          'This often happens when Windows Documents is set to a missing OneDrive '
          'path (for example D:\\Onedrive\\Documents).\n\n'
          'Try one of these:\n'
          '• In Windows Settings → Accounts → OneDrive, sign in or fix the folder location\n'
          '• Or move Documents back to C:\\Users\\<name>\\Documents\n'
          '• Then open Zaad POS again\n\n'
          'Technical detail:\n$text';
    }
    return 'Zaad POS could not start.\n\n$text';
  }

  @override
  Widget build(BuildContext context) => _child;
}

@immutable
class ColdStartBootstrapResult {
  const ColdStartBootstrapResult({this.userType, this.setupRoute});

  final UserType? userType;
  final String? setupRoute;
}

/// Minimal work before the login (or dashboard) route is shown. Heavy tasks run via
/// [PostLoginDeferredStartup].
Future<ColdStartBootstrapResult> coldStartBootstrap({
  void Function(String status)? onStatus,
}) async {
  Future<void> yieldUi() async {
    await Future<void>.delayed(Duration.zero);
    await SchedulerBinding.instance.endOfFrame;
  }

  void status(String s) => onStatus?.call(s);

  status(Platform.isAndroid ? 'Checking storage access…' : 'Preparing data folder…');
  if (Platform.isAndroid) {
    await AppDirectories.prepareAndroidStorageBeforeDatabaseOpen();
  }
  await AppDirectories.local();
  await yieldUi();

  status('Opening database…');
  await ZaadDI.initialize();
  await yieldUi();

  final db = locator<AppDatabase>();
  await db.sessionDao.clearSession();
  locator<CurrentCounterSession>().clear();

  status('Almost ready…');
  final startup = AppStartup(db);
  final userType = await startup.checkLoggedInUser();
  final setupRoute = userType == null ? ZaadDI.consumePendingInitialRoute() : null;

  return ColdStartBootstrapResult(userType: userType, setupRoute: setupRoute);
}

class _StartupSplash extends StatelessWidget {
  const _StartupSplash({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.scaffoldColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/png/appicon2.webp',
                  width: 72,
                  height: 72,
                ),
                const SizedBox(height: 20),
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.message});

  final String message;

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
                Text(
                  'Could not start',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(message),
                  ),
                ),
                if (Platform.isWindows)
                  FilledButton(
                    onPressed: () => exit(0),
                    child: const Text('Close'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

