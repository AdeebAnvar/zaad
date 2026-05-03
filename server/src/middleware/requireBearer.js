'use strict';

const crypto = require('crypto');

/** @typedef {{ required_token?: string; disabled?: boolean }} AuthOpts */

/**
 * Bearer token middleware (timing-safe equality when lengths match).
 * @returns {import('express').RequestHandler}
 */
function createRequireBearer(auth) {
  const secretRaw = typeof auth.required_token === 'string' ? auth.required_token.trim() : '';
  const disabled = Boolean(auth.disabled) || secretRaw === '';

  return function requireBearer(req, res, next) {
    if (disabled || req.method === 'OPTIONS') return next();

    const h = typeof req.headers.authorization === 'string' ? req.headers.authorization.trim() : '';
    const tok = /^Bearer\s+(.+)$/i.exec(h);
    const provided = tok ? tok[1].trim() : '';

    const a = Buffer.from(secretRaw);
    const b = Buffer.from(provided);
    let ok = false;
    try {
      ok = a.length === b.length && a.length > 0 && crypto.timingSafeEqual(a, b);
    } catch (_) {
      ok = false;
    }

    if (!ok) return res.status(401).json({ error: 'unauthorized' });
    next();
  };
}

/**
 * Validates WebSocket handshake URL `GET /ws?token=`. [rawUrl] is typically `req.url`.
 */
function websocketTokenOk(auth, rawUrl) {
  const secretRaw = typeof auth.required_token === 'string' ? auth.required_token.trim() : '';
  if (Boolean(auth.disabled) || secretRaw === '') return true;
  try {
    const u = typeof rawUrl === 'string' ? rawUrl : '';
    const qIdx = u.indexOf('?');
    const qStr = qIdx >= 0 ? u.slice(qIdx + 1) : '';
    const params = new URLSearchParams(qStr);
    const provided = typeof params.get('token') === 'string' ? String(params.get('token')).trim() : '';

    const a = Buffer.from(secretRaw);
    const b = Buffer.from(provided);
    if (a.length !== b.length || a.length === 0) return false;
    return crypto.timingSafeEqual(a, b);
  } catch (_) {
    return false;
  }
}

module.exports = { createRequireBearer, websocketTokenOk };
