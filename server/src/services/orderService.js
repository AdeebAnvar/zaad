'use strict';

const { randomUUID } = require('crypto');

function nowIso() {
  return new Date().toISOString();
}

/**
 * @param {*} db — SQLite hub API ({ run, get, all, transaction }).
 */
async function allocateNextInvoiceNumber(db) {
  const row = await db.get('SELECT next_invoice_number FROM invoice_sequence WHERE id = 1', []);
  if (!row) throw new Error('invoice_sequence missing');
  const assigned = Number(row.next_invoice_number);
  await db.run('UPDATE invoice_sequence SET next_invoice_number = next_invoice_number + 1 WHERE id = 1', []);
  return assigned;
}

/**
 * Ensures device row exists and updates last_seen.
 *
 * @param {*} db
 * @param {unknown} device
 */
async function touchDevice(db, device) {
  if (!device || typeof device !== 'object') return null;
  const id = /** @type {{ id?: string }} */ (device).id;
  if (!id || typeof id !== 'string') return null;

  const name = typeof /** @type {{ name?: string }} */ (device).name === 'string' ? device.name : null;
  const platform =
    typeof /** @type {{ platform?: string }} */ (device).platform === 'string' ? device.platform : null;
  const appVersion =
    typeof /** @type {{ appVersion?: string }} */ (device).appVersion === 'string'
      ? device.appVersion
      : null;

  const t = nowIso();
  const existing = await db.get('SELECT id FROM devices WHERE id = ?', [id]);
  if (existing) {
    await db.run(
      `UPDATE devices SET name = COALESCE(?, name), platform = COALESCE(?, platform),
        app_version = COALESCE(?, app_version), last_seen_at = ?, updated_at = ?,
        is_synced = 0
       WHERE id = ?`,
      [name, platform, appVersion, t, t, id],
    );
  } else {
    await db.run(
      `INSERT INTO devices (id, name, platform, app_version, last_seen_at, created_at, updated_at, is_synced, retry_count)
       VALUES (?, ?, ?, ?, ?, ?, ?, 0, 0)`,
      [id, name, platform, appVersion, t, t, t],
    );
  }
  return id;
}

/**
 * @param {*} db
 * @param {object} input
 * @param {(row: { id: string, operation: string, entity_type: string, entity_id?: string | null, payload: string }) => void | Promise<void>} onEnqueueSync
 */
