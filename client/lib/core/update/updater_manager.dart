import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:pos/app/navigation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:pos/app/di.dart';
import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/core/services/backup_service.dart';
import 'package:pos/core/sync/local_hub_primary_inbound_coordinator.dart';
import 'package:pos/core/sync/local_hub_sync_coordinator.dart';
import 'package:pos/core/sync/outbound_push_coordinator.dart';
import 'package:pos/core/utils/app_directories.dart';
import 'package:pos/core/utils/network_utils.dart';
import 'package:pos/data/local/drift_database.dart';

import 'update_model.dart';
import 'update_service.dart';

enum InstallReason { idleTimer, manual }

/// UI-safe snapshot for banner + progress overlay.
class UpdaterBannerState {
  const UpdaterBannerState({
    required this.phase,
    this.message,
    this.progress,
    this.foregroundBusy = false,
  });

  final UpdaterBannerPhase phase;
  final String? message;

  /// 0–1 download progress (`null` = indeterminate banner text only).
  final double? progress;
  final bool foregroundBusy;

  bool get visible =>
      foregroundBusy ||
      phase == UpdaterBannerPhase.available ||
      phase == UpdaterBannerPhase.downloading ||
      phase == UpdaterBannerPhase.ready ||
      phase == UpdaterBannerPhase.installing ||
      phase == UpdaterBannerPhase.error;

  const UpdaterBannerState.idle({String? message})
      : this(phase: UpdaterBannerPhase.idle, message: message);

  factory UpdaterBannerState.downloading(
      {required String message, double? progress}) {
    return UpdaterBannerState(
      phase: UpdaterBannerPhase.downloading,
      message: message,
      progress: progress,
      foregroundBusy: true,
    );
  }

  factory UpdaterBannerState.ready(String msg) =>
      UpdaterBannerState(phase: UpdaterBannerPhase.ready, message: msg);

  factory UpdaterBannerState.available(String msg) =>
      UpdaterBannerState(phase: UpdaterBannerPhase.available, message: msg);

  factory UpdaterBannerState.error(String msg) =>
      UpdaterBannerState(phase: UpdaterBannerPhase.error, message: msg);
}

enum UpdaterBannerPhase {
  idle,
  available,
  downloading,
  ready,
  installing,
  error
}

class UpdateCheckOutcome {
  const UpdateCheckOutcome({
    required this.updateAvailable,
    required this.manifest,
    required this.currentVersion,
    required this.message,
  });

  final bool updateAvailable;
  final RemoteUpdateManifest? manifest;
  final String currentVersion;

  /// Human-readable diagnostics (shown only on debug banners / tooling).
  final String message;
}

class InstallEligibility {
  const InstallEligibility._({
    required this.isOk,
    this.blockReason,
  });

  final bool isOk;
  final String? blockReason;

  factory InstallEligibility.ok() => const InstallEligibility._(isOk: true);

  factory InstallEligibility.blocked(String reason) =>
      InstallEligibility._(isOk: false, blockReason: reason);
}

/// Enterprise Windows updater — coordinates manifests, Dio downloads, guarded install.
///
/// **Post-install app launch:** Configure Inno Setup `[Run]` to start the POS executable;
/// [/NORESTART] suppresses rebooting Windows, not restarting your SKU.
class UpdaterManager {
  UpdaterManager({required AppDatabase database, UpdateService? updateService})
      : _db = database,
        _updateService = updateService ?? UpdateService();

  final AppDatabase _db;
  final UpdateService _updateService;

  CancelToken? _downloadCancelToken;

  RemoteUpdateManifest? _pendingManifest;
  String? _downloadedInstallerPath;

  ValueNotifier<double> downloadProgressNotifier = ValueNotifier<double>(0);
  ValueNotifier<UpdaterBannerState> bannerNotifier =
      ValueNotifier<UpdaterBannerState>(const UpdaterBannerState.idle());

  bool _billingLikelyBusy = false;
  bool _installLifecycleActive = false;
  bool _didPromptForPendingUpdate = false;
  bool _promptDialogOpen = false;

  static bool _didScheduleColdStartCheck = false;

