'use strict';

const fs = require('fs');
const path = require('path');

const WINDOWS_DEFAULT_CONFIG = path.join('C:', 'POS', 'config.json');
const WINDOWS_DEFAULT_DB = path.join('C:', 'POS', 'data', 'pos.db');
const WINDOWS_DEFAULT_BACKUPS = path.join('C:', 'POS', 'backups');

/** @typedef {ReturnType<typeof loadConfig>} AppConfig */

/**
 * Loads merged configuration: defaults → POS_CONFIG_PATH / default path → dotenv-derived overrides.
 * @returns {AppConfig}
 */
function loadConfig() {
  const isWindows = process.platform === 'win32';
  const defaultConfigPath = isWindows ? WINDOWS_DEFAULT_CONFIG : path.join(process.cwd(), 'config.json');

  /** @type {Record<string, unknown>} */
  let fileConfig = {};
  const configPathEnv = process.env.POS_CONFIG_PATH;
  const configPathCandidates = [];

  if (configPathEnv) configPathCandidates.push(configPathEnv);
  if (!configPathCandidates.includes(defaultConfigPath)) configPathCandidates.push(defaultConfigPath);

  let resolvedPath = '';
  for (const p of configPathCandidates) {
    try {
      if (p && fs.existsSync(p)) {
        resolvedPath = p;
        fileConfig = JSON.parse(fs.readFileSync(p, 'utf8'));
        break;
      }
    } catch (e) {
      console.warn(`[config] skipped invalid file ${p}:`, e.message);
    }
  }

  const prodLike = process.env.NODE_ENV === 'production';
  const devDbFallback = path.join(process.cwd(), 'data', 'pos.db');
  const devBackupFallback = path.join(process.cwd(), 'backups');

  const db_path =
    process.env.POS_DB_PATH ||
    /** @type {string | undefined} */ (fileConfig.db_path) ||
    (prodLike && isWindows ? WINDOWS_DEFAULT_DB : devDbFallback);

  const backup_dir =
    /** @type {string | undefined} */ (fileConfig.backup_dir) ||
    (prodLike && isWindows ? WINDOWS_DEFAULT_BACKUPS : devBackupFallback);

  const cloud = /** @type {Record<string, unknown>} */ (
    typeof fileConfig.cloud_sync === 'object' && fileConfig.cloud_sync !== null ? fileConfig.cloud_sync : {}
  );

  const static_api_base =
    (typeof cloud.api_base_url === 'string' ? cloud.api_base_url : '').trim() ||
    (process.env.POS_CLOUD_API_BASE_URL || '').trim();

  const enabledCloud = Boolean(cloud.enabled);
  const hasStaticTenant = static_api_base.length > 0;

  /** Main hub: pull/push to suite from Node (so Flutter in Local mode can use /sync/mirror). */
  const nodeEngine =
    Boolean(cloud.node_cloud_engine_enabled) ||
    process.env.POS_NODE_CLOUD_ENGINE === 'true' ||
    (enabledCloud && hasStaticTenant);

  /** @type {AppConfig['cloud_sync']} */
  const cloud_sync = {
    enabled: Boolean(cloud.enabled),
    api_base_url: static_api_base,
    auth_token_env:
      typeof cloud.auth_token_env === 'string'
        ? cloud.auth_token_env
        : /** @type {string} */ ('CLOUD_POS_TOKEN'),
    push_interval_seconds:
      typeof cloud.push_interval_seconds === 'number'
        ? Math.min(120, Math.max(3, cloud.push_interval_seconds))
        : Number(process.env.POS_CLOUD_PUSH_INTERVAL_SECONDS) || 7,
    max_retries: typeof cloud.max_retries === 'number' ? cloud.max_retries : 50,
    batch_size:
      typeof cloud.batch_size === 'number' ? Math.min(100, Math.max(1, cloud.batch_size)) : 25,
    /** When true, Node runs pull/push against the cloud (Flutter stays off the wire if you switch it over). */
    node_cloud_engine_enabled: nodeEngine,
    /** Keep posting generic sync_queue batches to /v1/sync/push (legacy hub contract). */
    legacy_sync_queue_push:
      typeof cloud.legacy_sync_queue_push === 'boolean'
        ? cloud.legacy_sync_queue_push
        : Boolean(cloud.enabled) && !nodeEngine,
    common_api_url:
      typeof cloud.common_api_url === 'string'
        ? cloud.common_api_url
        : process.env.POS_CLOUD_COMMON_API_URL ||
          'https://suite.zaadplatforms.com/api/getlink',
    app_id: typeof cloud.app_id === 'string' ? cloud.app_id : process.env.POS_CLOUD_APP_ID || '',
    resolve_base_url_from_common:
      typeof cloud.resolve_base_url_from_common === 'boolean'
        ? cloud.resolve_base_url_from_common
        : nodeEngine && !static_api_base,
    pull_interval_seconds:
      typeof cloud.pull_interval_seconds === 'number'
        ? Math.min(3600, Math.max(30, cloud.pull_interval_seconds))
        : Number(process.env.POS_CLOUD_PULL_INTERVAL_SECONDS) || 120,
    worker_tick_seconds:
      typeof cloud.worker_tick_seconds === 'number'
        ? Math.min(120, Math.max(5, cloud.worker_tick_seconds))
        : Number(process.env.POS_CLOUD_WORKER_TICK_SECONDS) || 15,
    initial_pull_on_startup:
      Boolean(cloud.initial_pull_on_startup) || process.env.POS_CLOUD_INITIAL_PULL === 'true',
    max_pull_pages:
      typeof cloud.max_pull_pages === 'number'
        ? Math.min(500, Math.max(1, cloud.max_pull_pages))
        : 500,
  };

  /** @type {AppConfig} */
  const merged = {
    port: coercePort(fileConfig.port) ?? 3000,
    host: typeof fileConfig.host === 'string' ? fileConfig.host : '0.0.0.0',
    db_path: path.normalize(db_path),
    backup_dir: path.normalize(backup_dir),
    config_path_used: resolvedPath || null,
    cloud_sync,
    backup_interval_cron:
      typeof fileConfig.backup_interval_cron === 'string'
        ? fileConfig.backup_interval_cron
        : '*/30 * * * *',
    backup_keep_days:
      typeof fileConfig.backup_keep_days === 'number' ? fileConfig.backup_keep_days : 7,
    auth: {
      /** Shared secret validated as Authorization: Bearer <token> OR ?token= for WebSocket */
      required_token:
        process.env.POS_HUB_TOKEN ||
        (typeof fileConfig.required_token === 'string' ? fileConfig.required_token : '') ||
        (typeof fileConfig.auth_required_token === 'string' ? fileConfig.auth_required_token : ''),
      /**
       * OFF only for local debugging. Prefer setting POS_HUB_TOKEN instead.
       * FORCE_AUTH_OFF=true skips validation (explicit escape hatch).
       */
      disabled:
        process.env.FORCE_AUTH_OFF === 'true' ||
        (typeof fileConfig.disable_auth === 'boolean' ? fileConfig.disable_auth : false),
    },
  };

  return merged;
}

/**
 * @param {unknown} v
 * @returns {number | null}
 */
function coercePort(v) {
  const n = Number(v);
  if (!Number.isFinite(n) || n < 1 || n > 65535) return null;
  return n;
}

module.exports = { loadConfig };
