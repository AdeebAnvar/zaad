'use strict';

const fs = require('fs');
const path = require('path');

/** Repo `server/logs` (same folder bootstrap already ensures exists). */
const SERVER_LOGS_DIR = path.join(__dirname, '..', '..', 'logs');

/**
 * HTTP + WebSocket visibility for LAN clients (mirror pulls, orders, health checks).
 *
 * **Support bundle from the hub PC** (machine running `server.js`):
 * - Set `POS_CLIENT_DIAGNOSTICS=1` — logs **every** HTTP route, full URL + query, request-start lines,
 *   and writes **`server/logs/pos-client-access.log`** (ISO timestamp each line).
 * - Or set only `POS_ACCESS_LOG_PATH=my-access.log` — file append without forcing full HTTP (still follows rules below).
 *
 * Other env:
 * - Default HTTP log: **`/sync/*` only** (plus ws open/close unless quiet).
 * - `POS_LOG_ALL_HTTP=1` — log every HTTP route (without needing diagnostics).
 * - `POS_LOG_ORDERS_HTTP=1` — include `/orders`.
 * - `POS_LOG_FULL_HTTP_URL=1` — include query string on HTTP lines.
 * - `POS_LOG_HTTP_START=1` — log a `[conn] → … started` line when each matching request arrives (see timeouts).
 * - `POS_QUIET_CONN_LOG=1` — no `[conn]` / ws noise on console or file (errors elsewhere still print).
 *
 * Does **not** log Authorization, cookies, or bodies (secrets / PCI).
 */

/** @type {string | undefined} */
let resolvedLogPathMemo;

function resolveAccessLogPath() {
  if (resolvedLogPathMemo !== undefined) return resolvedLogPathMemo;
  const explicit = (process.env.POS_ACCESS_LOG_PATH || '').trim();
  if (explicit) {
    resolvedLogPathMemo = path.isAbsolute(explicit) ? explicit : path.resolve(process.cwd(), explicit);
    return resolvedLogPathMemo;
  }
  if (process.env.POS_CLIENT_DIAGNOSTICS === '1' || process.env.POS_CLIENT_DIAGNOSTICS === 'true') {
    resolvedLogPathMemo = path.join(SERVER_LOGS_DIR, 'pos-client-access.log');
    return resolvedLogPathMemo;
  }
  resolvedLogPathMemo = '';
  return resolvedLogPathMemo;
}

function isQuiet() {
  return process.env.POS_QUIET_CONN_LOG === '1' || process.env.POS_QUIET_CONN_LOG === 'true';
}

function isDiagnostics() {
  return process.env.POS_CLIENT_DIAGNOSTICS === '1' || process.env.POS_CLIENT_DIAGNOSTICS === 'true';
}

function wantFullUrl() {
  return (
    isDiagnostics() ||
    process.env.POS_LOG_FULL_HTTP_URL === '1' ||
    process.env.POS_LOG_FULL_HTTP_URL === 'true'
  );
}

function wantRequestStartLine() {
  return (
    isDiagnostics() ||
    process.env.POS_LOG_HTTP_START === '1' ||
    process.env.POS_LOG_HTTP_START === 'true'
  );
}

/**
 * Write one support line to console (unless quiet) and optional access log file (ISO prefix).
 * @param {string} msg — usually starts with `[conn]` or `[ws]`
 */
function logConn(msg) {
  const filePath = resolveAccessLogPath();
  if (filePath) {
    try {
      fs.mkdirSync(path.dirname(filePath), { recursive: true });
      fs.appendFileSync(filePath, `${new Date().toISOString()} ${msg}\n`, 'utf8');
    } catch (e) {
      console.error('[conn-log] file append failed:', e instanceof Error ? e.message : String(e));
    }
  }
  if (!isQuiet()) {
    console.log(msg);
  }
}

/**
 * Client IP for HTTP or WebSocket upgrade requests.
 * @param {import('http').IncomingMessage} req
 */
function getClientIp(req) {
  const xf = req.headers['x-forwarded-for'];
  if (typeof xf === 'string' && xf.trim()) {
    return xf.split(',')[0].trim();
  }
  const s = req.socket;
  if (s && s.remoteAddress) return s.remoteAddress;
  return '';
}

/**
 * @param {import('http').IncomingMessage} req
 */
function shouldLogHttpRequest(req) {
  if (isQuiet()) return false;
  if (isDiagnostics()) return true;
  if (process.env.POS_LOG_ALL_HTTP === '1' || process.env.POS_LOG_ALL_HTTP === 'true') {
    return true;
  }
  const u = req.originalUrl || req.url || '';
  if (u.startsWith('/sync')) return true;
  if (
    (process.env.POS_LOG_ORDERS_HTTP === '1' || process.env.POS_LOG_ORDERS_HTTP === 'true') &&
    u.startsWith('/orders')
  ) {
    return true;
  }
  return false;
}

/**
 * Express middleware: logs matching HTTP requests (finish line; optional start line).
 * @returns {import('express').RequestHandler}
 */
function createHttpConnectionLogger() {
  return function httpConnectionLogger(req, res, next) {
    if (!shouldLogHttpRequest(req)) {
      return next();
    }
    const ip = getClientIp(req);
    const url = wantFullUrl() ? (req.originalUrl || req.url || '') : (req.originalUrl || req.url || '').split('?')[0];

    if (wantRequestStartLine()) {
      logConn(`[conn] → ${req.method} ${url} ${ip} started`);
    }

    const start = Date.now();
    res.on('finish', () => {
      const ms = Date.now() - start;
      const fail = res.statusCode >= 400 ? ' FAIL' : '';
      if (wantRequestStartLine()) {
        logConn(`[conn] ← ${req.method} ${url} ${ip} ${res.statusCode} ${ms}ms${fail}`);
      } else {
        logConn(`[conn] ${req.method} ${url} ${ip} ${res.statusCode} ${ms}ms${fail}`);
      }
    });

    next();
  };
}

/** Bootstrap: print where support logs go. */
function printConnectionLogHints() {
  const filePath = resolveAccessLogPath();
  if (isDiagnostics()) {
    console.log('[pos-server] POS_CLIENT_DIAGNOSTICS=1 — logging all HTTP + ws events; access file:', filePath || '(none)');
  } else if (filePath) {
    console.log('[pos-server] POS_ACCESS_LOG_PATH — writing conn/ws lines to:', filePath);
  }
}

module.exports = {
  getClientIp,
  createHttpConnectionLogger,
  shouldLogHttpRequest,
  logConn,
  resolveAccessLogPath,
  printConnectionLogHints,
  isQuiet,
  isDiagnostics,
};
