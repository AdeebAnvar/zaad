'use strict';

const express = require('express');
const cloudSync = require('../sync/cloudSyncService');

/** @typedef {import('../config/index').AppConfig} AppConfig */

/**
 * Cached master data + migration proxy tunnel under `/sync/...`.
 *
 * @param {*} db
 * @param {{ config: AppConfig; hub?: import('../websocket/index').WebSocketHub | null }} ctx
 */
function createSyncCatalogRouter(db, ctx) {
  const router = express.Router();

  router.use(
    '/proxy',
    express.raw({ type: '*/*', limit: '50mb' }),
    async (req, res) => {
      try {
        const baseUrl =
          '' + (await cloudSync.ensureResolvedCloudBase(db, ctx.config.cloud_sync));
        const pathWithQuery = pathAfterSegments(req.originalUrl || req.url, '/proxy');

        const methodUp = String(req.method || 'GET').toUpperCase();
        const out = await cloudSync.forwardProxyRequest({
          resolvedBase: baseUrl,
          method: methodUp,
          pathWithQuery,
          headers: req.headers,
          cloud_sync_fragment: ctx.config.cloud_sync,
          bodyBuffer:
            req.method === 'GET' || req.method === 'HEAD' || req.method === 'OPTIONS' ?
              undefined
            : Buffer.isBuffer(req.body) ?
              req.body
            : undefined,
        });

        // When the main Flutter app pulls catalog via `/sync/proxy/.../pull_records`, persist the same
        // JSON into hub SQLite so LAN sub devices can read `/sync/mirror/*` (otherwise mirror stays empty).
        if (
          methodUp === 'GET' &&
          out.statusCode >= 200 &&
          out.statusCode < 300 &&
          /pull_records/i.test(pathWithQuery)
        ) {
          try {
            const txt = (out.buffer ?? Buffer.alloc(0)).toString('utf8');
            const pullJson = JSON.parse(txt);
            if (pullJson && typeof pullJson === 'object') {
              await cloudSync.applyPullEnvelope(db, pullJson, console);
              if (ctx.hub) {
                ctx.hub.broadcast({
                  type: 'DATA_SYNCED',
                  payload: { phase: 'proxy_pull_mirror', path: pathWithQuery },
                });
              }
            }
          } catch (e) {
            console.warn(
              '[sync/proxy] could not apply pull_records to hub mirror:',
              e instanceof Error ? e.message : String(e),
            );
          }
        }

        for (const [k, v] of Object.entries(out.headers || {})) {
          if (/^transfer-encoding$/i.test(k)) continue;
          if (typeof v === 'string') res.setHeader(k, v);
          else if (Array.isArray(v)) res.setHeader(k, v);
        }
        return res.status(out.statusCode).send(out.buffer ?? Buffer.alloc(0));
      } catch (e) {
        const m = e instanceof Error ? e.message : String(e);
        return res.status(502).json({ error: 'proxy_failed', detail: m });
      }
    },
  );

  router.use(express.json({ limit: '10mb' }));

  router.get('/bootstrap', async (_req, res) => {
    try {
      const row = await db.get('SELECT raw_json FROM cloud_bootstrap_snapshot WHERE id = 1', []);
      if (!row || !row.raw_json) {
        return res
          .status(503)
          .json({ success: false, error: 'bootstrap_pending', message: 'Run cloud sync once' });
      }
      return res.status(200).type('json').send(String(row.raw_json));
    } catch {
      return res.status(500).json({ success: false, error: 'bootstrap_read_failed' });
    }
  });

  router.get('/summary', async (_req, res) => {
    try {
      const row = await db.get('SELECT raw_json FROM cloud_bootstrap_snapshot WHERE id = 1', []);
      if (!row || !row.raw_json) return res.status(503).json({ error: 'bootstrap_pending' });

      /** @typedef {{ success?: unknown; data?: Record<string, unknown>; user?: unknown[] }} Px */
      const parsed = JSON.parse(String(row.raw_json));
      const px = /** @type {Px} */ (parsed);
      const inner = typeof px.success === 'boolean' && px.data !== undefined ? px.data : px;
      return res.json({
        branches:
          inner && typeof inner === 'object' && Array.isArray(/** @type {{ branch?: unknown[] }} */ (inner).branch)
            ? /** @type {{ branch?: unknown[] }} */ (inner).branch
            : [],
        settings:
          inner && typeof inner === 'object' ?
            /** @type {{ settings?: unknown }} */ (inner).settings ?? null
          : null,
        company:
          inner && typeof inner === 'object' ?
            /** @type {{ company?: unknown }} */ (inner).company ?? null
          : null,
        users:
          inner && typeof inner === 'object' ?
            Array.isArray(/** @type {{ user?: unknown[] }} */ (inner).user) ?
              /** @type {{ user?: unknown[] }} */ (inner).user ?? []
            : []
          : [],
      });
    } catch {
      return res.status(500).json({ error: 'bootstrap_read_failed' });
    }
  });

  async function mirrorList(resourceKey, req, res) {
    try {
      const limit = Math.min(500, Math.max(1, Number(req.query.limit) || 200));
      const offset = Math.max(0, Number(req.query.offset) || 0);
      const rows = await db.all(
        `SELECT entity_id, record_json FROM cloud_mirror_entities WHERE resource_key = ?
           ORDER BY entity_id COLLATE NOCASE LIMIT ? OFFSET ?`,
        [resourceKey, limit, offset],
      );
      const mapped = rows.map((r) => {
        /** @typedef {{ entity_id?: string; record_json?: string }} Rw */
        const rr = /** @type {Rw} */ (r);
        try {
          return { id: rr.entity_id, ...JSON.parse(String(rr.record_json || '{}')) };
        } catch {
          return { id: rr.entity_id, raw: rr.record_json };
        }
      });
      return res.json({
        resource: resourceKey,
        count: mapped.length,
        limit,
        offset,
        rows: mapped,
      });
    } catch {
      return res.status(500).json({ error: 'list_failed', resourceKey });
    }
  }

  /** Matches [cloudSyncService] pull resource keys — LAN satellites fetch these pages from the hub mirror. */
  const MIRROR_RESOURCE_KEYS = new Set([
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
  ]);

  router.get('/mirror/:resourceKey', async (req, res) => {
    const key = String(req.params.resourceKey || '').trim();
    if (!MIRROR_RESOURCE_KEYS.has(key)) {
      return res.status(400).json({ error: 'unknown_resource', resourceKey: key });
    }
    return mirrorList(key, req, res);
  });

  router.get('/categories', async (req, res) => mirrorList('category', req, res));

  router.get('/items', async (req, res) => mirrorList('item', req, res));

  router.get('/users', async (_req, res, next) => {
    try {
      const staffRowsRaw = await db.all(
        `SELECT record_json FROM cloud_mirror_entities WHERE resource_key IN ('staffs','waiters') ORDER BY resource_key`,
        [],
      );
      const staffRows = staffRowsRaw
        .map((r) => {
          /** @typedef {{ record_json?: string }} Rrw */
          const rx = /** @type {Rrw} */ (r);
          try {
            return JSON.parse(String(rx.record_json || '{}'));
          } catch {
            return null;
          }
        })
        .filter(Boolean);

      const boot = await db.get('SELECT raw_json FROM cloud_bootstrap_snapshot WHERE id = 1', []);
      /** @type {unknown[]} */
      let usersFromBootstrap = [];
      if (boot && boot.raw_json) {
        try {
          const pj = JSON.parse(String(boot.raw_json));
          const inner = pj && pj.data !== undefined ? pj.data : pj;
          if (
            inner &&
            typeof inner === 'object' &&
            Array.isArray(/** @type {{ user?: unknown[] }} */ (inner).user)
          ) {
            usersFromBootstrap = [.../** @type {unknown[]} */ ((/** @type {{ user?: unknown[] }} */ (inner).user ?? []))];
          }
        } catch (_) {
          /* ignore */
        }
      }
      return res.json({
        users: [...usersFromBootstrap, ...staffRows],
      });
    } catch (e) {
      next(e);
    }
  });

  router.get('/customers', async (req, res) => mirrorList('customer', req, res));

  /**
   * Flutter stores the tenant API root in SharedPreferences after common-api login; Node cannot read that.
   * POST `{ "api_base_url": "https://tenant.example" }` to persist into sync_meta + in-memory config so
   * trigger-resync / worker can call `ensureResolvedCloudBase` without static api_base_url in config.json.
   */
  router.post('/tenant-base', async (req, res) => {
    try {
      const raw = req.body && typeof req.body === 'object' ? req.body.api_base_url : null;
      const s = String(raw || '').trim();
      if (!s) {
        return res.status(400).json({ ok: false, error: 'missing_api_base_url' });
      }
      const u = new URL(s);
      if (u.protocol !== 'http:' && u.protocol !== 'https:') {
        return res.status(400).json({ ok: false, error: 'invalid_api_base_url' });
      }
      const normalized = cloudSync.normalizeCloudBase(s);
      await cloudSync.metaSet(db, 'cloud_resolved_base_url', normalized);
      ctx.config.cloud_sync.api_base_url = normalized;
      return res.json({ ok: true, api_base_url: normalized });
    } catch (e) {
      const m = e instanceof Error ? e.message : String(e);
      return res.status(400).json({ ok: false, error: 'invalid_api_base_url', message: m });
    }
  });

  router.post('/trigger-resync', async (_req, res) => {
    // Manual mirror refresh — needs resolvable tenant URL (config, meta, or POST /sync/tenant-base).
    // Cloud HTTP uses same X-Auth-Key default as Flutter [DioClient]; optional Bearer via CLOUD_POS_TOKEN.
    const cs = ctx.config.cloud_sync;
    try {
      await cloudSync.ensureResolvedCloudBase(db, cs);
      await cloudSync.refreshBootstrap(db, cs, undefined);
      await cloudSync.runInitialMasterSync(db, ctx.config, undefined, ctx.hub, console);
      if (ctx.hub) ctx.hub.broadcast({ type: 'DATA_SYNCED', payload: { phase: 'manual_resync' } });
      return res.json({ ok: true });
    } catch (e) {
      const m = e instanceof Error ? e.message : String(e);
      const looksConfig =
        /cloud base URL not configured|missing url|app_id|resolve/i.test(m) ||
        /CLOUD_POS_TOKEN|authorization|401|403/i.test(m);
      return res.status(looksConfig ? 400 : 500).json({
        ok: false,
        error: looksConfig ? 'cloud_not_configured_or_auth' : 'resync_failed',
        message: m,
      });
    }
  });

  return router;
}

/**
 * Given `/sync/proxy/api/v1/x?foo=1` → `/api/v1/x?foo=1`
 *
 * @param {string} fullUrlOriginal
 * @param {string} marker e.g. `/proxy`
 */
function pathAfterSegments(fullUrlOriginal, marker) {
  const qIx = fullUrlOriginal.indexOf('?');
  const pathOnly = qIx >= 0 ? fullUrlOriginal.slice(0, qIx) : fullUrlOriginal;
  const query = qIx >= 0 ? fullUrlOriginal.slice(qIx) : '';
  let idx = pathOnly.lastIndexOf(marker);
  if (idx < 0) idx = pathOnly.indexOf(marker);
  if (idx < 0) return `/${fullUrlOriginal.replace(/^\/?/, '')}`;

  let tail = pathOnly.slice(idx + marker.length);
  tail = tail && tail.length ? tail : '/';
  if (!tail.startsWith('/')) tail = `/${tail}`;
  return `${tail}${query}`;
}

module.exports = { createSyncCatalogRouter };
