'use strict';

const {
  clientPeer,
  mainPeer,
} = require('./socketMeta');

function ts() {
  return new Date().toISOString();
}

const MAX_JSON_CHARS = (() => {
  const v = Number.parseInt(process.env.POS_LOG_MAX_JSON || '', 10);
  return Number.isFinite(v) && v > 0 ? v : 524288;
})();

/**
 * Pretty JSON for logs; trims when longer than POS_LOG_MAX_JSON (default 524288 chars).
 */
function envelopeString(envelope) {
  try {
    const s =
      envelope === undefined ? '(undefined)'
      : envelope === null ? 'null'
      : typeof envelope === 'string'
        ? envelope
        : JSON.stringify(envelope, null, 2);
    if (s.length <= MAX_JSON_CHARS) return s;
    return `${s.slice(0, MAX_JSON_CHARS)}\n... [truncated ${s.length - MAX_JSON_CHARS} chars; raise POS_LOG_MAX_JSON]\n`;
  } catch (e) {
    return `[unserializable envelope: ${e && e.message ? e.message : e}]`;
  }
}

const DIV = `${'━'.repeat(72)}`;

/**
 * Legacy short log (connections, bootstrap).
 */
function hubLog(channel, message, meta) {
  const lineTs = ts();
  if (meta !== undefined && meta !== null && Object.keys(meta).length > 0) {
    // eslint-disable-next-line no-console
    console.log(`${lineTs} [POS][${channel}] ${message}`, meta);
  } else {
    // eslint-disable-next-line no-console
    console.log(`${lineTs} [POS][${channel}] ${message}`);
  }
}

/**
 * Full WebSocket request: SUB → MAIN (validated or raw parse).
 * @param {import('ws')} ws
 */
function trafficInEnvelope(ws, envelope, extras = {}) {
  const payloadRole =
    envelope &&
    envelope.payload &&
    typeof envelope.payload === 'object' &&
    typeof envelope.payload.clientRole === 'string'
      ? envelope.payload.clientRole
      : null;
  const inferredRole = payloadRole || ws.__posClientRole || 'CLIENT';
  const from =
    envelope && typeof envelope.deviceId === 'string' && envelope.deviceId
      ? {
          role: inferredRole,
          deviceId: envelope.deviceId,
          ip: ws.__posIp || null,
          port: ws.__posPort ?? null,
          userAgent: ws.__posUserAgent || null,
        }
      : clientPeer(ws);

  const to = mainPeer();

  // eslint-disable-next-line no-console
  console.log(
    `\n${DIV}\n${ts()} [POS][TRAFFIC] WEBSOCKET CLIENT → MAIN wire ${extras.label || envelope?.type || 'message'}\n` +
      `from: ${JSON.stringify(from, null, 2)}\n` +
      `to:   ${JSON.stringify(to, null, 2)}` +
      (extras.note ? `\nnote: ${extras.note}` : '') +
      `\n--- body (parsed envelope) ---\n${envelopeString(envelope)}\n${DIV}\n`,
  );
}

/**
 * Broken JSON or non-object on the wire (still logs raw).
 * @param {import('ws')} ws
 */
function trafficInMalformed(ws, raw, err, responsePreview = null) {
  const from = clientPeer(ws);
  const to = mainPeer();

  let rawBlock = envelopeString(raw.length > MAX_JSON_CHARS ? `${raw.slice(0, MAX_JSON_CHARS)}\n...[raw truncated]` : raw);

  let outPreview = '';
  if (responsePreview != null) {
    outPreview = `\n--- response sent to SUB (compact) ---\n${envelopeString(responsePreview)}\n`;
  }

  // eslint-disable-next-line no-console
  console.log(
    `\n${DIV}\n${ts()} [POS][TRAFFIC] WEBSOCKET CLIENT → MAIN parse error\n` +
      `from: ${JSON.stringify(from, null, 2)}\n` +
      `to:   ${JSON.stringify(to, null, 2)}\n` +
      `error: ${String(err && err.message ? err.message : err)}\n` +
      `--- raw body ---\n${rawBlock}\n` +
      outPreview +
      `${DIV}\n`,
  );
}

/**
 * MAIN → single SUB socket.
 * @param {import('ws')} ws
 */
function trafficOutUnicast(ws, envelope, extras = {}) {
  const from = mainPeer();
  const to = clientPeer(ws);

  // eslint-disable-next-line no-console
  console.log(
    `\n${DIV}\n${ts()} [POS][TRAFFIC] WEBSOCKET MAIN → CLIENT ${extras.label || envelope?.type || 'response'}\n` +
      `from: ${JSON.stringify(from, null, 2)}\n` +
      `to:   ${JSON.stringify(to, null, 2)}` +
      (extras.note ? `\nnote: ${extras.note}` : '') +
      `\n--- body ---\n${envelopeString(envelope)}\n${DIV}\n`,
  );
}

/**
 * MAIN broadcasts to peers (excluding originator socket).
 */
function trafficOutBroadcast(originWs, envelope, recipients) {
  const from = mainPeer();
  const to = {
    mode: 'BROADCAST_EXCEPT_ORIGIN_CLIENT',
    originSentFrom: clientPeer(originWs),
    recipients,
    recipientCount: recipients.length,
  };

  // eslint-disable-next-line no-console
  console.log(
    `\n${DIV}\n${ts()} [POS][TRAFFIC] WEBSOCKET MAIN → CLIENT(s) broadcast\n` +
      `from: ${JSON.stringify(from, null, 2)}\n` +
      `to:   ${JSON.stringify(to, null, 2)}\n` +
      `--- broadcast body ---\n${envelopeString(envelope)}\n${DIV}\n`,
  );
}

/**
 * HTTP request/response snapshot (currently /health and 404s).
 */
function trafficHttp(peerIp, requestLine, status, responseBody = null) {
  const block = {
    request: requestLine,
    peerIp,
    httpStatus: status,
    ...(responseBody != null ? { responseBody } : {}),
  };
  // eslint-disable-next-line no-console
  console.log(
    `\n${DIV}\n${ts()} [POS][TRAFFIC] HTTP\n--- meta ---\n${envelopeString(block)}\n${DIV}\n`,
  );
}

module.exports = {
  hubLog,
  ts,
  envelopeString,
  trafficInEnvelope,
  trafficInMalformed,
  trafficOutUnicast,
  trafficOutBroadcast,
  trafficHttp,
};
