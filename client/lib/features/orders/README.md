# Orders hub integration

When `SharedPreferences` key `pos_server_base_url` is set (via `PosServerSettings.setBaseUrl`), checkout writes go to the Node LAN server; Drift mirrors the authoritative response and WebSocket events.

- **Payload mapper:** `data/hub_orders_payload_builder.dart`
- **Drift projection:** `data/hub_orders_sync.dart`
- **Live transport:** `package:pos/core/network/pos_hub_realtime_coordinator.dart`

Cold start executes `hydrateCacheIfConfigured()` then opens `/ws`.
