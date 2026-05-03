'use strict';

const express = require('express');
const { createHttpConnectionLogger } = require('./middleware/connectionLog');
const { createHealthRouter } = require('./routes/health');
const { createOrdersRouter } = require('./routes/orders');
const { createSyncCatalogRouter } = require('./routes/sync_catalog');

/** @typedef {import('./config/index').AppConfig} AppConfig */

/**
 * @param {*} db — async SQLite hub API ({ run, get, all, exec, transaction, close })
 * @param {{ hub: ReturnType<import('./websocket/index').createWebSocketHub> | null; config: AppConfig }} ctx
 * @param {import('express').RequestHandler | null} authMiddleware — bearer auth (applied to ALL HTTP routes incl. health)
 */
function createHttpApp(db, ctx, authMiddleware) {
  const app = express();

  app.disable('x-powered-by');
  app.use((req, res, next) => {
    res.setHeader('access-control-allow-origin', '*');
    res.setHeader('access-control-allow-methods', 'GET,POST,PATCH,DELETE,OPTIONS');
    res.setHeader('access-control-allow-headers', 'content-type,authorization');
    if (req.method === 'OPTIONS') return res.sendStatus(204);
    next();
  });

  /** LAN / sub-device visibility: logs /sync/* by default (mirror pulls). See connectionLog.js env toggles. */
  app.use(createHttpConnectionLogger());

  if (authMiddleware) app.use(authMiddleware);

  /** `/sync/proxy/*` parses raw upstream bodies; `/sync/trigger-resync` uses router-local JSON. */
  app.use('/sync', createSyncCatalogRouter(db, { hub: ctx.hub, config: ctx.config }));

  app.use(express.json({ limit: '10mb' }));

  app.use('/health', createHealthRouter(db));
  app.use('/orders', createOrdersRouter(db, ctx));

  app.use((_req, res) => res.status(404).json({ error: 'not_found' }));

  app.use((err, _req, res, _next) => {
    console.error('[http]', err);
    res.status(500).json({ error: 'internal_error' });
  });

  return app;
}

module.exports = { createHttpApp };
