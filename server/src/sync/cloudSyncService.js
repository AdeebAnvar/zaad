'use strict';

const { randomUUID } = require('crypto');

/**
 * Mirrors Flutter `pull_data_repository_impl.dart` resource keys (`data.{key}` envelopes).
 */
const PULL_RESOURCE_KEYS = [
  'category',
  'variations',
  'variationOptions',
  'toppingCategories',
  'toppings',
  'expenseCategory',
  'driver',
  'staffs',
  'waiters',
  'unit',
  'paymentMethods',
  'floors',
  'deliveryService',
  'kitchens',
  'item',
  'customer',
  'tables',
];

/** @typedef {import('../config/index').AppConfig} AppConfig */

let _resolvedBaseMemo = '';

/**
 * @param {string} raw
 */
function normalizeCloudBase(raw) {
  let s = String(raw || '').trim();
  const re = /^([a-z][a-z0-9+.-]*:\/\/[^/]+):0(?:\/|$)/i;
  s = s.replace(re, (_, h) => h + '/').replace(/:0$/i, '');
  return s.replace(/\/+$/, '');
}

/**
 * @param {URL | string} u
 */
function urlToStringSansZeroPort(u) {
  try {
    const x = typeof u === 'string' ? new URL(u) : new URL(u.toString());
    if (x.port === '0') {
      x.port = '';
    }
    return normalizeCloudBase(x.toString());
  } catch {
    return normalizeCloudBase(String(u));
  }
}

function nowIso() {
  return new Date().toISOString();
}

/**
 * Common host resolver (`?appid=`) → tenant base URL JSON field `url` / legacy `message` error.
 *
 * @param {{ commonApiUrl: string; appId: string }} opts
 */
async function fetchBaseUrlFromCommon(opts) {
  const u = new URL(opts.commonApiUrl);
  if (!u.searchParams.has('appid')) {
    u.searchParams.set('appid', opts.appId);
  }
  const res = await fetch(u.toString(), { method: 'GET', redirect: 'follow' });
  const text = await res.text();
  let data = /** @type {Record<string, unknown>} */ ({});
  try {
    data = /** @type {Record<string, unknown>} */ (JSON.parse(text));
  } catch {
    throw new Error('common resolver returned non‑JSON');
  }
  if (Object.prototype.hasOwnProperty.call(data, 'message')) {
    const msg = /** @type {unknown} */ (data.message);
    if (typeof msg === 'string' && msg.includes('http')) {
      throw new Error(msg);
    }
    if (typeof msg === 'string' && msg.trim()) {
      throw new Error(msg);
    }
  }
  const url = /** @type {unknown} */ (data.url);
  if (typeof url !== 'string' || !url.trim()) {
    throw new Error('common resolver response missing url');
  }
  return normalizeCloudBase(url);
}

/**
 * @param {*} db
 */
async function metaGet(db, k) {
  const row = await db.get('SELECT v FROM sync_meta WHERE k = ?', [k]);
  return row && typeof row === 'object' && 'v' in row ? String(/** @type {{ v: unknown }} */ (row).v) : '';
}

/**
 * @param {*} db
 */
async function metaSet(db, k, v) {
  const t = nowIso();
  await db.run(
    `INSERT INTO sync_meta (k, v, updated_at) VALUES (?, ?, ?)
     ON CONFLICT(k) DO UPDATE SET v = excluded.v, updated_at = excluded.updated_at`,
    [k, String(v), t],
  );
}

function getCloudBearerToken(cloudSyncFrag) {
  const envVar = cloudSyncFrag.auth_token_env || 'CLOUD_POS_TOKEN';
  return String(process.env[envVar] || '').trim();
}

/** Same default as Flutter [DioClient] — tenant API works without Bearer when this is set. */
const FLUTTER_TENANT_X_AUTH_KEY =
  (typeof process.env.POS_TENANT_X_AUTH_KEY === 'string' && process.env.POS_TENANT_X_AUTH_KEY.trim()) ||
  'd0ff75bf-77e6-4032-a7d4-9061ddd89752';

