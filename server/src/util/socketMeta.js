'use strict';

/**
 * @param {import('ws')} ws
 * @param {import('http').IncomingMessage} req
 */
function attachSocketMeta(ws, req) {
  const ff = req.headers['x-forwarded-for'];
  const ip = ff ? String(ff).split(',')[0].trim() : req.socket.remoteAddress || 'unknown';
  ws.__posIp = ip;
  ws.__posPort = req.socket.remotePort ?? null;
  ws.__posUserAgent = req.headers['user-agent'] || null;
  ws.__posLastDeviceId = null;
  ws.__posClientRole = null;
  ws.__posDeviceName = null;
}

/**
 * @param {import('ws')} ws
 * @param {string} [deviceId]
 * @param {string} [clientRole]
 * @param {string} [deviceName]
 */
function rememberInboundDevice(ws, deviceId, clientRole, deviceName) {
  if (typeof deviceId === 'string' && deviceId.length > 0) {
    ws.__posLastDeviceId = deviceId;
  }
  if (typeof clientRole === 'string' && clientRole.length > 0) {
    ws.__posClientRole = clientRole;
  }
  if (typeof deviceName === 'string' && deviceName.length > 0) {
    ws.__posDeviceName = deviceName;
  }
}

/**
 * @param {import('ws')} ws
 */
function clientPeer(ws) {
  return {
    role: ws.__posClientRole || 'CLIENT',
    deviceId: ws.__posLastDeviceId || null,
    deviceName: ws.__posDeviceName || null,
    ip: ws.__posIp || null,
    port: ws.__posPort ?? null,
    userAgent: ws.__posUserAgent || null,
  };
}

function mainPeer() {
  return {
    role: 'MAIN',
    deviceId: 'MAIN-HUB',
    ip: '127.0.0.1',
    note: 'LAN hub process',
  };
}

module.exports = {
  attachSocketMeta,
  rememberInboundDevice,
  clientPeer,
  mainPeer,
};
