'use strict';

const WebSocket = require('ws');
const wsConfig = require('../config/wsConfig');
const { hubLog } = require('../util/hubLog');
const { attachSocketMeta } = require('../util/socketMeta');
const handleWS = require('./wsHandler');

/**
 * @param {import('http').Server} server
 * @param {import('better-sqlite3').Database} db
 */
function initWebSocket(server, db) {
  const wss = new WebSocket.Server({
    server,
    path: '/ws',
    maxPayload: wsConfig.maxPayloadBytes,
    clientTracking: true,
  });

  // Keep idle LAN sockets alive and detect dead peers.
  // Without this, Wi-Fi/NAT middleboxes may silently drop inactive SUB sockets.
  const heartbeatTimer = setInterval(() => {
    for (const ws of wss.clients) {
      if (ws.isAlive === false) {
        hubLog('CONN', 'WebSocket heartbeat timeout', {
          ip: ws.__posIp,
          port: ws.__posPort,
          lastDeviceId: ws.__posLastDeviceId,
          deviceName: ws.__posDeviceName,
        });
        ws.terminate();
        continue;
      }
      ws.isAlive = false;
      try {
        ws.ping();
      } catch (_) {
        ws.terminate();
      }
    }
  }, wsConfig.heartbeatMs);

  wss.on('connection', (ws, req) => {
    attachSocketMeta(ws, req);
    ws.isAlive = true;
    ws.on('pong', () => {
      ws.isAlive = true;
    });
    hubLog('CONN', 'WebSocket open', {
      ip: ws.__posIp,
      port: ws.__posPort,
      path: req.url || '/ws',
      userAgent: ws.__posUserAgent,
      peerCount: wss.clients.size,
    });
    handleWS(ws, wss, db);
  });

  wss.on('close', () => {
    clearInterval(heartbeatTimer);
  });

  return wss;
}

module.exports = initWebSocket;
