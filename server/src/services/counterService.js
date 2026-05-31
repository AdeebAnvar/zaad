'use strict';

/**
 * Authoritative invoice suffix + pickup token counters for LAN MAIN hub.
 * All Flutter terminals (MAIN + SUB) allocate through POST /counters/allocate.
 */

function parseBranchScopedInvoice(raw) {
  if (raw == null) return null;
  const s = String(raw).trim();
  if (!s) return null;
  const m = /^([A-Za-z0-9]+)-(\d+)-(\d+)$/.exec(s);
  if (!m) return null;
  const branchId = Number.parseInt(m[2], 10);
  const suffix = Number.parseInt(m[3], 10);
  if (!Number.isFinite(branchId) || branchId <= 0 || !Number.isFinite(suffix) || suffix <= 0) {
    return null;
  }
  return { prefix: m[1], branchId, suffix };
}

function formatShortInvoice(prefix, branchId, suffix) {
  return `${prefix}-${branchId}-${String(suffix).padStart(3, '0')}`;
}

function readSnapshotField(snap, snakeKey, camelKey) {
  if (!snap || typeof snap !== 'object') return null;
  if (snap[snakeKey] != null) return snap[snakeKey];
  if (camelKey && snap[camelKey] != null) return snap[camelKey];
  const meta = snap.metadata;
  if (meta && typeof meta === 'object') {
    const flutter = meta.flutter;
    if (flutter && typeof flutter === 'object') {
      if (flutter[snakeKey] != null) return flutter[snakeKey];
      if (camelKey && flutter[camelKey] != null) return flutter[camelKey];
    }
  }
  return null;
}

function maxFromHubOrders(db, branchId, prefix) {
  let invoiceMax = 0;
  let tokenMax = 0;
  const rows = db.prepare('SELECT json FROM orders').all();
  for (const row of rows) {
    try {
      const payload = JSON.parse(row.json);
      const snap = payload && payload.snapshot && typeof payload.snapshot === 'object'
        ? payload.snapshot
        : payload;
      if (!snap || typeof snap !== 'object') continue;

      const snapBranch = readSnapshotField(snap, 'branch_id', 'branchId');
      const bid = typeof snapBranch === 'number' ? snapBranch : Number.parseInt(String(snapBranch || ''), 10);
      if (Number.isFinite(bid) && bid > 0 && bid !== branchId) continue;

      const invRaw = readSnapshotField(snap, 'invoice_number', 'invoiceNumber');
      const parsed = parseBranchScopedInvoice(invRaw);
      if (parsed && parsed.branchId === branchId && parsed.prefix === prefix) {
        if (parsed.suffix > invoiceMax) invoiceMax = parsed.suffix;
      }

      const tokRaw = readSnapshotField(snap, 'pickup_token', 'pickupToken');
      const tok = typeof tokRaw === 'number' ? tokRaw : Number.parseInt(String(tokRaw || ''), 10);
      if (Number.isFinite(tok) && tok > tokenMax) tokenMax = tok;
    } catch (_) {
      /* skip corrupt row */
    }
  }
  return { invoiceMax, tokenMax };
}

function getOrCreateCounterRow(db, branchId, prefix) {
  let row = db
    .prepare('SELECT branch_id, prefix, last_invoice_suffix, last_pickup_token FROM branch_counters WHERE branch_id = ? AND prefix = ?')
    .get(branchId, prefix);
  if (row) return row;
  db.prepare(
    'INSERT INTO branch_counters (branch_id, prefix, last_invoice_suffix, last_pickup_token, updated_at) VALUES (?, ?, 0, 0, ?)',
  ).run(branchId, prefix, Date.now());
  row = db
    .prepare('SELECT branch_id, prefix, last_invoice_suffix, last_pickup_token FROM branch_counters WHERE branch_id = ? AND prefix = ?')
    .get(branchId, prefix);
  return row;
}

function coerceInt(v) {
  if (typeof v === 'number' && Number.isFinite(v)) return Math.trunc(v);
  const n = Number.parseInt(String(v ?? ''), 10);
  return Number.isFinite(n) ? n : 0;
}

/**
 * @param {import('better-sqlite3').Database} db
 * @param {object} body
 */
