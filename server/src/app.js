'use strict';

require('dotenv').config();

const fs = require('fs');
const path = require('path');
const http = require('http');
const WebSocket = require('ws');
const wsCfg = require('./config/wsConfig');
const initWebSocket = require('./websocket/wsServer');
const { openDatabase, acquireMainLock, releaseMainLock } = require('./db/sqlite');
const { trafficHttp } = require('./util/hubLog');

const DATA_DIR = path.join(__dirname, '..', 'data');
if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });

acquireMainLock(DATA_DIR);

const dbPath = process.env.POS_SQLITE_PATH || path.join(DATA_DIR, 'main.sqlite');
const db = openDatabase(dbPath);

/** @type {{ wss: import('ws').WebSocketServer | null }} */
const hub = { wss: null };

/**
 * OPEN WebSocket peers (every connected Flutter/Node client on /ws).
 * @param {import('ws').WebSocketServer | null} wss
 */
function websocketClientsSnapshot(wss) {
  if (!wss) return null;
  const peers = [];
  const maxPeers = 64;
  let openSockets = 0;
  for (const ws of wss.clients) {
    if (ws.readyState !== WebSocket.OPEN) continue;
    openSockets += 1;
    if (peers.length < maxPeers) {
      peers.push({
        deviceId: ws.__posLastDeviceId || null,
        ip: ws.__posIp || null,
        port: ws.__posPort ?? null,
      });
    }
  }
  return { openSockets, peers };
}

const server = http.createServer((req, res) => {
  const ip = req.socket.remoteAddress || 'unknown';

  if (req.method === 'GET' && req.url === '/health') {
    const body = { ok: true, role: 'MAIN', sqlite: dbPath };
    const snap = websocketClientsSnapshot(hub.wss);
    if (snap) {
      body.ws = snap;
    }
    trafficHttp(ip, { method: 'GET', path: '/health', urlRaw: req.url }, 200, body);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify(body));
    return;
  }

  trafficHttp(ip, { method: req.method || '?', urlRaw: req.url || '/' }, 404, { error: 'not_found' });
  res.writeHead(404);
  res.end();
});

hub.wss = initWebSocket(server, db);

server.listen(wsCfg.port, wsCfg.host, () => {
  // eslint-disable-next-line no-console
  console.log(`[POS MAIN] HTTP health http://${wsCfg.host}:${wsCfg.port}/health`);
  // eslint-disable-next-line no-console
  console.log(`[POS MAIN] WebSocket ws://${wsCfg.host}:${wsCfg.port}/ws`);
  // eslint-disable-next-line no-console
  console.log(`[POS MAIN] SQLite ${dbPath}`);
});

function shutdown() {
  releaseMainLock();
  try {
    db.close();
  } catch (_) {
    /* ignore */
  }
  process.exit(0);
}

process.on('SIGINT', shutdown);
process.on('SIGTERM', shutdown);
process.on('exit', () => releaseMainLock());
