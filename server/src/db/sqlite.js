'use strict';

const fs = require('fs');
const path = require('path');
const Database = require('better-sqlite3');

let lockFd = null;
let lockFilePath = null;

/** @returns {boolean} true if lock file removed or missing (safe to create) */
function removeStaleMainLock(lockPath) {
  try {
    if (!fs.existsSync(lockPath)) return true;
    let pid = NaN;
    try {
      const raw = fs.readFileSync(lockPath, 'utf8').trim();
      pid = Number.parseInt(String(raw).split(/\s/)[0], 10);
    } catch (_) {
      /* empty or unreadable */
    }
    if (!Number.isFinite(pid) || pid <= 0) {
      fs.unlinkSync(lockPath);
      return true;
    }
    if (pid === process.pid) {
      fs.unlinkSync(lockPath);
      return true;
    }
    try {
      process.kill(pid, 0);
      return false;
    } catch (e) {
      const code = e && e.code;
      if (code === 'EPERM') return false;
      try {
        fs.unlinkSync(lockPath);
      } catch (_) {
        /* ignore */
      }
      return true;
    }
  } catch (_) {
    try {
      fs.unlinkSync(lockPath);
    } catch (_2) {
      /* ignore */
    }
    return true;
  }
}

/**
 * Prevents multiple MAIN hubs on one machine (spec: single authoritative server).
 * Stale `main.lock` from a crashed MAIN is removed after checking the stored PID.
 */
function acquireMainLock(dataDir) {
  const lockPath = path.join(dataDir, 'main.lock');
  try {
    lockFd = fs.openSync(lockPath, 'wx');
    fs.writeSync(lockFd, `${process.pid}\n`);
    lockFilePath = lockPath;
    return;
  } catch (_) {
    /* continue */
  }

  if (!removeStaleMainLock(lockPath)) {
    // eslint-disable-next-line no-console
    console.error(
      `[POS MAIN] Cannot start: another MAIN is running (lock: ${lockPath}). Stop that process first.`,
    );
    process.exit(1);
    return;
  }

  try {
    lockFd = fs.openSync(lockPath, 'wx');
    fs.writeSync(lockFd, `${process.pid}\n`);
    lockFilePath = lockPath;
  } catch (e) {
    // eslint-disable-next-line no-console
    console.error(
      `[POS MAIN] Cannot create lock at ${lockPath}: ${e && e.message ? e.message : e}`,
    );
    process.exit(1);
  }
}

function releaseMainLock() {
  try {
    if (lockFd != null) fs.closeSync(lockFd);
    lockFd = null;
    if (lockFilePath && fs.existsSync(lockFilePath)) fs.unlinkSync(lockFilePath);
  } catch (_) {
    /* ignore */
  }
  lockFilePath = null;
}

function migrate(db) {
  db.exec(`
    PRAGMA journal_mode = WAL;
    PRAGMA synchronous = FULL;

    CREATE TABLE IF NOT EXISTS processed_events (
      event_id TEXT PRIMARY KEY,
      processed_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS inbox (
      id TEXT PRIMARY KEY,
      event_id TEXT NOT NULL UNIQUE,
      type TEXT NOT NULL,
      raw_envelope TEXT NOT NULL,
      received_at INTEGER NOT NULL,
      applied INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS event_journal (
      seq INTEGER PRIMARY KEY AUTOINCREMENT,
      event_id TEXT NOT NULL UNIQUE,
      type TEXT NOT NULL,
      payload TEXT NOT NULL,
      envelope TEXT NOT NULL,
      effective_ms INTEGER NOT NULL,
      device_id TEXT NOT NULL
    );

    CREATE INDEX IF NOT EXISTS idx_journal_effective_ms ON event_journal(effective_ms);

    CREATE TABLE IF NOT EXISTS categories (
      id TEXT PRIMARY KEY,
      json TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS items (
      id TEXT PRIMARY KEY,
      json TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS orders (
      id TEXT PRIMARY KEY,
      json TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS kot_entries (
      id TEXT PRIMARY KEY,
      json TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS payments (
      id TEXT PRIMARY KEY,
      json TEXT NOT NULL,
      updated_at INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS branch_counters (
      branch_id INTEGER NOT NULL,
      prefix TEXT NOT NULL,
      last_invoice_suffix INTEGER NOT NULL DEFAULT 0,
      last_pickup_token INTEGER NOT NULL DEFAULT 0,
      updated_at INTEGER NOT NULL,
      PRIMARY KEY (branch_id, prefix)
    );
  `);
}

function openDatabase(filePath) {
  const dir = path.dirname(filePath);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  const db = new Database(filePath);
  db.pragma('foreign_keys = ON');
  migrate(db);
  return db;
}

module.exports = {
  openDatabase,
  acquireMainLock,
  releaseMainLock,
};