/**
 * @param {AppConfig['cloud_sync']} c
 */
function bearerHeadersForCloud(c, extra = {}) {
  const token = getCloudBearerToken(c);
  /** @type {Record<string, string>} */
  const h = {
    accept: 'application/json',
    'content-type': 'application/json',
    'X-Auth-Key': FLUTTER_TENANT_X_AUTH_KEY,
    ...extra,
  };
  if (token) {
    h.authorization = `Bearer ${token}`;
  }
  return h;
}

/**
 * @param {AppConfig['cloud_sync']} cfg
 * @returns {Promise<string>}
 */
async function ensureResolvedCloudBase(db, cfg) {
  let base = normalizeCloudBase(cfg.api_base_url);
  if (!base && _resolvedBaseMemo) base = normalizeCloudBase(_resolvedBaseMemo);
  if (!base) base = normalizeCloudBase(await metaGet(db, 'cloud_resolved_base_url'));

  const appId = String(cfg.app_id || '').trim();
  const shouldHitCommon = (cfg.resolve_base_url_from_common && !!appId) || (!base && !!appId);

  if (shouldHitCommon && appId) {
    try {
      const resolved = await fetchBaseUrlFromCommon({
        commonApiUrl: cfg.common_api_url,
        appId,
      });
      base = resolved;
    } catch (e) {
      if (!base) throw e;
    }
  }

  if (!base) throw new Error('cloud base URL not configured (set api_base_url or app_id + common resolver)');
  cfg.api_base_url = base;
  _resolvedBaseMemo = base;
  await metaSet(db, 'cloud_resolved_base_url', base);
  return base;
}

/**
 * @param {string} cloudBase normalized
 */
function resolveCloudUrl(cloudBase, pathQuery) {
  const root = normalizeCloudBase(cloudBase);
  let suffix = pathQuery.startsWith('/') ? pathQuery : `/${pathQuery}`;
  suffix = suffix.replace(/^\/\/+/, '/');
  return new URL(suffix.slice(1), `${root.endsWith('/') ? root : `${root}/`}`);
}

async function readJsonMaybe(res) {
  const txt = await res.text();
  try {
    return JSON.parse(txt);
  } catch {
    return { raw: txt };
  }
}

/**
 * Tenant API call (Flutter parity: Bearer + legacy X-Auth-Key).
 *
 * @param {AppConfig['cloud_sync']} cfg
 */
async function cloudFetchJson(cfg, method, absolutePathQuery, opts = {}) {
  const base = normalizeCloudBase(cfg.api_base_url);
  if (!base) throw new Error('cloud base not resolved');
  const url = resolveCloudUrl(base, absolutePathQuery);
  /** @type {Record<string, string>} */
  const headers = {
    ...bearerHeadersForCloud(cfg),
  };
  if (opts.forwardHeaders && typeof opts.forwardHeaders === 'object') {
    const fh = /** @type {Record<string, string | undefined>} */ (opts.forwardHeaders);
    const xh = fh['x-auth-key'] ?? fh['X-Auth-Key'];
    if (typeof xh === 'string' && xh.trim()) {
      headers['X-Auth-Key'] = xh.trim();
    }
    const ah = fh['authorization'] ?? fh['Authorization'];
    if (typeof ah === 'string' && ah.trim() && !headers.authorization) {
      headers.authorization = ah.trim();
    }
  }

  /** @type {RequestInit} */
  const req = {
    method,
    headers,
    redirect: 'follow',
  };
  if (opts.body !== undefined) {
    req.body = typeof opts.body === 'string' ? opts.body : JSON.stringify(opts.body);
  }

  const res = /** @type {globalThis.Response} */ (await fetch(urlToStringSansZeroPort(url), req));
  const body = await readJsonMaybe(res);
  return { ok: res.ok, status: res.status, body };
}

/**
 * @param {unknown} envelope
 */