async function createOrder(db, input, onEnqueueSync) {
  const itemsRaw = Array.isArray(input.items) ? input.items : [];
  const paymentsRaw = Array.isArray(input.payments) ? input.payments : [];
  const customerId =
    typeof input.customerId === 'string' ? input.customerId : input.customer_id != null ? String(input.customer_id) : null;

  const notes = typeof input.notes === 'string' ? input.notes : null;
  /** @type {string | null} */
  let metadataJson = null;
  if (input.metadata !== undefined && input.metadata !== null) {
    try {
      metadataJson = JSON.stringify(input.metadata);
    } catch {
      throw new Error('metadata must be JSON-serializable');
    }
  }

  const deviceId = await touchDevice(db, input.device);

  const orderId = typeof input.localId === 'string' ? input.localId : randomUUID();
  /** @typedef {{ id?: string; sku?: string; name?: string; qty?: number; unitPriceCents?: number }} ItemIn */
  const itemsParsed = [];
  let total = 0;
  for (const raw of itemsRaw) {
    if (!raw || typeof raw !== 'object') continue;
    const r = /** @type {ItemIn} */ (raw);
    const name = typeof r.name === 'string' ? r.name : '';
    const qty = Number(r.qty);
    const qtyN = Number.isFinite(qty) && qty > 0 ? qty : 1;
    const unitPrice = Number(r.unitPriceCents ?? r.unit_price_cents ?? 0);
    const unitN = Number.isFinite(unitPrice) ? Math.round(unitPrice) : 0;
    const lineTotal = Math.round(qtyN * unitN);
    total += lineTotal;
    itemsParsed.push({
      id: typeof r.id === 'string' ? r.id : randomUUID(),
      sku: typeof r.sku === 'string' ? r.sku : null,
      name: name || 'Item',
      qty: qtyN,
      unit_price_cents: unitN,
      line_total_cents: lineTotal,
      tax_cents:
        typeof r.taxCents === 'number'
          ? Math.round(r.taxCents)
          : typeof r.tax_cents === 'number'
            ? Math.round(r.tax_cents)
            : 0,
    });
  }

  /** @typedef {{ id?: string; method?: string; amountCents?: number; reference?: string; metadata?: unknown }} PayIn */
  const paymentsParsed = [];
  for (const raw of paymentsRaw) {
    if (!raw || typeof raw !== 'object') continue;
    const p = /** @type {PayIn} */ (raw);
    paymentsParsed.push({
      id: typeof p.id === 'string' ? p.id : randomUUID(),
      method: typeof p.method === 'string' ? p.method : 'unknown',
      amount_cents: Math.round(Number(p.amountCents ?? p.amount_cents ?? 0)),
      reference: typeof p.reference === 'string' ? p.reference : null,
      metadata: Object.prototype.hasOwnProperty.call(p, 'metadata') ? p.metadata : undefined,
    });
  }

  const ALLOWED_STATUSES = new Set(['open', 'kot', 'placed', 'pending', 'completed', 'cancelled']);
  const statusIncoming =
    typeof input.status === 'string' ? input.status.trim() : '';
  const initialStatus =
    ALLOWED_STATUSES.has(statusIncoming) ? statusIncoming : 'open';

  let totalStored = total;
  if (typeof input.totalCents === 'number' && Number.isFinite(input.totalCents)) {
    totalStored = Math.round(input.totalCents);
  }

  const t0 = nowIso();

  await db.transaction(async () => {
    const invoice_number = await allocateNextInvoiceNumber(db);
    await db.run(
      `INSERT INTO orders (id, invoice_number, status, customer_id, device_id, total_cents, notes, metadata,
        created_at, updated_at, is_synced, retry_count)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0)`,
      [
        orderId,
        invoice_number,
        initialStatus,
        customerId,
        deviceId,
        totalStored,
        notes,
        metadataJson,
        t0,
        t0,
      ],
    );

    for (const row of itemsParsed) {
      const it = /** @type {typeof itemsParsed[number] & { id: string }} */ (row);
      await db.run(
        `INSERT INTO order_items (id, order_id, sku, name, qty, unit_price_cents, line_total_cents, tax_cents,
           created_at, updated_at, is_synced, retry_count)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0)`,
        [
          it.id,
          orderId,
          it.sku,
          it.name,
          it.qty,
          it.unit_price_cents,
          it.line_total_cents,
          it.tax_cents,
          t0,
          t0,
        ],
      );
    }

    for (const row of paymentsParsed) {
      const pt = /** @type {typeof paymentsParsed[number] & { id: string }} */ (row);
      let md = null;
      if ('metadata' in row && /** @type {{ metadata?: unknown }} */ (row).metadata !== undefined) {
        md = JSON.stringify(/** @type {{ metadata?: unknown }} */ (row).metadata);
      }
      await db.run(
        `INSERT INTO payments (id, order_id, method, amount_cents, reference, metadata,
           created_at, updated_at, is_synced, retry_count)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, 0)`,
        [pt.id, orderId, pt.method, pt.amount_cents, pt.reference, md, t0, t0],
      );
    }

    await Promise.resolve(
      onEnqueueSync({
        id: randomUUID(),
        operation: 'insert',
        entity_type: 'order',
        entity_id: orderId,
        payload: JSON.stringify({ invoice_number, orderId }),
      }),
    );
  });

  return getOrderById(db, orderId);
}

/**
 * @param {*} db
 * @param {string} id
 */
async function getOrderById(db, id) {
  const order = await db.get('SELECT * FROM orders WHERE id = ?', [id]);
  if (!order) return null;
  const items = await db.all('SELECT * FROM order_items WHERE order_id = ? ORDER BY created_at', [id]);
  const payments = await db.all('SELECT * FROM payments WHERE order_id = ? ORDER BY created_at', [id]);
  return { order, items, payments };
}