  /// Registers a one-shot post-frame update sweep (manifest + downloader).
  static void scheduleColdStartCheckOnce() {
    if (_didScheduleColdStartCheck) return;
    if (!Platform.isWindows) return;
    _didScheduleColdStartCheck = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!locator.isRegistered<UpdaterManager>()) return;
      unawaited(locator<UpdaterManager>().beginStartupWorkflow());
    });
  }

  RemoteUpdateManifest? get pendingManifest => _pendingManifest;
  String? get downloadedInstallerPath => _downloadedInstallerPath;

  /// Active sale / checkout / tender — defer silent install whenever this stays true.
  void reportBillingGate(bool billingOrSaleInFlight) {
    if (!Platform.isWindows) return;
    if (_billingLikelyBusy == billingOrSaleInFlight) return;
    _billingLikelyBusy = billingOrSaleInFlight;
  }

  Widget wrapAppWithUpdateLayers(Widget child) {
    if (!Platform.isWindows) return child;
    return ValueListenableBuilder<UpdaterBannerState>(
      valueListenable: bannerNotifier,
      builder: (context, banner, _) {
        if (banner.phase == UpdaterBannerPhase.available) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final navigatorContext =
                AppNavigator.navigatorKey.currentState?.context;
            if (navigatorContext != null && navigatorContext.mounted) {
              unawaited(promptForUpdate(navigatorContext, automatic: true));
            }
          });
        }
        final stack = child;
        if (!banner.visible) return stack;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _UpdateBanner(state: banner),
            Expanded(child: stack),
          ],
        );
      },
    );
  }

  void _emitBanner(UpdaterBannerState s) => bannerNotifier.value = s;

  void _log(String m) {
    if (kDebugMode) debugPrint('[UpdaterManager] $m');
  }

  Future<void> beginStartupWorkflow() async {
    if (!Platform.isWindows) return;

    try {
      if (!await NetworkUtils.hasInternetConnection()) {
        _emitBanner(const UpdaterBannerState.idle(
            message: 'Offline — skipping update check'));
        return;
      }

      final outcome = await checkForUpdates();
      if (!outcome.updateAvailable || outcome.manifest == null) {
        if (outcome.message.isNotEmpty) {
          _emitBanner(UpdaterBannerState.idle(message: outcome.message));
        }
        return;
      }

      _pendingManifest = outcome.manifest!;
      _emitBanner(
        UpdaterBannerState.available(
          'Update ${outcome.manifest!.version} available — tap the update icon to install.',
        ),
      );
    } catch (e, st) {
      _log('startup workflow failed: $e\n$st');
      _emitBanner(UpdaterBannerState.error(e.toString()));
    }
  }

  Future<void> promptForUpdate(BuildContext context,
      {bool automatic = false}) async {
    if (!Platform.isWindows) return;
    final manifest = _pendingManifest;
    if (manifest == null || _installLifecycleActive) return;
    if (automatic && _didPromptForPendingUpdate) return;
    if (_promptDialogOpen) return;

    _promptDialogOpen = true;
    if (automatic) _didPromptForPendingUpdate = true;

    try {
      if ((_downloadedInstallerPath ?? '').isNotEmpty) {
        final installNow = await _confirmInstallNow(context, manifest);
        if (installNow == true) {
          await installUpdate(reason: InstallReason.manual);
        }
        return;
      }

      final shouldUpdate = await _confirmDownloadUpdate(context, manifest);
      if (shouldUpdate != true) {
        _emitBanner(
          UpdaterBannerState.available(
            'Update ${manifest.version} available — tap the update icon to install.',
          ),
        );
        return;
      }

      await downloadUpdate(manifest);
      if (!context.mounted) return;
      final installNow = await _confirmInstallNow(context, manifest);
      if (installNow == true) {
        await installUpdate(reason: InstallReason.manual);
      }
    } catch (e, st) {
      _log('user update flow failed: $e\n$st');
      _emitBanner(UpdaterBannerState.error(e.toString()));
    } finally {
      _promptDialogOpen = false;
    }
  }

  Future<bool?> _confirmDownloadUpdate(
    BuildContext context,
    RemoteUpdateManifest manifest,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update available'),
          content: Text(
            'Version ${manifest.version} is available. Do you want to download and update now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Update Now'),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _confirmInstallNow(
    BuildContext context,
    RemoteUpdateManifest manifest,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Install update?'),
          content: Text(
            'Update ${manifest.version} is downloaded. POS will close while the installer runs.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Install Later'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Install Now'),
            ),
          ],
        );
      },
    );
  }

  Future<InstallEligibility> canInstallUpdate() async {
    if (!Platform.isWindows) {
      return InstallEligibility.blocked('Not Windows');
    }
    if (_billingLikelyBusy) {
      return InstallEligibility.blocked('Billing or checkout in progress');
    }
    if ((_downloadedInstallerPath ?? '').isEmpty) {
      return InstallEligibility.blocked('Installer not downloaded yet');
    }
    final exe = File(_downloadedInstallerPath!);
    if (!await exe.exists()) {
      return InstallEligibility.blocked(
          'Installer file missing — redownload needed');
    }

    try {
      if (await _db.pendingActionsDao.countPending() > 0) {
        return InstallEligibility.blocked('Pending hub/offline mutations');
      }

      final lanOutstanding = await _db.syncQueueDao.unsyncedOutboxCount();
      if (lanOutstanding > 0) {
        return InstallEligibility.blocked(
            'LAN hub sync pending ($lanOutstanding)');
      }

      final unappliedCount = await _countUnappliedInbox();
      if (unappliedCount > 0) {
        return InstallEligibility.blocked(
            'Inbound hub events awaiting apply ($unappliedCount)');
      }

      if ((await _db.ordersDao.getUnsyncedOrderLogs()).isNotEmpty) {
        return InstallEligibility.blocked('Queued cloud sales uploads');
      }

      final settles = await (_db.select(_db.settleSalesOutbox)
            ..where((t) => t.synced.equals(false)))
          .get();
      if (settles.isNotEmpty) {
        return InstallEligibility.blocked('Unsettled cashier batches syncing');
      }

      if ((await _db.customersDao.getUnsyncedCustomers()).isNotEmpty) {
        return InstallEligibility.blocked('Customer records pending upload');
      }

      final hub = locator<LocalHubSettings>();
      if (!hub.blocksTenantCloudRest &&
          locator.isRegistered<OutboundPushCoordinator>()) {
        if (locator<OutboundPushCoordinator>().isFlushWorkInFlight) {
          return InstallEligibility.blocked('Active cloud push flush');
        }
      }
    } catch (e) {
      return InstallEligibility.blocked('Operational guard query failed ($e)');
    }

    return InstallEligibility.ok();
  }

  Future<int> _countUnappliedInbox() async =>
      (await (_db.select(_db.syncInbox)..where((t) => t.applied.equals(false)))
              .get())
          .length;

  Future<void> pauseRealtimeChannels() async {
    if (!Platform.isWindows) return;
    final g = GetIt.instance;
    if (g.isRegistered<LocalHubSyncCoordinator>()) {
      g<LocalHubSyncCoordinator>().stop();
    }
    if (g.isRegistered<LocalHubPrimaryInboundCoordinator>()) {
      g<LocalHubPrimaryInboundCoordinator>().stop();
    }
  }

  Future<void> resumeRealtimeChannels() async {
    if (!Platform.isWindows) return;
    await locator<LocalHubSyncCoordinator>().startIfEnabled();
    await locator<LocalHubPrimaryInboundCoordinator>().startIfEnabled();
    final hub = locator<LocalHubSettings>();
    if (!hub.blocksTenantCloudRest &&
        locator.isRegistered<OutboundPushCoordinator>()) {
      locator<OutboundPushCoordinator>().resumeAfterMaintenance();
      locator<OutboundPushCoordinator>().scheduleFlush();
    }
  }

  Future<UpdateCheckOutcome> checkForUpdates(
      {String manifestUrl = kDefaultVersionManifestUrl}) async {
    if (!Platform.isWindows) {
      return const UpdateCheckOutcome(
        updateAvailable: false,
        manifest: null,
        currentVersion: '',
        message: 'Windows only',
      );
    }
    final info = await PackageInfo.fromPlatform();
    final current = VersionCompare.normalize(info.version);

    if (!await NetworkUtils.hasInternetConnection()) {
      return UpdateCheckOutcome(
        updateAvailable: false,
        manifest: null,
        currentVersion: current,
        message: 'No internet connectivity',
      );
    }

    try {
      final manifest = await _updateService.fetchManifest(url: manifestUrl);
      final remote = VersionCompare.normalize(manifest.version);
      final newer =
          VersionCompare.isNewerThan(remote: remote, current: current);
      return UpdateCheckOutcome(
        updateAvailable: newer,
        manifest: manifest,
        currentVersion: current,
        message: newer ? 'Available ${manifest.version}' : 'Up to date',
      );
    } on UpdateServiceException catch (e) {
      return UpdateCheckOutcome(
        updateAvailable: false,
        manifest: null,
        currentVersion: current,
        message: e.message,
      );
    }
  }

  Future<String> downloadUpdate(RemoteUpdateManifest manifest,
      {CancelToken? cancelToken}) async {
    if (!Platform.isWindows)
      throw UpdateServiceException('Windows-only download');

    final token = cancelToken ?? (_downloadCancelToken = CancelToken());

    await Directory(kWindowsUpdatesDirectory).create(recursive: true);

    final safeName =
        '${VersionCompare.normalize(manifest.version)}_${p.basename(Uri.parse(manifest.installerDownloadUrl).path)}'
            .replaceAll(RegExp(r'[^\w.-]+'), '_');
    final target = p.join(kWindowsUpdatesDirectory, safeName);

    downloadProgressNotifier.value = 0;
    _emitBanner(
      UpdaterBannerState.downloading(
        message: 'Downloading POS update ${manifest.version}…',
        progress: null,
      ),
    );

    try {
      await _updateService.downloadInstaller(
        downloadUrl: manifest.installerDownloadUrl,
        targetPath: target,
        cancelToken: token,
        onProgress: (received, total) {
          if (total <= 0) return;
          final ratio = received / total;
          downloadProgressNotifier.value = ratio.clamp(0.0, 1.0);
          _emitBanner(
            UpdaterBannerState.downloading(
              message:
                  'Downloading POS update ${manifest.version} (${(ratio * 100).floor()}%)',
              progress: ratio.clamp(0.0, 1.0),
            ),
          );
        },
      );
    } finally {
      if (cancelToken == null && identical(token, _downloadCancelToken)) {
        _downloadCancelToken = null;
      }
    }

    _downloadedInstallerPath = target;
    downloadProgressNotifier.value = 1;
    _emitBanner(
      UpdaterBannerState.ready(
        'Update ${manifest.version} downloaded — tap the update icon to install.',
      ),
    );
    return target;
  }

  Future<void> cancelOngoingDownload() async {
    _downloadCancelToken?.cancel('User/system cancelled installer download');
  }

  /// Copies `pos.sqlite` into [`kWindowsUpdatesDirectory`] immediately before patching.
  Future<String?> backupDatabase() async {
    if (!Platform.isWindows) return null;
    await Directory(kWindowsUpdatesDirectory).create(recursive: true);
    final localDir = await AppDirectories.local();
    final dbPath = File(p.join(localDir.path, 'pos.sqlite'));
    if (!await dbPath.exists()) return null;
    final stamped = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupFile =
        File(p.join(kWindowsUpdatesDirectory, 'pre_update_$stamped.db'));
    await dbPath.copy(backupFile.path);
    _log('pre-update SQLite copy → ${backupFile.path}');
    return backupFile.path;
  }

  /// Runs `zaad_pos_setup.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART` after teardown.
  Future<void> installUpdate(
      {InstallReason reason = InstallReason.manual}) async {
    if (!Platform.isWindows) return;
    final eligibility = await canInstallUpdate();
    if (!eligibility.isOk) {
      throw UpdateServiceException(
          eligibility.blockReason ?? 'Install blocked');
    }

    final path = _downloadedInstallerPath;
    if (path == null || !await File(path).exists()) {
      throw UpdateServiceException('Installer unavailable');
    }

    final validated = await UpdateService.validateWindowsInstallerFile(path,
        expectedContentLength: await File(path).length());
    if (validated != UpdateInstallerValidation.ok) {
      throw UpdateServiceException('Installer corrupted ($validated)');
    }

    _installLifecycleActive = true;
    await pauseRealtimeChannels();

    final hub = locator<LocalHubSettings>();
    if (!hub.blocksTenantCloudRest &&
        locator.isRegistered<OutboundPushCoordinator>()) {
      try {
        await locator<OutboundPushCoordinator>().flushPendingIfOnline();
      } catch (_) {
        /* best-effort */
      }
      locator<OutboundPushCoordinator>().suspendForMaintenance();
    }

    try {
      await BackupService.instance.backupNow(_db);
    } catch (e, st) {
      _log('integrated backup skipped: $e\n$st');
    }

    try {
      await backupDatabase();
    } on FileSystemException catch (e) {
      _installLifecycleActive = false;
      if (!hub.blocksTenantCloudRest &&
          locator.isRegistered<OutboundPushCoordinator>()) {
        locator<OutboundPushCoordinator>().resumeAfterMaintenance();
      }
      await resumeRealtimeChannels();
      throw UpdateServiceException(
          'Could not duplicate SQLite before install (${e.osError?.message ?? e.message})');
    }

    try {
      await _quiesceSqliteWrites();
      await _db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
    } catch (e, st) {
      _installLifecycleActive = false;
      if (!hub.blocksTenantCloudRest &&
          locator.isRegistered<OutboundPushCoordinator>()) {
        locator<OutboundPushCoordinator>().resumeAfterMaintenance();
      }
      await resumeRealtimeChannels();
      _log('sqlite quiesce failed: $e\n$st');
      throw UpdateServiceException('Database refused quiet window ($e)');
    }

    _emitBanner(
      const UpdaterBannerState(
        phase: UpdaterBannerPhase.installing,
        foregroundBusy: true,
        message: 'Closing databases and launching installer…',
      ),
    );

    await _db.close();

    try {
      await _spawnInnoDetached(path);
    } catch (e, st) {
      _log('installer spawn failed after DB close: $e\n$st');
      _emitBanner(UpdaterBannerState.error(
          'CRITICAL: DB closed but installer failed — relaunch POS manually.'));
      unawaited(
        Future<void>.delayed(const Duration(seconds: 2), () => exit(1)),
      );
      rethrow;
    }

    await restartApplication(forceExitWithoutRelaunch: true);
  }

  Future<void> _spawnInnoDetached(String exePath) async {
    final args = ['/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART'];
    try {
      await Process.start(exePath, args, mode: ProcessStartMode.detached);
    } on ProcessException catch (e) {
      throw UpdateServiceException('Failed to spawn installer (${e.message})');
    }
  }

  /// Acquires SQLite writer lock briefly to serialize with in-flight merges.
  Future<void> _quiesceSqliteWrites() async {
    await _db.customStatement('PRAGMA busy_timeout = 20000');
    await _db.customStatement('BEGIN IMMEDIATE');
    await _db.customStatement('COMMIT');
  }

  /// Relaunch helper for IT scripts / kiosk shells.
  ///
  /// Prefer Inno `[Run]` to relaunch after `/VERYSILENT` installs; supply [forceExitWithoutRelaunch] to exit cleanly
  /// so the Inno process can supersede the outdated binary immediately.
  Future<void> restartApplication(
      {bool forceExitWithoutRelaunch = false}) async {
    if (!Platform.isWindows) return;
    if (!forceExitWithoutRelaunch) {
      final launcher = Platform.resolvedExecutable;
      await Process.start(launcher, const [], mode: ProcessStartMode.detached);
    }
    exit(0);
  }

  void disposeIdleMonitorOnly() {}
}

class _UpdateBanner extends StatelessWidget {
  const _UpdateBanner({required this.state});

  final UpdaterBannerState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = switch (state.phase) {
      UpdaterBannerPhase.error => theme.colorScheme.errorContainer,
      UpdaterBannerPhase.ready => theme.colorScheme.tertiaryContainer,
      _ => theme.colorScheme.primaryContainer,
    };
    final fg = switch (state.phase) {
      UpdaterBannerPhase.error => theme.colorScheme.onErrorContainer,
      UpdaterBannerPhase.ready => theme.colorScheme.onTertiaryContainer,
      _ => theme.colorScheme.onPrimaryContainer,
    };

    return Material(
      color: bg,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.system_update_alt,
                    color: fg,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.message ?? '',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: fg, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if ((state.progress ?? 0) > 0 && state.progress! < 1)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(value: state.progress),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
