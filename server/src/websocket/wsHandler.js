'use strict';

const { handleEnvelope, send } = require('../services/eventService');
const { hubLog, trafficInEnvelope, trafficInMalformed, trafficOutUnicast } = require('../util/hubLog');
const { rememberInboundDevice } = require('../util/socketMeta');

/**
 * @param {import('ws')} ws
 * @param {import('ws').WebSocketServer} wss
 * @param {import('better-sqlite3').Database} db
 */
function handleWS(ws, wss, db) {
  ws.on('message', (buf) => {
    const raw = typeof buf === 'string' ? buf : buf.toString('utf8');
    let data;
    try {
      data = JSON.parse(raw);
    } catch (e) {
      const errBody = { error: 'Invalid message' };
      trafficInMalformed(ws, raw, e, errBody);
      send(ws, errBody, { skipTrafficLog: true });
      return;
    }

    if (data !== null && typeof data === 'object') {
      const payload = data.payload && typeof data.payload === 'object' ? data.payload : {};
      rememberInboundDevice(
        ws,
        typeof data.deviceId === 'string' ? data.deviceId : '',
        typeof payload.clientRole === 'string' ? payload.clientRole : '',
      );
    }

    trafficInEnvelope(ws, data, { label: `recv ${typeof data?.type === 'string' ? data.type : '(non-object)'}` });

    try {
      handleEnvelope(db, ws, wss, data, raw);
    } catch (err) {
      const body = {
        error: 'Server error',
        detail: String(err && err.message ? err.message : err),
      };
      trafficOutUnicast(ws, body, { label: 'uncaught handler error', note: 'before connection closed' });
      send(ws, body, { skipTrafficLog: true });
    }
  });

  ws.on('close', (code, reason) => {
    hubLog('CONN', 'WebSocket closed', {
      peer: { ip: ws.__posIp, port: ws.__posPort, lastDeviceId: ws.__posLastDeviceId },
      code,
      reason: reason && reason.toString(),
    });
  });
}

module.exports = handleWS;
