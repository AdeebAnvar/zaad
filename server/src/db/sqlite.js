'use strict';

const sqlite3 = require('sqlite3').verbose();

/**
 * Promise helpers bound to one sqlite3 Database connection (single-file WAL hub DB).
 *
 * @param {sqlite3.Database} rawDb
 */
function createDbApi(rawDb) {
  let closed = false;
  /**
   * @param {string} sql
   * @param {unknown[]} [params]
   */
  function run(sql, params = []) {
    return new Promise((resolve, reject) => {
      rawDb.run(sql, params, function onRun(err) {
        if (err) return reject(err);
        resolve({ lastID: this.lastID, changes: this.changes });
      });
    });
  }

  /**
   * @param {string} sql
   * @param {unknown[]} [params]
   */
  function get(sql, params = []) {
    return new Promise((resolve, reject) => {
      rawDb.get(sql, params, (err, row) => {
        if (err) return reject(err);
        resolve(row);
      });
    });
  }

  /**
   * @param {string} sql
   * @param {unknown[]} [params]
   */
  function all(sql, params = []) {
    return new Promise((resolve, reject) => {
      rawDb.all(sql, params, (err, rows) => {
        if (err) return reject(err);
        resolve(rows);
      });
    });
  }

  /**
   * @param {string} sql — may contain multiple statements (schema bootstrap).
   */
  function exec(sql) {
    return new Promise((resolve, reject) => {
      rawDb.exec(sql, (err) => {
        if (err) return reject(err);
        resolve();
      });
    });
  }

  /**
   * SERIALIZABLE transaction with BEGIN IMMEDIATE / COMMIT / ROLLBACK.
   * @template T
   * @param {() => Promise<T>} work
   * @returns {Promise<T>}
   */
  async function transaction(work) {
    await run('BEGIN IMMEDIATE');
    try {
      const result = await work();
      await run('COMMIT');
      return result;
    } catch (e) {
      await run('ROLLBACK').catch(() => {});
      throw e;
    }
  }

  function close() {
    if (closed) return Promise.resolve();
    return new Promise((resolve, reject) => {
      rawDb.close((err) => {
        if (err) {
          if (err.code === 'SQLITE_MISUSE' || /Database handle is closed/i.test(String(err.message))) {
            closed = true;
            return resolve();
          }
          return reject(err);
        }
        closed = true;
        resolve();
      });
    });
  }

  async function applyPragmas() {
    await run('PRAGMA journal_mode = WAL');
    await run('PRAGMA foreign_keys = ON');
    await run('PRAGMA busy_timeout = 5000');
  }

  return {
    run,
    get,
    all,
    exec,
    transaction,
    close,
    applyPragmas,
    /** @package exposed for rare diagnostics only */
    _raw: rawDb,
  };
}

/**
 * Open SQLite at `dbPath` (directory created if missing).
 *
 * @param {{ dbPath: string }} opts
 */
function openSqlite(opts) {
  const fs = require('fs');
  const path = require('path');
  const dbPath = opts.dbPath;
  fs.mkdirSync(path.dirname(dbPath), { recursive: true });
  const rawDb = new sqlite3.Database(dbPath);
  return createDbApi(rawDb);
}

module.exports = {
  createDbApi,
  openSqlite,
};
