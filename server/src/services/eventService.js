'use strict';

const { randomUUID } = require('crypto');
const { hubLog, trafficOutUnicast, trafficOutBroadcast } = require('../util/hubLog');

const DEVICE_MAIN = 'MAIN-HUB';

function nowMs() {
  return Date.now();
}

function envelopeTimestampSec(data) {
  return typeof data.timestamp === 'number' ? data.timestamp : Math.floor(nowMs() / 1000);
}

function effectiveMs(data, payload) {
  const p = payload && typeof payload === 'object' ? payload : {};
  if (typeof p.updatedAt === 'number') return p.updatedAt;
  return envelopeTimestampSec(data) * 1000;
}

/**
 * @param {import('ws')} ws
 * @param {object} obj JSON-serializable
 * @param {{ skipTrafficLog?: boolean; trafficExtras?: Record<string, string> }} [opts]
 */
function send(ws, obj, opts = {}) {
  if (!opts.skipTrafficLog) {
    trafficOutUnicast(ws, obj, opts.trafficExtras || {});
  }
  try {
    if (ws.readyState === ws.OPEN) ws.send(JSON.stringify(obj));
    else hubLog('OUT_WARN', 'socket not OPEN; frame not sent', { type: obj && obj.type, eventId: obj && obj.eventId });
  } catch (e) {
    hubLog('OUT_ERR', 'send threw', {
      error: String(e && e.message ? e.message : e),
      type: obj && obj.type,
      eventId: obj && obj.eventId,
    });
  }
}

function broadcast(wss, obj, originWs) {
  const raw = JSON.stringify(obj);
  const recipientRows = [];

  for (const client of wss.clients) {
    if (client === originWs) continue;
    if (client.readyState !== client.OPEN) continue;

    recipientRows.push({
      deviceId: client.__posLastDeviceId || null,
      ip: client.__posIp || null,
      port: client.__posPort ?? null,
      userAgent: client.__posUserAgent || null,
    });

    try {
      client.send(raw);
    } catch (_) {
      /* ignore dead sockets */
    }
  }

  trafficOutBroadcast(originWs, obj, recipientRows);
}

function ackEnvelope(forEventId, ok, extras = {}) {
  return {
    eventId: randomUUID(),
    type: 'ACK',
    payload: Object.assign({ forEventId, ok }, extras),
    timestamp: Math.floor(nowMs() / 1000),
    deviceId: DEVICE_MAIN,
  };
}

function connectWelcome() {
  return {
    eventId: randomUUID(),
    type: 'CONNECT',
    payload: {
      role: 'MAIN',
      serverTimeMs: nowMs(),
    },
    timestamp: Math.floor(nowMs() / 1000),
    deviceId: DEVICE_MAIN,
  };
}

function validateInbound(data) {
  if (!data || typeof data !== 'object') return { ok: false, error: 'Invalid JSON object' };
  if (typeof data.eventId !== 'string' || !data.eventId) return { ok: false, error: 'Missing eventId' };
  if (typeof data.type !== 'string' || !data.type) return { ok: false, error: 'Missing type' };
  if (typeof data.payload !== 'object' || data.payload === null) return { ok: false, error: 'Missing payload' };
  if (typeof data.timestamp !== 'number') return { ok: false, error: 'Missing timestamp' };
  if (typeof data.deviceId !== 'string' || !data.deviceId) return { ok: false, error: 'Missing deviceId' };
  return { ok: true };
}

function applyDomainLww(db, table, id, jsonObj, updatedAt) {
  if (!id) return;
  const row = db.prepare(`SELECT updated_at FROM ${table} WHERE id = ?`).get(id);
  if (row && row.updated_at >= updatedAt) return;
  db.prepare(`INSERT OR REPLACE INTO ${table} (id, json, updated_at) VALUES (?, ?, ?)`).run(
    id,
    JSON.stringify(jsonObj),
    updatedAt,
  );
}

function applyEventToDomain(db, type, payload, effMs) {
  const p = payload && typeof payload === 'object' ? payload : {};
  switch (type) {
    case 'ITEM_UPSERT': {
      const id = p.id || p.uuid;
      if (id) applyDomainLww(db, 'items', String(id), p, effMs);
      break;
    }
    case 'CATEGORY_UPSERT': {
      const id = p.id || p.uuid || p.categorySlug;
      if (id) applyDomainLww(db, 'categories', String(id), p, effMs);
      break;
    }
    case 'ORDER_CREATE':
    case 'ORDER_UPDATE': {
      const id = p.orderId || p.id || p.serverOrderId;
      if (id) applyDomainLww(db, 'orders', String(id), p, effMs);
      break;
    }
    case 'KOT_CREATE': {
      const id = p.kotId || p.id || randomUUID();
      applyDomainLww(db, 'kot_entries', String(id), p, effMs);
      break;
    }
    case 'PAYMENT_CREATE': {
      const id = p.paymentId || p.id || randomUUID();
      applyDomainLww(db, 'payments', String(id), p, effMs);
      break;
    }
    case 'DELETE': {
      const entity = p.entity;
      const id = p.id;
      if (!entity || !id) break;
      const table =
        entity === 'order' || entity === 'orders'
          ? 'orders'
          : entity === 'item' || entity === 'items'
            ? 'items'
            : entity === 'category' || entity === 'categories'
              ? 'categories'
              : entity === 'payment' || entity === 'payments'
                ? 'payments'
                : entity === 'kot' || entity === 'kots'
                  ? 'kot_entries'
                  : null;
      if (!table) break;
      db.prepare(`DELETE FROM ${table} WHERE id = ?`).run(String(id));
      break;
    }
    default:
      break;
  }
}

