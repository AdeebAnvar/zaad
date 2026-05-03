# POS LAN server (`server/`)

Node hub that owns **invoice numbering**, persists orders in SQLite, broadcasts live events over WebSockets, drains a `sync_queue` to an optional HTTPS cloud relay, and snapshots the database (`node-cron`).

## Prerequisites

- Node.js ≥ 20 (`fetch` builtin)
- On Windows native modules may require [windows-build-tools](https://github.com/nodejs/node-gyp) for `better-sqlite3`

```powershell
npm install
copy env.example.txt .env   # optional
npm run db:init
npm run dev
```

## Production layout

The installer lays out:

- Server code under `C:\POS\server\`
- Canonical DB — `C:\POS\data\pos.db`
- Rotation backups — `C:\POS\backups\`
- JSON overrides — `C:\POS\config.json`

Development uses `POS_CONFIG_PATH`, `POS_DB_PATH`, or `./data/pos.db` fallback when neither config file nor `C:\POS\config.json` exist.

Example `config.json`:

```json
{
  "port": 3000,
  "host": "0.0.0.0",
  "db_path": "C:\\POS\\data\\pos.db",
  "backup_dir": "C:\\POS\\backups",
  "backup_interval_cron": "*/30 * * * *",
  "backup_keep_days": 7,
  "cloud_sync": {
    "enabled": false,
    "api_base_url": "https://your-cloud-host.example",
    "auth_token_env": "CLOUD_POS_TOKEN",
    "push_interval_seconds": 7,
    "max_retries": 50,
    "batch_size": 25
  }
}
```

## REST surface

| Method | Path                   | Purpose              |
|--------|-------------------------|----------------------|
| GET    | `/health`               | Liveness / sqlite    |
| POST   | `/orders`               | Submit sale          |
| GET    | `/orders`               | List recent          |
| PATCH  | `/orders/:id/status`    | Update lifecycle     |

## WebSocket (`/ws`)

Server envelopes:

```json
{ "type": "NEW_ORDER"|"ORDER_UPDATED"|"HELLO", "payload": {}, "ts": "ISO8601" }
```

## PM2 (`ecosystem.config.cjs`)

```powershell
npm install --omit=dev
npm i -g pm2
pm2 start ecosystem.config.cjs
pm2 save
pm2 startup
```

## Cloud push contract (placeholder)

Posts `POST {api_base_url}/v1/sync/push` JSON body:

```json
{ "batch": [{ "id", "operation", "entity_type", "entity_id", "payload": {} }], "source": "pos-local-server" }
```

Bearer token from `process.env[<auth_token_env>]`.