function listCreatedUpdated(envelope) {
  if (!envelope || typeof envelope !== 'object') return [];
  const cu = /** @type {{ created_updated?: unknown }} */ (envelope).created_updated;
  if (Array.isArray(cu)) return cu;
  if (cu && typeof cu === 'object' && !Array.isArray(cu)) {
    return Object.values(cu);
  }
  return [];
}

/**
 * @param {unknown} envelope
 */
function extractDeletedIds(envelope) {
  if (!envelope || typeof envelope !== 'object') return [];
  const raw = /** @type {{ deleted?: unknown }} */ (envelope).deleted;
  if (!Array.isArray(raw)) return [];

  const ids = new Set();
  for (const e of raw) {
    if (typeof e === 'number' || typeof e === 'string') {
      const n = typeof e === 'number' ? e : Number(e);
      if (Number.isFinite(n)) ids.add(String(n));
      continue;
    }
    if (!e || typeof e !== 'object') continue;
    const m = /** @type {Record<string, unknown>} */ (e);
    const rawId = m.id ?? m.record_id ?? m.model_id;
    if (typeof rawId === 'number') ids.add(String(rawId));
    else if (typeof rawId === 'string' && rawId.trim()) {
      const p = Number(rawId);
      ids.add(Number.isFinite(p) ? String(p) : rawId.trim());
    }
  }
  return [...ids];
}

/**
 * @param {unknown} row
 */
function normEntityId(row) {
  if (!row || typeof row !== 'object') return '';
  const m = /** @type {Record<string, unknown>} */ (row);
  const id = m.id ?? m.uuid;
  return id != null ? String(id) : '';
}

function paginationComplete(meta) {
  if (!meta || typeof meta !== 'object') return true;
  const m = /** @type {Record<string, unknown>} */ (meta);
  if (m.has_more === true) return false;
  if (m.hasMore === true) return false;
  const cp = Number(m.current_page);
  const lp = Number(m.last_page);
  if (Number.isFinite(cp) && Number.isFinite(lp)) {
    if (cp < lp) return false;
  }
  return true;
}

/**
 * @param {*} db
 * @param {{ success?: unknown; message?: unknown; errors?: unknown; data?: unknown }} pullJson
 */
async function applyPullEnvelope(db, pullJson, log) {
  const lg = /** @type {{ warn?: (...a: unknown[]) => void } | undefined} */ (log);
  const warn = (...args) =>
    typeof lg?.warn === 'function' ? /** @type {(...a: unknown[]) => void} */ (lg.warn)(...args)
      : console.warn(...args);
  const dataRoot = pullJson.data;
  if (!dataRoot || typeof dataRoot !== 'object') {
    warn('pull page missing data');
    return { touchedItems: false };
  }
  const data = /** @type {Record<string, unknown>} */ (dataRoot);

  let touchedItems = false;
  const upsertSql =
    `INSERT INTO cloud_mirror_entities (resource_key, entity_id, record_json, updated_at, synced_at)
     VALUES (?, ?, ?, ?, ?)
     ON CONFLICT(resource_key, entity_id) DO UPDATE SET
       record_json = excluded.record_json,
       updated_at = excluded.updated_at,
       synced_at = excluded.synced_at`;
  const deleteSql = 'DELETE FROM cloud_mirror_entities WHERE resource_key = ? AND entity_id = ?';

  await db.transaction(async () => {
    const t = nowIso();
    for (const key of PULL_RESOURCE_KEYS) {
      const envelope = data[key];
      if (!envelope || typeof envelope !== 'object') continue;
      const list = listCreatedUpdated(envelope);
      for (const raw of list) {
        const id = normEntityId(raw);
        if (!id) continue;
        await db.run(upsertSql, [key, id, JSON.stringify(raw), t, t]);
        if (key === 'item') touchedItems = true;
      }
      const delIds = extractDeletedIds(envelope);
      for (const id of delIds) {
        await db.run(deleteSql, [key, id]);
        if (key === 'item') touchedItems = true;
      }
    }
  });

  return { touchedItems };
}