function recordInbox(db, data, rawStr) {
  const id = randomUUID();
  const ins = db.prepare(
    `INSERT INTO inbox (id, event_id, type, raw_envelope, received_at, applied) VALUES (?,?,?,?,?,1)`,
  );
  ins.run(id, data.eventId, data.type, rawStr, nowMs());
}

function appendJournal(db, data, envelopeStr, effectiveMs_) {
  const ins = db.prepare(
    `INSERT INTO event_journal (event_id, type, payload, envelope, effective_ms, device_id) VALUES (?,?,?,?,?,?)`,
  );
  ins.run(data.eventId, data.type, JSON.stringify(data.payload), envelopeStr, effectiveMs_, data.deviceId);
}

function buildSyncResponse(db, lastSyncMs) {
  const lm = typeof lastSyncMs === 'number' ? lastSyncMs : 0;
  const rows = db
    .prepare(
      `SELECT envelope, effective_ms FROM event_journal WHERE effective_ms > ? ORDER BY effective_ms ASC, seq ASC`,
    )
    .all(lm);
  /** @type {{ effectiveMs: number, envelope: object }[]} */
  const events = [];
  let batchMax = lm;
  for (const r of rows) {
    try {
      const envelope = JSON.parse(r.envelope);
      const eff = typeof r.effective_ms === 'number' ? r.effective_ms : lm;
      if (eff > batchMax) batchMax = eff;
      events.push({ effectiveMs: eff, envelope });
    } catch (_) {
      /* skip corrupt row */
    }
  }
  // Critical: watermark must reflect only rows returned — global MAX(journal)
  // skips older orders forever after partial apply / reorder.
  return {
    events,
    syncTimestamp: batchMax,
  };
}

/**
 * @param {import('better-sqlite3').Database} db
 * @param {import('ws')} ws
 * @param {import('ws').WebSocketServer} wss
 * @param {object} data parsed envelope
 * @param {string} rawStr original string for journaling
 */
function handleEnvelope(db, ws, wss, data, rawStr) {
  const v = validateInbound(data);
  if (!v.ok) {
    send(ws, { error: v.error });
    return;
  }

  const eff = effectiveMs(data, data.payload);
  data.__effectiveMs = eff;

  if (data.type === 'CONNECT') {
    const welcome = connectWelcome();
    send(ws, welcome, {
      trafficExtras: { note: `handshake answering CONNECT ${data.eventId}` },
    });
    // Tell other peers (MAIN Flutter listener) that a terminal joined so it can push COMPANY_SNAPSHOT.
    const connectBroadcast = JSON.parse(rawStr);
    broadcast(wss, connectBroadcast, ws);
    return;
  }

  if (data.type === 'SYNC_REQUEST') {
    const last = data.payload.lastSyncTimestamp;
    const pack = buildSyncResponse(db, typeof last === 'number' ? last : 0);
    const resp = {
      eventId: randomUUID(),
      type: 'SYNC_RESPONSE',
      payload: pack,
      timestamp: Math.floor(nowMs() / 1000),
      deviceId: DEVICE_MAIN,
    };
    send(ws, resp, {
      trafficExtras: {
        note: `lastSync=${typeof last === 'number' ? last : 0} eventsReturned=${pack.events.length}`,
      },
    });
    return;
  }

  const trx = db.transaction(() => {
    const ins = db.prepare(`INSERT OR IGNORE INTO processed_events (event_id, processed_at) VALUES (?, ?)`);
    const info = ins.run(data.eventId, nowMs());
    if (info.changes === 0) {
      return { duplicate: true };
    }

    applyEventToDomain(db, data.type, data.payload, eff);

    recordInbox(db, data, rawStr);

    if (data.type !== 'ACK') {
      appendJournal(db, data, rawStr, eff);
    }
    return { duplicate: false };
  });

  let out;
  try {
    out = trx();
  } catch (e) {
    hubLog('EVT_ERR', `transaction failed for ${data.type}`, { eventId: data.eventId, error: String(e && e.message ? e.message : e) });
    send(ws, ackEnvelope(data.eventId, false, { error: String(e && e.message ? e.message : e) }), {
      trafficExtras: { note: 'ACK nack: DB transaction failed' },
    });
    return;
  }

  if (out && out.duplicate) {
    send(ws, ackEnvelope(data.eventId, true, { duplicate: true }), {
      trafficExtras: { note: 'duplicate eventId (idempotent)' },
    });
    return;
  }

  send(ws, ackEnvelope(data.eventId, true), {
    trafficExtras: {
      note: `persist OK type=${data.type} effectiveMs=${eff}`,
    },
  });

  const broadcastEnvelope = JSON.parse(rawStr);
  // Echo to other SUBs only so the originator is not double-applying (outbox + broadcast).
  broadcast(wss, broadcastEnvelope, ws);
}

module.exports = {
  handleEnvelope,
  send,
  broadcast,
  ackEnvelope,
  connectWelcome,
  validateInbound,
  DEVICE_MAIN,
};
