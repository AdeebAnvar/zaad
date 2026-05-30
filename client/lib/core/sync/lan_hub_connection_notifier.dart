import 'package:pos/core/network/local_hub_settings.dart';
import 'package:pos/presentation/widgets/custom_toast.dart';

/// User-visible LAN hub connection toasts (SUB ↔ MAIN and MAIN ↔ SUB peers).
class LanHubConnectionNotifier {
  bool _subLinkWasUp = false;
  final Set<String> _knownPeerDeviceIds = <String>{};

  /// SUB tablet lost its WebSocket to the MAIN hub.
  void onSubHubDisconnected(LocalHubSettings settings) {
    if (!_subLinkWasUp) return;
    _subLinkWasUp = false;
    CustomSnackBar.showWarning(
      message: 'Connection to MAIN PC lost',
      duration: const Duration(seconds: 5),
      position: SnackBarPosition.topRight,
    );
  }

  /// SUB tablet connected to the MAIN hub.
  void onSubHubConnected(LocalHubSettings settings) {
    if (_subLinkWasUp) return;
    final showRestored = _subEverConnected;
    _subLinkWasUp = true;
    _subEverConnected = true;
    if (showRestored) {
      CustomSnackBar.showSuccess(
        message: 'Connected to MAIN PC',
        duration: const Duration(seconds: 3),
        position: SnackBarPosition.topRight,
      );
    }
  }

  bool _subEverConnected = false;

  /// MAIN PC: a SUB (or other peer) joined the hub.
  void onMainPeerConnected({
    required String deviceId,
    String? deviceName,
    String? clientRole,
  }) {
    if (deviceId.isEmpty) return;
    if (clientRole == 'MAIN_CLIENT') return;
    final added = _knownPeerDeviceIds.add(deviceId);
    if (!added) return;
    final label = hubPeerDisplayLabel(deviceName: deviceName, deviceId: deviceId);
    CustomSnackBar.showInfo(
      message: 'Connected: $label',
      duration: const Duration(seconds: 3),
      position: SnackBarPosition.topRight,
    );
  }

  /// MAIN PC: a peer left the hub.
  void onMainPeerDisconnected({
    required String deviceId,
    String? deviceName,
    String? clientRole,
  }) {
    if (deviceId.isEmpty) return;
    if (clientRole == 'MAIN_CLIENT') return;
    if (!_knownPeerDeviceIds.remove(deviceId)) return;
    final label = hubPeerDisplayLabel(deviceName: deviceName, deviceId: deviceId);
    CustomSnackBar.showWarning(
      message: 'Connection lost: $label',
      duration: const Duration(seconds: 5),
      position: SnackBarPosition.topRight,
    );
  }

  void resetMainPeerTracking() {
    _knownPeerDeviceIds.clear();
  }
}

/// Prefer [deviceName] from the CONNECT handshake; fall back to a short id.
String hubPeerDisplayLabel({String? deviceName, String? deviceId}) {
  final name = deviceName?.trim();
  if (name != null && name.isNotEmpty) return name;
  final id = deviceId?.trim();
  if (id == null || id.isEmpty) return 'Unknown device';
  if (id.length <= 16) return id;
  return '${id.substring(0, 8)}…';
}
