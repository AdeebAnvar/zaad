'use strict';

const http = require('http');
const fs = require('fs');
const path = require('path');

const { loadConfig } = require('./config');
const { openDatabase } = require('./db/database');
const { initializeDatabase } = require('./db/init');
const { createHttpApp } = require('./httpApp');
const { createWebSocketHub } = require('./websocket');
const { createRequireBearer } = require('./middleware/requireBearer');
const { printConnectionLogHints } = require('./middleware/connectionLog');
const { createWsVerifyClient } = require('./middleware/websocketVerify');
const { startSyncWorker } = require('./sync/worker');
const { startBackupScheduler } = require('./backup/runner');

async function start() {
  const config = /** @type {ReturnType<typeof loadConfig>} */ (loadConfig());

  if (
    process.env.NODE_ENV === 'production' &&
    !config.auth.disabled &&
    !(String(config.auth.required_token || '').trim())
  ) {
    console.error('[pos-server] FATAL: production requires POS_HUB_TOKEN or required_token in config.');
    process.exit(1);
  }

  fs.mkdirSync(path.dirname(config.db_path), { recursive: true });
  fs.mkdirSync(config.backup_dir, { recursive: true });
  fs.mkdirSync(path.join(__dirname, '..', 'logs'), { recursive: true });

  console.log('[pos-server] config file:', config.config_path_used || '(no file found — defaults/env)');
  console.log('[pos-server] sqlite path:', config.db_path);
  if (config.cloud_sync.enabled) {
    console.log(
      '[pos-server] cloud: node engine (suite pull/push) =',
      config.cloud_sync.node_cloud_engine_enabled ? 'ON' : 'OFF',
      '— token env:',
      config.cloud_sync.auth_token_env,
    );
    if (!config.cloud_sync.node_cloud_engine_enabled) {
      console.warn(
        '[pos-server] cloud_sync.enabled but suite sync worker is OFF. Set cloud_sync.api_base_url (or POS_CLOUD_API_BASE_URL), or node_cloud_engine_enabled / POS_NODE_CLOUD_ENGINE=true',
      );
    }
  }

  const db = openDatabase({ dbPath: config.db_path });
  await initializeDatabase(db);

  /** @type {ReturnType<createWebSocketHub> | null} */
  let hub = null;

  const authMw =
    config.auth.disabled || !(config.auth.required_token || '').trim()
      ? null
      : /** @type {import('express').RequestHandler} */ (createRequireBearer(config.auth));

  /** @typedef {{ get hub(): ReturnType<typeof createWebSocketHub>|null; config: import('./config').AppConfig }} AppCtx */
  const appCtx = /** @type {AppCtx} */ ({
    /** @returns {ReturnType<typeof createWebSocketHub> | null} */
    get hub() {
      return hub;
    },
    config,
  });

  const app = createHttpApp(db, appCtx, authMw);

  const server = http.createServer(app);
  const wsVerify =
    config.auth.disabled || !(config.auth.required_token || '').trim()
      ? undefined
      : createWsVerifyClient(config.auth);
  hub = createWebSocketHub(server, { path: '/ws', verifyClient: wsVerify });

  console.log('[pos-server] auth:', config.auth.disabled ? 'DISABLED (set POS_HUB_TOKEN + disable:false for prod)' : 'Bearer + ?token=');

  server.listen(config.port, config.host, () => {
    console.log(
      `[pos-server] listening http://${config.host === '0.0.0.0' ? '0.0.0.0' : config.host}:${config.port}`
    );
    console.log('[pos-server] websocket path /ws');
    printConnectionLogHints();
    console.log(
      '[pos-server] LAN conn logs: prefix [conn]; support mode: POS_CLIENT_DIAGNOSTICS=1 (all HTTP + pos-client-access.log)'
    );
  });

  const cloudSyncSvc = require('./sync/cloudSyncService');
  const stopSync = startSyncWorker(db, config, { getHub: () => hub });

  if (config.cloud_sync.initial_pull_on_startup && config.cloud_sync.node_cloud_engine_enabled) {
    setImmediate(async () => {
      try {
        console.log('[pos-server] cloud: initial_pull_on_startup (bootstrap + paginated pull)…');
        await cloudSyncSvc.ensureResolvedCloudBase(db, config.cloud_sync);
        await cloudSyncSvc.refreshBootstrap(db, config.cloud_sync, undefined);
        await cloudSyncSvc.runInitialMasterSync(db, config, undefined, hub, console);
      } catch (e) {
        console.warn('[pos-server] cloud initial pull failed:', e instanceof Error ? e.message : String(e));
      }
    });
  }
  const stopBackup = startBackupScheduler({
    db_path: config.db_path,
    backup_dir: config.backup_dir,
    backup_keep_days: config.backup_keep_days,
    backup_interval_cron: config.backup_interval_cron,
  });

  let shutdownInvoked = false;
  const shutdown = () => {
    if (shutdownInvoked) return;
    shutdownInvoked = true;
    stopSync();
    stopBackup();
    server.close(() => {
      Promise.resolve(db.close())
        .then(() => console.log('[pos-server] shutdown complete'))
        .catch((err) => console.error('[pos-server] db.close failed', err));
    });
  };

  process.on('SIGINT', shutdown);
  process.on('SIGTERM', shutdown);
}

module.exports = { start };
