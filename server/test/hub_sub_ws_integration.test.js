'use strict';

/**
 * Integration: MAIN + SUB WebSocket peers, CONNECT handshake, ORDER_CREATE journal + broadcast.
 * Run: node --test test/hub_sub_ws_integration.test.js
 */

const { test, before, after } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const http = require('http');
const os = require('os');
const path = require('path');
const WebSocket = require('ws');

const { openDatabase } = require('../src/db/sqlite');
const initWebSocket = require('../src/websocket/wsServer');
const { DEVICE_MAIN } = require('../src/services/eventService');

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function wsConnect(port, deviceId, clientRole) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(`ws://127.0.0.1:${port}/ws`);
    const timer = setTimeout(() => reject(new Error('CONNECT timeout')), 8000);

    const connectEnvelope = {
      eventId: `connect-${deviceId}`,
      type: 'CONNECT',
      payload: {
        clientRole,
        appMode: clientRole === 'SUB_CLIENT' ? 'hub_sub' : 'main',
      },
      timestamp: Math.floor(Date.now() / 1000),
      deviceId,
    };

    ws.on('open', () => ws.send(JSON.stringify(connectEnvelope)));

    ws.on('message', (buf) => {
      let data;
      try {
        data = JSON.parse(buf.toString());
      } catch (_) {
        return;
      }
      if (data.type === 'CONNECT' && data.deviceId === DEVICE_MAIN) {
        clearTimeout(timer);
        resolve({ ws, welcome: data });
      }
    });

    ws.on('error', (e) => {
      clearTimeout(timer);
      reject(e);
    });
  });
}

function wsWaitForType(ws, type, timeoutMs = 8000) {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(`timeout waiting for ${type}`)), timeoutMs);

    const onMsg = (buf) => {
      let data;
      try {
        data = JSON.parse(buf.toString());
      } catch (_) {
        return;
      }
      if (data.type === type) {
        clearTimeout(timer);
        ws.off('message', onMsg);
        resolve(data);
      }
    };
    ws.on('message', onMsg);
  });
}

function countOpenSockets(wss) {
  let n = 0;
  for (const c of wss.clients) {
    if (c.readyState === WebSocket.OPEN) n += 1;
  }
  return n;
}

let server;
let wss;
let db;
let tmpDir;
let port;

before(async () => {
  tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'pos-hub-test-'));
  const dbPath = path.join(tmpDir, 'test.sqlite');
  db = openDatabase(dbPath);

  server = http.createServer((req, res) => {
    if (req.method === 'GET' && req.url === '/health') {
      const peers = [];
      for (const ws of wss.clients) {
        if (ws.readyState !== WebSocket.OPEN) continue;
        peers.push({
          deviceId: ws.__posLastDeviceId || null,
          ip: ws.__posIp || null,
          port: ws.__posPort ?? null,
        });
      }
      const body = JSON.stringify({
        ok: true,
        role: 'MAIN',
        ws: { openSockets: peers.length, peers },
      });
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(body);
      return;
    }
    res.writeHead(404);
    res.end();
  });

  await new Promise((resolve) => {
    server.listen(0, '127.0.0.1', resolve);
  });
  port = server.address().port;
  wss = initWebSocket(server, db);
});

after(async () => {
  if (!wss) return;
  for (const c of wss.clients) {
    try {
      c.close();
    } catch (_) {
      /* ignore */
    }
  }
  await new Promise((resolve) => server.close(resolve));
  try {
    db.close();
  } catch (_) {
    /* ignore */
  }
  try {
    fs.rmSync(tmpDir, { recursive: true, force: true });
  } catch (_) {
    /* ignore */
  }
});

test('CONNECT handshake for MAIN_CLIENT and SUB_CLIENT', async () => {
  const main = await wsConnect(port, 'device-main-1', 'MAIN_CLIENT');
  const sub = await wsConnect(port, 'device-sub-1', 'SUB_CLIENT');

  assert.strictEqual(main.welcome.payload.role, 'MAIN');
  assert.strictEqual(sub.welcome.payload.role, 'MAIN');
  assert.strictEqual(countOpenSockets(wss), 2);

  main.ws.close();
  sub.ws.close();
  await sleep(50);
});

