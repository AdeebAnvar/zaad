import 'package:pos/app/di.dart';
import 'package:pos/core/network/pos_server_settings.dart';
import 'package:pos/core/network/websocket_service.dart';

/// Restarts hub hydrate + WebSocket after setup / QR scan changes LOCAL hub prefs.
Future<void> applyHubSocketAfterLocalSetupChange() async {
  final ws = locator<HubWebSocketService>();
  await ws.stop();
  final settings = locator<PosServerSettings>();
  if (settings.enablesLanWebSocket) {
    await ws.hydrateCacheIfConfigured();
    ws.startRealtimeIfConfigured();
  }
}
