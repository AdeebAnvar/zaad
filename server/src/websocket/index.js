'use strict';

const { WebSocket, WebSocketServer } = require('ws');
const { getClientIp, logConn, isQuiet } = require('../middleware/connectionLog');

/**
 * @typedef {{ broadcast: (msg: unknown) => void; clientCount: () => number }} WebSocketHub
 */

/**
 * @param {import('http').Server} httpServer
 * @param {{ path?: string; verifyClient?: ((info: { req: import('http').IncomingMessage }) => boolean) | undefined }} [opts]
 * @returns {WebSocketHub}
 */
function createWebSocketHub(httpServer, opts = {}) {
  const path = opts.path || '/ws';
  /** @type {ConstructorParameters<typeof WebSocketServer>[0]} */
  const wssOpts = { server: httpServer, path };
  if (typeof opts.verifyClient === 'function') {
    wssOpts.verifyClient = opts.verifyClient;
  }
  const wss = new WebSocketServer(wssOpts);

  wss.on('connection', (ws, req) => {
    const ip = getClientIp(req);
    if (!isQuiet()) {
      const ua = typeof req.headers['user-agent'] === 'string' ? req.headers['user-agent'].slice(0, 120) : '';
      logConn(`[conn] ws open ${ip} clients=${wss.clients.size}${ua ? ` ua=${JSON.stringify(ua)}` : ''}`);
    }
    ws.send(
      JSON.stringify({
        type: 'HELLO',
        payload: { message: 'connected', path },
        ts: new Date().toISOString(),
      })
    );
    ws.on('close', (code, reason) => {
      if (!isQuiet()) {
        const r = Buffer.isBuffer(reason) ? reason.toString() : String(reason || '');
        logConn(`[conn] ws close ${ip} code=${code}${r ? ` reason=${r.slice(0, 80)}` : ''}`);
      }
    });
    ws.on('error', (err) => {
      console.warn('[ws] client error', ip, err.message);
    });
  });

  return {
    broadcast(msg) {
      const envelope =
        typeof msg === 'object' && msg !== null
          ? /** @type {Record<string, unknown>} */ (msg)
          : { payload: msg };
      const data = JSON.stringify({ ...envelope, ts: new Date().toISOString() });
      for (const client of wss.clients) {
        if (client.readyState === WebSocket.OPEN) {
          client.send(data);
        }
      }
    },
    clientCount() {
      return wss.clients.size;
    },
  };
}

module.exports = { createWebSocketHub };
