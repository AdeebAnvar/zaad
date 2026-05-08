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

  wss.on('connection', (ws, req) => {
    attachSocketMeta(ws, req);
    hubLog('CONN', 'WebSocket open', {
      ip: ws.__posIp,
      port: ws.__posPort,
      path: req.url || '/ws',
      userAgent: ws.__posUserAgent,
      peerCount: wss.clients.size,
    });
    handleWS(ws, wss, db);
  });

  return wss;
}

module.exports = initWebSocket;