/**
 * @param {*} db
 * @param {{ limit?: number; offset?: number }} q
 */
async function listOrders(db, q) {
  const limit = Math.min(500, Math.max(1, Number(q.limit) || 50));
  const offset = Math.max(0, Number(q.offset) || 0);
  const rows = await db.all('SELECT * FROM orders ORDER BY created_at DESC LIMIT ? OFFSET ?', [limit, offset]);
  return rows;
}

/**
 * @param {*} db
 * @param {string} id
 * @param {string} status
 * @param {(row: { id: string, operation: string, entity_type: string, entity_id?: string | null, payload: string }) => void | Promise<void>} onEnqueueSync
 */
async function updateOrderStatus(db, id, status, onEnqueueSync) {
  return db.transaction(async () => {
    const row = await db.get('SELECT id FROM orders WHERE id = ?', [id]);
    if (!row) return null;
    const t = nowIso();
    await db.run(
      'UPDATE orders SET status = ?, updated_at = ?, is_synced = 0, retry_count = 0 WHERE id = ?',
      [status, t, id],
    );
    await Promise.resolve(
      onEnqueueSync({
        id: randomUUID(),
        operation: 'update',
        entity_type: 'order',
        entity_id: id,
        payload: JSON.stringify({ status }),
      }),
    );
    return getOrderById(db, id);
  });
}

/**
 * PATCH fields used by Flutter KOT totals / metadata merges.
 *
 * @param {*} db
 * @param {string} id
 * @param {Record<string, unknown>} input
 * @param {(row: { id: string, operation: string, entity_type: string, entity_id?: string | null, payload: string }) => void | Promise<void>} onEnqueueSync
 */
async function patchOrder(db, id, input, onEnqueueSync) {
  return db.transaction(async () => {
    const row = await db.get('SELECT * FROM orders WHERE id = ?', [id]);
    if (!row) return null;

    let metaObj = {};
    if (row.metadata) {
      try {
        metaObj = JSON.parse(String(row.metadata));
      } catch {
        metaObj = {};
      }
    }
    if (input.metadata !== undefined && input.metadata !== null && typeof input.metadata === 'object') {
      metaObj = { ...metaObj, .../** @type {object} */ (input.metadata) };
    }

    const statusNext =
      typeof input.status === 'string' && input.status.trim() ? input.status.trim() : String(row.status);

    let totalStored = Number(row.total_cents);
    if (typeof input.totalCents === 'number' && Number.isFinite(input.totalCents)) {
      totalStored = Math.round(input.totalCents);
    }

    const t = nowIso();
    await db.run(
      `UPDATE orders SET status = ?, total_cents = ?, metadata = ?, updated_at = ?,
       is_synced = 0, retry_count = 0 WHERE id = ?`,
      [statusNext, totalStored, JSON.stringify(metaObj), t, id],
    );

    await Promise.resolve(
      onEnqueueSync({
        id: randomUUID(),
        operation: 'update',
        entity_type: 'order',
        entity_id: id,
        payload: JSON.stringify({ status: statusNext, totalCents: totalStored }),
      }),
    );

    return getOrderById(db, id);
  });
}

/**
 * @param {*} db
 * @param {string} id
 * @param {(row: { id: string, operation: string, entity_type: string, entity_id?: string | null, payload: string }) => void | Promise<void>} onEnqueueSync
 */
async function deleteOrderById(db, id, onEnqueueSync) {
  return db.transaction(async () => {
    const row = await db.get('SELECT id FROM orders WHERE id = ?', [id]);
    if (!row) return false;
    await db.run('DELETE FROM order_items WHERE order_id = ?', [id]);
    await db.run('DELETE FROM payments WHERE order_id = ?', [id]);
    await db.run('DELETE FROM orders WHERE id = ?', [id]);

    await Promise.resolve(
      onEnqueueSync({
        id: randomUUID(),
        operation: 'delete',
        entity_type: 'order',
        entity_id: id,
        payload: JSON.stringify({ id }),
      }),
    );

    return true;
  });
}

module.exports = {
  createOrder,
  getOrderById,
  listOrders,
  updateOrderStatus,
  patchOrder,
  deleteOrderById,
};