/**
 * @param {*} db
 * @param {AppConfig['cloud_sync']} cfg
 */
async function refreshBootstrap(db, cfg, fwdHeaders) {
  const { ok, status, body } = await cloudFetchJson(cfg, 'GET', '/api/v1/sync/bootstrap', {
    forwardHeaders: fwdHeaders,
  });
  if (!ok) {
    const msg =
      typeof body === 'object' && body !== null && 'message' in body
        ? String(/** @type {{ message?: unknown }} */ (body).message)
        : `HTTP ${status}`;
    throw new Error(`bootstrap failed: ${msg}`);
  }
  const t = nowIso();
  await db.run(
    `INSERT INTO cloud_bootstrap_snapshot (id, raw_json, updated_at) VALUES (1, ?, ?)
     ON CONFLICT(id) DO UPDATE SET raw_json = excluded.raw_json, updated_at = excluded.updated_at`,
    [JSON.stringify(body), t],
  );
}

/**
 * @param {*} db
 * @param {AppConfig} config
 */
async function runInitialMasterSync(db, config, fwdHeaders, hub, log) {
  await ensureResolvedCloudBase(db, config.cloud_sync);
  await refreshBootstrap(db, config.cloud_sync, fwdHeaders);

  /** @type {Record<string, { current_page?: number; last_page?: number; has_more?: boolean }>} */
  const metaByResource = {};

  let page = 1;
  const maxPages = config.cloud_sync.max_pull_pages || 500;
  for (; page <= maxPages; page++) {
    const { ok, status, body } = await cloudFetchJson(config.cloud_sync, 'GET', `/api/v1/pull_records?page=${page}`, {
      forwardHeaders: fwdHeaders,
    });
    if (!ok) throw new Error(`pull_records page=${page}: HTTP ${status}`);
    const b = /** @type {{ success?: boolean; message?: string; data?: unknown }} */ (body);
    if (!b.success) {
      throw new Error(b.message || `pull unsuccessful page ${page}`);
    }

    const { touchedItems } = await applyPullEnvelope(
      db,
      /** @type {{ success?: unknown; message?: unknown; errors?: unknown; data?: unknown }} */ (body),
      log
    );

    let allDone = true;
    const dataRoot = b.data && typeof b.data === 'object' ? /** @type {Record<string, unknown>} */ (b.data) : null;
    for (const key of PULL_RESOURCE_KEYS) {
      const envelope = dataRoot && dataRoot[key] && typeof dataRoot[key] === 'object'
        ? /** @type {{ pagination?: unknown }} */ (dataRoot[key])
        : null;
      const pagination = envelope && envelope.pagination && typeof envelope.pagination === 'object'
        ? envelope.pagination
        : null;

      metaByResource[key] = pagination
        ? {
            .../** @type {Record<string, number | boolean>} */ (pagination),
          }
        : metaByResource[key] || {};

      if (!paginationComplete(pagination)) {
        allDone = false;
      }
    }

    if (hub) {
      if (touchedItems) hub.broadcast({ type: 'ITEMS_UPDATED', payload: { page, source: 'pull' } });
    }

    if (allDone) break;
  }

  await metaSet(db, 'cloud_last_pull_at', nowIso());
  if (hub) {
    hub.broadcast({ type: 'DATA_SYNCED', payload: { phase: 'pull', pages: page } });
  }
}

/**
 * @param {unknown[]} rows
 */
function mergePushBodies(rows) {
  const merged = { expenses: /** @type {unknown[]} */ ([]), customers: [], sales: [], credit_sales: [] };
  for (const row of rows) {
    let p;
    try {
      p = typeof row.payload_json === 'string' ? JSON.parse(row.payload_json) : row;
    } catch {
      continue;
    }
    if (!p || typeof p !== 'object') continue;
    const o = /** @type {Record<string, unknown>} */ (p);
    if (Array.isArray(o.expenses)) merged.expenses.push(.../** @type {unknown[]} */ (o.expenses));
    if (Array.isArray(o.customers)) merged.customers.push(.../** @type {unknown[]} */ (o.customers));
    if (Array.isArray(o.sales)) merged.sales.push(.../** @type {unknown[]} */ (o.sales));
    if (Array.isArray(o.credit_sales)) merged.credit_sales.push(.../** @type {unknown[]} */ (o.credit_sales));
  }
  return merged;
}