test('GET /health reports two open WebSockets when MAIN + SUB connected', async () => {
  const main = await wsConnect(port, 'device-main-2', 'MAIN_CLIENT');
  const sub = await wsConnect(port, 'device-sub-2', 'SUB_CLIENT');

  const health = await new Promise((resolve, reject) => {
    http
      .get(`http://127.0.0.1:${port}/health`, (res) => {
        let raw = '';
        res.on('data', (c) => (raw += c));
        res.on('end', () => {
          try {
            resolve(JSON.parse(raw));
          } catch (e) {
            reject(e);
          }
        });
      })
      .on('error', reject);
  });

  assert.strictEqual(health.ws.openSockets, 2);
  assert.strictEqual(health.ws.peers.length, 2);

  main.ws.close();
  sub.ws.close();
  await sleep(50);
});

test('SUB ORDER_CREATE is ACKed and broadcast to MAIN listener', async () => {
  const main = await wsConnect(port, 'device-main-3', 'MAIN_CLIENT');
  const sub = await wsConnect(port, 'device-sub-3', 'SUB_CLIENT');

  const broadcastPromise = wsWaitForType(main.ws, 'ORDER_CREATE');

  const orderEvent = {
    eventId: 'order-sub-100',
    type: 'ORDER_CREATE',
    payload: {
      orderId: 'hub-order-100',
      updatedAt: Date.now(),
      snapshot: {
        invoice_number: 'INV-2-100',
        branch_id: 2,
        status: 'completed',
        final_amount: 50,
        items: [{ item_id: 1, item_name: 'Tea', quantity: 1, total: 50 }],
      },
    },
    timestamp: Math.floor(Date.now() / 1000),
    deviceId: 'device-sub-3',
  };

  sub.ws.send(JSON.stringify(orderEvent));

  const ack = await wsWaitForType(sub.ws, 'ACK');
  assert.strictEqual(ack.payload.forEventId, 'order-sub-100');
  assert.strictEqual(ack.payload.ok, true);

  const mirrored = await broadcastPromise;
  assert.strictEqual(mirrored.type, 'ORDER_CREATE');
  assert.strictEqual(mirrored.eventId, 'order-sub-100');

  const row = db.prepare('SELECT id FROM orders WHERE id = ?').get('hub-order-100');
  assert.ok(row, 'hub SQLite should persist ORDER_CREATE');

  main.ws.close();
  sub.ws.close();
  await sleep(50);
});

test('SYNC_REQUEST returns journal events after SUB posts order', async () => {
  const sub = await wsConnect(port, 'device-sub-4', 'SUB_CLIENT');

  sub.ws.send(
    JSON.stringify({
      eventId: 'order-sub-200',
      type: 'ORDER_CREATE',
      payload: {
        orderId: 'hub-order-200',
        updatedAt: Date.now(),
        snapshot: { invoice_number: 'INV-2-200', branch_id: 2, final_amount: 10, items: [] },
      },
      timestamp: Math.floor(Date.now() / 1000),
      deviceId: 'device-sub-4',
    }),
  );
  await wsWaitForType(sub.ws, 'ACK');

  sub.ws.send(
    JSON.stringify({
      eventId: 'sync-req-1',
      type: 'SYNC_REQUEST',
      payload: { lastSyncTimestamp: 0 },
      timestamp: Math.floor(Date.now() / 1000),
      deviceId: 'device-sub-4',
    }),
  );

  const syncResp = await wsWaitForType(sub.ws, 'SYNC_RESPONSE');
  assert.ok(Array.isArray(syncResp.payload.events));
  assert.ok(syncResp.payload.events.length >= 1);

  sub.ws.close();
  await sleep(50);
});
