'use strict';

const express = require('express');
const orderService = require('../services/orderService');
const syncQueue = require('../services/syncQueueService');

/**
 * @typedef {{ hub: import('../websocket/index').WebSocketHub | null }} Ctx
 */

/**
 * @param {*} db
 * @param {Ctx} ctx
 */
function createOrdersRouter(db, ctx) {
  const router = express.Router();

  router.post('/', async (req, res) => {
    try {
      const created = await orderService.createOrder(db, req.body ?? {}, (job) => syncQueue.enqueueSync(db, job));
      if (!created) return res.status(500).json({ error: 'order_create_failed' });
      if (ctx.hub) ctx.hub.broadcast({ type: 'NEW_ORDER', payload: created });
      res.status(201).json(created);
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      res.status(400).json({ error: message });
    }
  });

  router.get('/', async (req, res, next) => {
    try {
      const rows = await orderService.listOrders(db, req.query);
      res.json(rows);
    } catch (e) {
      next(e);
    }
  });

  router.get('/:id', async (req, res, next) => {
    try {
      const full = await orderService.getOrderById(db, req.params.id);
      if (!full) return res.status(404).json({ error: 'not_found' });
      res.json(full);
    } catch (e) {
      next(e);
    }
  });

  router.patch(
    '/:id',
    async (req, res) => {
      const id = req.params.id;
      try {
        const updated = await orderService.patchOrder(db, id, req.body ?? {}, (job) =>
          syncQueue.enqueueSync(db, job),
        );
        if (!updated) return res.status(404).json({ error: 'not_found' });
        if (ctx.hub) ctx.hub.broadcast({ type: 'ORDER_UPDATED', payload: updated });
        res.json(updated);
      } catch (e) {
        const message = e instanceof Error ? e.message : String(e);
        res.status(400).json({ error: message });
      }
    },
  );

  router.delete('/:id', async (req, res) => {
    const id = req.params.id;
    try {
      const ok = await orderService.deleteOrderById(db, id, (job) => syncQueue.enqueueSync(db, job));
      if (!ok) return res.status(404).json({ error: 'not_found' });
      if (ctx.hub) ctx.hub.broadcast({ type: 'ORDER_DELETED', payload: { id } });
      res.status(204).send();
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      res.status(400).json({ error: message });
    }
  });

  router.patch('/:id/status', async (req, res) => {
    const id = req.params.id;
    const statusRaw = req.body?.status ?? req.body?.statusValue;
    if (typeof statusRaw !== 'string' || !statusRaw.trim()) {
      return res.status(400).json({ error: 'status_required' });
    }
    const status = statusRaw.trim();
    try {
      const updated = await orderService.updateOrderStatus(db, id, status, (job) =>
        syncQueue.enqueueSync(db, job),
      );
      if (!updated) return res.status(404).json({ error: 'not_found' });
      if (ctx.hub) ctx.hub.broadcast({ type: 'ORDER_UPDATED', payload: updated });
      res.json(updated);
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      res.status(400).json({ error: message });
    }
  });

  return router;
}

module.exports = { createOrdersRouter };
