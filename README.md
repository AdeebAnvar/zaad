# Offline POS Monorepo

Local-first POS with a Node.js LAN server (`server/`), Flutter clients (`client/`), SQLite on the hub machine, optional cloud sync (`sync_queue`), scheduled backups, and Windows installer scaffolding (`installer/`).

## Layout

```
pos/
  client/       Flutter app — point builds and `flutter pub get` here
  server/       Express + WebSocket + better-sqlite3 — source of truth for orders/invoices
  installer/    Post-build deployment to C:\POS\ (PowerShell)
  shared/       Optional docs / contracts (no runtime coupling)
```

## Quick start (development)

### Server

```powershell
cd server
npm install
copy env.example.txt .env
npm run dev
```

By default development uses `./data/pos.db` under `server/` unless `POS_CONFIG_PATH` points at a JSON file (see `server/README.md`).

### Client

```powershell
cd client
flutter pub get
flutter run -d windows
```

Configure the server base URL in-app (planned: SharedPreferences); the sample API service expects `PosServerSettings.baseUrl`.

## Production (machine A)

1. Run `installer\Setup-POS.ps1` **after** `flutter build windows` (see script).
2. PM2 manages `server/server.js`; clients use the host IP (`http://192.168.x.x:3000`).
3. Canonical DB path in production is `C:\POS\data\pos.db`; backups rotate under `C:\POS\backups\`.
