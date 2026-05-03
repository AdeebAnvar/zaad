'use strict';

const syncQueue = require('../services/syncQueueService');
const cloudSync = require('./cloudSyncService');

/** @typedef {import('../config/index').AppConfig} AppConfig */

/** @typedef {{ getHub?: () => import('../websocket/index').WebSocketHub | null }} WorkerHubCtx */

/**
 * @param {WorkerHubCtx | undefined} ctx
 */
function resolveHub(ctx) {
  if (!ctx || typeof ctx.getHub !== 'function') return null;
  return ctx.getHub() ?? null;
}

/**
 * @param {string} base
 */
function ensureTrailingSlash(base) {
  return base.endsWith('/') ? base : `${base}/`;
}

/**
 * @param {globalThis.Response} res
 */
async function safeText(res) {
  try {
    return await res.text();
  } catch {
    return '';
  }
}

/**
 * @param {*} db
 * @param {AppConfig} config
 */
async function legacyHubBatchPush(db, config, log) {
  const baseTrim = String(config.cloud_sync.api_base_url || '').trim();
  const wantLegacy =
    config.cloud_sync.enabled && config.cloud_sync.legacy_sync_queue_push && !!baseTrim;
  if (!wantLegacy) return;

  const tokenEnv = config.cloud_sync.auth_token_env;
  const token = tokenEnv ? String(process.env[tokenEnv] || '').trim() : '';
  if (!token) {
    log('legacy_sync_queue_push is on but missing token env %s — skipping hub batch', tokenEnv);
    return;
  }

  const jobs = await syncQueue.fetchDueJobs(db, { limit: config.cloud_sync.batch_size });
  if (!jobs.length) return;

  /** @type {{ id: string; operation: string; entity_type: string; entity_id?: string | null; payload: unknown }[]} */
  const envelope = [];
  for (const row of jobs) {
    let payload;
    try {
      payload = JSON.parse(String(row.payload));
    } catch {
      payload = row.payload;
    }
    envelope.push({
      id: String(row.id),
      operation: String(row.operation),
      entity_type: String(row.entity_type),
      entity_id: row.entity_id ? String(row.entity_id) : null,
      payload,
    });
  }

  const url = new URL('/v1/sync/push', ensureTrailingSlash(baseTrim));
  try {
    const res = await fetch(url, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ batch: envelope, source: 'pos-local-server' }),
    });

    if (!res.ok) {
      const text = await safeText(res);
      throw new Error(`HTTP ${res.status} ${text}`);
    }

    for (const row of jobs) await syncQueue.markSynced(db, String(row.id));
  } catch (e) {
    const message = e instanceof Error ? e.message : String(e);
    const t = Date.now();
    for (const row of jobs) {
      const nextRetry = Number(row.retry_count || 0) + 1;
      if (nextRetry > config.cloud_sync.max_retries) {
        log('max retries exceeded for job %s — leaving for manual review', row.id);
        continue;
      }
      const delay = syncQueue.computeBackoffMs(Number(row.retry_count || 0));
      const nextIso = new Date(t + delay).toISOString();
      await syncQueue.markFailure(db, String(row.id), {
        retryCount: nextRetry,
        error: message.slice(0, 2000),
        nextAttemptAt: nextIso,
      });
    }
    log('legacy hub batch push failed: %s', message);
  }
}

/**
 * @param {*} db
 * @param {AppConfig} config
 * @param {WorkerHubCtx} [hubCtx]
 * @param {{ log?: typeof console }} [opts]
 */
function startSyncWorker(db, config, hubCtx = undefined, opts = {}) {
  /**
   * @param {unknown} msgOrFirst
   * @param {...unknown[]} rest
   */
  const lg = opts.log ?? ((msgOrFirst, ...rest) => console.log('[sync-worker]', msgOrFirst, ...rest));

  let timer = /** @type {ReturnType<typeof setTimeout> | null} */ (null);
  let stopped = false;
  const tickState = cloudSync.createTickState();

  const jitteredDelayMs = () => {
    const baseMs =
      typeof config.cloud_sync.worker_tick_seconds === 'number'
        ? config.cloud_sync.worker_tick_seconds * 1000
        : 15_000;
    const jitter = Math.floor(Math.random() * 2500);
    return Math.min(180_000, Math.max(5_000, baseMs + jitter));
  };

  const schedule = (delayMs) => {
    if (stopped) return;
    if (timer) clearTimeout(timer);
    timer = setTimeout(runCycle, delayMs);
  };

  const runCycle = async () => {
    if (stopped) return;

    try {
      await legacyHubBatchPush(db, config, lg).catch(() => {});

      if (config.cloud_sync.node_cloud_engine_enabled) {
        const hubSnap = resolveHub(hubCtx);
        try {
          await cloudSync.runWorkerTick(db, { config, hub: hubSnap ?? null }, tickState, console);
        } catch (e) {
          lg('node cloud worker tick crashed %s', e instanceof Error ? e.message : String(e));
        }
      }
    } catch (e) {
      lg('[sync-cycle] unexpected %s', e instanceof Error ? e.message : String(e));
    } finally {
      if (!stopped) schedule(jitteredDelayMs());
    }
  };

  schedule(Math.floor(Math.random() * 500) + 200);

  return () => {
    stopped = true;
    if (timer) clearTimeout(timer);
    timer = null;
  };
}

module.exports = { startSyncWorker };