function emptyPushPing() {
  return { expenses: [], customers: [], sales: [], credit_sales: [] };
}

/**
 * @param {*} db
 * @param {AppConfig} config
 */
async function flushOutboundPushJobs(db, config, hub, log, fwdHeaders) {
  await ensureResolvedCloudBase(db, config.cloud_sync);

  const now = nowIso();
  const jobs = await db.all(
    `SELECT * FROM cloud_mirror_push_jobs
       WHERE is_synced = 0 AND (next_attempt_at IS NULL OR next_attempt_at <= ?)
       ORDER BY created_at ASC LIMIT 10`,
    [now],
  );

  if (!jobs.length) return;

  const bodyObj = mergePushBodies(jobs);
  try {
    const { ok, status, body } = await cloudFetchJson(config.cloud_sync, 'POST', '/api/v1/push_records', {
      forwardHeaders: fwdHeaders,
      body: bodyObj,
    });
    if (!ok) {
      const snippet =
        typeof body === 'object' && body !== null ? JSON.stringify(body).slice(0, 900) : `HTTP ${status}`;
      throw new Error(snippet || `HTTP ${status}`);
    }
    const ids = jobs.map((j) => String(/** @type {{ id: unknown }} */ (j).id));
    const t = nowIso();
    const okSql =
      `UPDATE cloud_mirror_push_jobs SET is_synced = 1, updated_at = ?, last_error = NULL WHERE id = ?`;
    for (const id of ids) {
      await db.run(okSql, [t, id]);
    }
    await metaSet(db, 'cloud_last_push_at', t);
    if (hub && (bodyObj.sales.length || bodyObj.customers.length)) {
      hub.broadcast({ type: 'ORDER_UPDATED', payload: { source: 'cloud_push', synced: true } });
    }
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    const failSql =
      `UPDATE cloud_mirror_push_jobs SET retry_count = retry_count + 1, last_error = ?, updated_at = ?,
       next_attempt_at = ? WHERE id = ?`;
    let delayMs = 2000;
    for (const j of jobs) {
      const rc = Number(/** @type {{ retry_count?: number }} */ (j).retry_count || 0) + 1;
      delayMs = Math.min(5 * 60 * 1000, 800 * Math.pow(2, Math.min(rc, 10)));
      const nextIso = new Date(Date.now() + delayMs).toISOString();
      if (rc > config.cloud_sync.max_retries) {
        log.warn('push job %s exceeded retries — skipping', /** @type {{ id?: string }} */ (j).id);
        continue;
      }
      await db.run(failSql, [msg.slice(0, 1900), nowIso(), nextIso, String(/** @type {{ id: string }} */ (j).id)]);
    }
    log.warn('flushOutboundPushJobs: %s', msg);
    throw e;
  }
}

/**
 * Send keep-alive ping (matches Flutter behaviour when queues are empty).
 */
async function pushRecordsPing(db, config, hub, fwdHeaders) {
  await ensureResolvedCloudBase(db, config.cloud_sync);

  const { ok, status, body } = await cloudFetchJson(config.cloud_sync, 'POST', '/api/v1/push_records', {
    forwardHeaders: fwdHeaders,
    body: emptyPushPing(),
  });
  if (!ok) {
    const snippet =
      typeof body === 'object' && body !== null ? JSON.stringify(body).slice(0, 400) : `HTTP ${status}`;
    throw new Error(`push_records ping: ${snippet}`);
  }
  await metaSet(db, 'cloud_last_push_ping_at', nowIso());
}