function allocateCounters(db, body) {
  const branchId = coerceInt(body.branchId);
  const prefix = String(body.prefix || '').trim();
  if (branchId <= 0 || !prefix) {
    return { ok: false, error: 'branchId and prefix are required' };
  }

  const allocateInvoice = body.allocateInvoice === true;
  const allocatePickupToken = body.allocatePickupToken === true;
  if (!allocateInvoice && !allocatePickupToken) {
    return { ok: false, error: 'allocateInvoice or allocatePickupToken required' };
  }

  const trx = db.transaction(() => {
    const row = getOrCreateCounterRow(db, branchId, prefix);
    let invoiceMax = row.last_invoice_suffix || 0;
    let tokenMax = row.last_pickup_token || 0;

    invoiceMax = Math.max(invoiceMax, coerceInt(body.localInvoiceMax));
    tokenMax = Math.max(tokenMax, coerceInt(body.localPickupTokenMax));

    // Hot path: trust branch_counters + client localMax (seed + ORDER_* bump keep these current).
    // Full-table JSON scan here caused multi-second stalls on busy MAIN hubs.
    const scanHubOrders = body.scanHubOrders === true;
    if (scanHubOrders) {
      const hubMax = maxFromHubOrders(db, branchId, prefix);
      invoiceMax = Math.max(invoiceMax, hubMax.invoiceMax);
      tokenMax = Math.max(tokenMax, hubMax.tokenMax);
    }

    /** @type {{ ok: true, invoiceNumber?: string, invoiceSuffix?: number, pickupToken?: number }} */
    const result = { ok: true };

    if (allocateInvoice) {
      const next = invoiceMax + 1;
      result.invoiceSuffix = next;
      result.invoiceNumber = formatShortInvoice(prefix, branchId, next);
      invoiceMax = next;
    }

    if (allocatePickupToken) {
      const next = tokenMax + 1;
      result.pickupToken = next;
      tokenMax = next;
    }

    db.prepare(
      'UPDATE branch_counters SET last_invoice_suffix = ?, last_pickup_token = ?, updated_at = ? WHERE branch_id = ? AND prefix = ?',
    ).run(invoiceMax, tokenMax, Date.now(), branchId, prefix);

    return result;
  });

  return trx();
}

/**
 * Raise hub counters from MAIN bootstrap (never lowers).
 * @param {import('better-sqlite3').Database} db
 * @param {object} body
 */
function seedCounters(db, body) {
  const branchId = coerceInt(body.branchId);
  const prefix = String(body.prefix || '').trim();
  if (branchId <= 0 || !prefix) {
    return { ok: false, error: 'branchId and prefix are required' };
  }

  const trx = db.transaction(() => {
    const row = getOrCreateCounterRow(db, branchId, prefix);
    const invoiceMax = Math.max(row.last_invoice_suffix || 0, coerceInt(body.lastInvoiceSuffix));
    const tokenMax = Math.max(row.last_pickup_token || 0, coerceInt(body.lastPickupToken));
    db.prepare(
      'UPDATE branch_counters SET last_invoice_suffix = ?, last_pickup_token = ?, updated_at = ? WHERE branch_id = ? AND prefix = ?',
    ).run(invoiceMax, tokenMax, Date.now(), branchId, prefix);
    return { ok: true, lastInvoiceSuffix: invoiceMax, lastPickupToken: tokenMax };
  });

  return trx();
}

/**
 * After ORDER_* lands on hub, keep counters at least as high as the snapshot.
 * @param {import('better-sqlite3').Database} db
 * @param {object} payload ORDER_CREATE / ORDER_UPDATE payload
 */
function bumpCountersFromOrderPayload(db, payload) {
  const p = payload && typeof payload === 'object' ? payload : {};
  const snap = p.snapshot && typeof p.snapshot === 'object' ? p.snapshot : null;
  if (!snap) return;

  const branchId = coerceInt(readSnapshotField(snap, 'branch_id', 'branchId'));
  if (branchId <= 0) return;

  const invRaw = readSnapshotField(snap, 'invoice_number', 'invoiceNumber');
  const parsed = parseBranchScopedInvoice(invRaw);
  if (!parsed || parsed.branchId !== branchId) return;

  const tokRaw = readSnapshotField(snap, 'pickup_token', 'pickupToken');
  const tok = coerceInt(tokRaw);

  const trx = db.transaction(() => {
    const row = getOrCreateCounterRow(db, branchId, parsed.prefix);
    const invoiceMax = Math.max(row.last_invoice_suffix || 0, parsed.suffix);
    const tokenMax = Math.max(row.last_pickup_token || 0, tok);
    db.prepare(
      'UPDATE branch_counters SET last_invoice_suffix = ?, last_pickup_token = ?, updated_at = ? WHERE branch_id = ? AND prefix = ?',
    ).run(invoiceMax, tokenMax, Date.now(), branchId, parsed.prefix);
  });
  trx();
}

module.exports = {
  allocateCounters,
  seedCounters,
  bumpCountersFromOrderPayload,
  parseBranchScopedInvoice,
  formatShortInvoice,
};
