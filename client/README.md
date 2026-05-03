# POS Flutter client (`client/`)

This is the existing Flutter application, relocated under [`client/`](../README.md) as part of the offline-first LAN architecture.

SharedPreferences key `pos_server_base_url` stores the hub (`http://192.168.x.x:3000`). Use [`lib/core/network/pos_api_service.dart`](lib/core/network/pos_api_service.dart) as the integration surface toward the Node server while Drift remains the on-device cache.

```powershell
flutter pub get
flutter run -d windows
```