/**
 * Worker state mutated across ticks.
 */
function createTickState() {
  return {
    lastPullTs: 0,
    lastPushTs: 0,
    consecutiveErrors: 0,
  };
}

/**
 * One worker iteration: gated pull interval + outbound jobs + heartbeat ping fallback.
 *
 * @param {*} db
 * @param {{ config: AppConfig; hub?: import('../websocket/index').WebSocketHub | null; fwdHeaders?: Record<string, string> }} ctx
 */
async function runWorkerTick(db, ctx, tickState, log = console) {
  const cfg = ctx.config.cloud_sync;

  await ensureResolvedCloudBase(db, cfg);

  const now = Date.now();
  let pullRan = false;
  if (
    cfg.node_cloud_engine_enabled &&
    now - tickState.lastPullTs >= Math.round(cfg.pull_interval_seconds * 1000)
  ) {
    try {
      /** @type {unknown} */
      await runPaginatedIncrementalPull(db, ctx.config, ctx.fwdHeaders, ctx.hub, log);
      tickState.lastPullTs = Date.now();
      pullRan = true;
      tickState.consecutiveErrors = 0;
      if (ctx.hub) ctx.hub.broadcast({ type: 'DATA_SYNCED', payload: { phase: 'heartbeat_pull' } });
    } catch (e) {
      tickState.consecutiveErrors++;
      log.warn('[cloud-sync] pull tick failed %s', e instanceof Error ? e.message : String(e));
    }
  }

  if (cfg.node_cloud_engine_enabled && now - tickState.lastPushTs >= Math.round(cfg.push_interval_seconds * 1000)) {
    try {
      const cRow =
        (await db.get(`SELECT COUNT(1) AS c FROM cloud_mirror_push_jobs WHERE is_synced = 0`, [])) ?? {};
      const pending = Number(
        /** @type {{ c?: unknown }} */ (cRow).c ?? 0
      ) || 0;
      if (pending > 0) {
        await flushOutboundPushJobs(db, ctx.config, ctx.hub, log, ctx.fwdHeaders);
      } else {
        await pushRecordsPing(db, ctx.config, ctx.hub, ctx.fwdHeaders);
      }
      tickState.lastPushTs = Date.now();
      tickState.consecutiveErrors = 0;
    } catch (e) {
      tickState.consecutiveErrors++;
      log.warn('[cloud-sync] push tick failed %s', e instanceof Error ? e.message : String(e));
    }
  }

  return { pullRan };
}

/**
 * Lighter incremental pull (single page) after startup full sync elsewhere.
 *
 * @param {*} db
 */
async function runPaginatedIncrementalPull(db, config, fwdHeaders, hub, log) {
  await ensureResolvedCloudBase(db, config.cloud_sync);

  /** @typedef {{ current_page?: number }} PgLike */
  const nextPageRow = await metaGet(db, 'cloud_next_pull_page');
  let page = Number(nextPageRow) || 1;
  if (!Number.isFinite(page) || page < 1) page = 1;

  const { ok, status, body } = await cloudFetchJson(config.cloud_sync, 'GET', `/api/v1/pull_records?page=${page}`, {
    forwardHeaders: fwdHeaders,
  });
  if (!ok) throw new Error(`pull_records incremental: HTTP ${status}`);
  const b = /** @type {{ success?: boolean; message?: string; data?: unknown }} */ (body);
  if (!b.success) throw new Error(b.message || 'pull unsuccessful');

  const { touchedItems } = await applyPullEnvelope(db, /** @type {never} */ (body), log);
  await metaSet(db, 'cloud_last_pull_at', nowIso());

  /** @typedef {{ pagination?: Record<string, unknown> }} Env */
  let allDone = true;
  const dataRoot = b.data && typeof b.data === 'object' ? /** @type {Record<string, unknown>} */ (b.data) : null;
  for (const key of PULL_RESOURCE_KEYS) {
    const envelope = dataRoot && dataRoot[key] && typeof dataRoot[key] === 'object'
      ? /** @type {{ pagination?: Record<string, unknown> }} */ (dataRoot[key])
      : null;
    const pagination =
      envelope?.pagination && typeof envelope.pagination === 'object' ? envelope.pagination : undefined;
    if (!paginationComplete(pagination)) allDone = false;
  }

  await metaSet(db, 'cloud_next_pull_page', String(allDone ? 1 : page + 1));
  await metaSet(db, 'cloud_incremental_watermark_iso', nowIso());

  if (hub) {
    if (touchedItems) hub.broadcast({ type: 'ITEMS_UPDATED', payload: { page, incremental: true } });
    hub.broadcast({ type: 'DATA_SYNCED', payload: { phase: 'incremental', page } });
  }
}

