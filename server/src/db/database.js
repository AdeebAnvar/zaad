'use strict';

const { openSqlite } = require('./sqlite');

/**
 * @param {{ dbPath: string }} opts
 * @returns {ReturnType<typeof openSqlite>}
 */
function openDatabase(opts) {
  return openSqlite(opts);
}

module.exports = { openDatabase };
