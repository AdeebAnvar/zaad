import 'dart:async';
import 'dart:io';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:pos/app/di.dart';
import 'package:pos/core/services/backup_service.dart';
import 'package:pos/core/sync/lan_hub_reconnect_service.dart';
import 'package:pos/core/sync/local_hub_primary_inbound_coordinator.dart';
import 'package:pos/core/sync/local_hub_sync_coordinator.dart';
import 'package:pos/core/sync/outbound_push_coordinator.dart';
import 'package:pos/core/update/updater_manager.dart';
import 'package:pos/core/utils/sales_csv_backup.dart';
import 'package:pos/data/local/drift_database.dart';

/// Process-exit cleanup (Windows / macOS / Linux). Avoids backup WAL-checkpoint + hub I/O racing [AppDatabase.close].
AppLifecycleListener? _desktopExitListener;
bool _desktopExitHookInstalled = false;
bool _shutdownInProgress = false;

bool _isFlutterTestBinding() {
  try {
    return WidgetsBinding.instance.runtimeType.toString().contains('TestWidgets');
  } on Object {
    return false;
  }
}

Future<void> _shutdownForDesktopExit() async {
  if (_shutdownInProgress) return;
  _shutdownInProgress = true;
  try {
    BackupService.instance.prepareForExit();
    SalesCsvBackup.cancelScheduledDebouncedRefresh();

    if (!locator.isRegistered<AppDatabase>()) return;

    if (locator.isRegistered<OutboundPushCoordinator>()) {
      locator<OutboundPushCoordinator>().dispose();
    }
    if (locator.isRegistered<LanHubReconnectService>()) {
      locator<LanHubReconnectService>().dispose();
    }
    if (locator.isRegistered<LocalHubSyncCoordinator>()) {
      locator<LocalHubSyncCoordinator>().stop();
    }
    if (locator.isRegistered<LocalHubPrimaryInboundCoordinator>()) {
      locator<LocalHubPrimaryInboundCoordinator>().stop();
    }

    if (locator.isRegistered<UpdaterManager>()) {
      locator<UpdaterManager>().disposeIdleMonitorOnly();
    }

    try {
      await locator<AppDatabase>().close().timeout(const Duration(seconds: 5));
    } on TimeoutException catch (_) {
      if (kDebugMode) {
        debugPrint('[DesktopExit] database.close() timed out — proceeding with exit');
      }
    } on Object catch (e, st) {
      if (kDebugMode) {
        debugPrint('[DesktopExit] database.close() failed: $e\n$st');
      }
    }
  } on Object catch (e, st) {
    if (kDebugMode) {
      debugPrint('[DesktopExit] shutdown error: $e\n$st');
    }
  }
}

/// Fallback when the embedder does not drive [AppLifecycleListener.onExitRequested].
class _DetachShutdownObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      unawaited(_shutdownForDesktopExit());
    }
  }
}

final _detachShutdownObserver = _DetachShutdownObserver();

/// Register [AppLifecycleListener.onExitRequested] so closing the window can drain I/O before the engine tears down.
void installDesktopExitGracefulShutdown() {
  if (kIsWeb) return;
  if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;
  if (_desktopExitHookInstalled) return;
  if (_isFlutterTestBinding()) return;

  _desktopExitHookInstalled = true;
  WidgetsBinding.instance.addObserver(_detachShutdownObserver);

  _desktopExitListener?.dispose();
  _desktopExitListener = AppLifecycleListener(
    onExitRequested: () async {
      await _shutdownForDesktopExit();
      return AppExitResponse.exit;
    },
  );
}
