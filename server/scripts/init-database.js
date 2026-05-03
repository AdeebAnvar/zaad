'use strict';

/**
 * Stand-alone schema initializer (runs migrations idempotently).
 * Usage: POS_DB_PATH=./data/pos.db node scripts/init-database.js
 */

require('dotenv').config({ path: require('path').join(__dirname, '..', '.env') });

const path = require('path');
const { loadConfig } = require('../src/config');
const { openDatabase } = require('../src/db/database');
const { initializeDatabase } = require('../src/db/init');

const cfg = loadConfig();
const dbPath =
  process.env.POS_SCHEMA_TARGET ||
  process.env.POS_DB_PATH ||
  process.argv[2] ||
  cfg.db_path ||
  path.join(process.cwd(), 'data', 'pos.db');

(async () => {
  console.log('[db:init] target', dbPath);
  const db = openDatabase({ dbPath });
  await initializeDatabase(db);
  await db.close();
  console.log('[db:init] done');
})().catch((e) => {
  console.error('[db:init] failed', e);
  process.exitCode = 1;
});
