'use strict';

const express = require('express');

/**
 * @param {*} db
 */
function createHealthRouter(db) {
  const r = express.Router();

  r.get('/', async (_req, res) => {
    let sqliteOk = true;
    try {
      await db.get('SELECT 1 AS ok', []);
    } catch {
      sqliteOk = false;
    }

    res.json({
      ok: sqliteOk,
      uptimeSeconds: Math.round(process.uptime()),
      time: new Date().toISOString(),
    });
  });

  return r;
}

module.exports = { createHealthRouter };