/**
 * @param {*} db
 * @param {Record<string, unknown>} payload — Flutter-shaped `push_records` body fragment
 */
async function enqueueOutboundPushRecords(db, payload) {
  const id = randomUUID();
  const t = nowIso();
  await db.run(
    `INSERT INTO cloud_mirror_push_jobs (
       id, payload_json, created_at, updated_at, is_synced, retry_count, last_error, next_attempt_at)
     VALUES (?, ?, ?, ?, 0, 0, NULL, ?)`,
    [id, JSON.stringify(payload), t, t, t],
  );
}

/**
 * HTTP passthrough proxy (migration): Flutter sends same paths as Dio would.
 *
 */
async function forwardProxyRequest(opts) {
  const {
    resolvedBase,
    method,
    pathWithQuery,
    headers,
    bodyBuffer,
    bodyJson,
    cloud_sync_fragment,
  } = opts;
  const cfgUse = /** @type {AppConfig['cloud_sync']} */ (cloud_sync_fragment);
  const base = normalizeCloudBase(resolvedBase);
  const url = resolveCloudUrl(base, pathWithQuery.replace(/^\/+/, ''));
  const merged = bearerHeadersForCloud(cfgUse);
  if (headers) {
    const fh = headers;
    const xh = fh['x-auth-key'] ?? fh['X-Auth-Key'];
    if (typeof xh === 'string' && xh.trim()) merged['X-Auth-Key'] = xh.trim();
  }
  /** @type {RequestInit & { duplex?: string }} */
  const req = {
    method,
    headers: merged,
    redirect: 'follow',
  };

  let sendBody =
    typeof bodyJson === 'string' ? bodyJson : bodyJson !== undefined ? JSON.stringify(bodyJson) : undefined;
  if (bodyBuffer !== undefined && bodyBuffer !== null) {
    req.body =
      Buffer.isBuffer(bodyBuffer) ||
      typeof bodyBuffer === 'string' ||
      bodyBuffer instanceof Uint8Array
        ? Buffer.from(bodyBuffer)
        : String(bodyBuffer);
    if (!merged['content-type']) merged['content-type'] = 'application/json';
    sendBody = undefined;
  }
  if (sendBody !== undefined) {
    req.body = sendBody;
  }
  const res = await fetch(url.toString(), req);

  /** @type {Buffer} */
  const buf = Buffer.from(await res.arrayBuffer());

  /** @type {Record<string, string | string[]>} */
  const outHeaders = {};
  res.headers.forEach((v, k) => {
    outHeaders[k] = v;
  });

  return { statusCode: res.status, headers: outHeaders, buffer: buf };
}

module.exports = {
  /** @deprecated use fetchBaseUrlFromCommon */
  fetchBaseUrl: fetchBaseUrlFromCommon,
  normalizeCloudBase,
  fetchBaseUrlFromCommon,
  ensureResolvedCloudBase,
  refreshBootstrap,
  runInitialMasterSync,
  flushOutboundPushJobs,
  enqueueOutboundPushRecords,
  cloudFetchJson,
  applyPullEnvelope,
  runPaginatedIncrementalPull,
  metaGet,
  metaSet,
  createTickState,
  runWorkerTick,
  forwardProxyRequest,
};
