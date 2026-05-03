'use strict';

/**
 * Creates schema. Invoice numbers are server-owned via invoice_sequence counter.
 *
 * @param {{ applyPragmas: () => Promise<void>; exec: (sql: string) => Promise<void> }} db
 */
async function initializeDatabase(db) {
  await db.applyPragmas();

  await db.exec(`
      CREATE TABLE IF NOT EXISTS invoice_sequence (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        next_invoice_number INTEGER NOT NULL
      );

      INSERT OR IGNORE INTO invoice_sequence (id, next_invoice_number) VALUES (1, 1001);

      CREATE TABLE IF NOT EXISTS devices (
        id TEXT PRIMARY KEY,
        name TEXT,
        platform TEXT,
        app_version TEXT,
        last_seen_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        retry_count INTEGER NOT NULL DEFAULT 0
      );

      CREATE TABLE IF NOT EXISTS orders (
        id TEXT PRIMARY KEY,
        invoice_number INTEGER NOT NULL UNIQUE,
        status TEXT NOT NULL DEFAULT 'open',
        customer_id TEXT,
        device_id TEXT,
        total_cents INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        metadata TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        retry_count INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (device_id) REFERENCES devices(id)
      );

      CREATE TABLE IF NOT EXISTS order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        sku TEXT,
        name TEXT NOT NULL,
        qty REAL NOT NULL DEFAULT 1,
        unit_price_cents INTEGER NOT NULL DEFAULT 0,
        line_total_cents INTEGER NOT NULL DEFAULT 0,
        tax_cents INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        retry_count INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (order_id) REFERENCES orders(id)
      );

      CREATE TABLE IF NOT EXISTS payments (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        method TEXT NOT NULL,
        amount_cents INTEGER NOT NULL,
        reference TEXT,
        metadata TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        retry_count INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (order_id) REFERENCES orders(id)
      );

      CREATE TABLE IF NOT EXISTS sync_queue (
        id TEXT PRIMARY KEY,
        operation TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        next_attempt_at TEXT
      );

      CREATE INDEX IF NOT EXISTS idx_orders_updated_at ON orders(updated_at);
      CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
      CREATE INDEX IF NOT EXISTS idx_payments_order_id ON payments(order_id);
      CREATE INDEX IF NOT EXISTS idx_sync_queue_next ON sync_queue(is_synced, next_attempt_at, created_at);

      CREATE TABLE IF NOT EXISTS sync_meta (
        k TEXT PRIMARY KEY,
        v TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS cloud_bootstrap_snapshot (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        raw_json TEXT NOT NULL,
        updated_at TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS cloud_mirror_entities (
        resource_key TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        record_json TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT NOT NULL,
        PRIMARY KEY (resource_key, entity_id)
      );

      CREATE INDEX IF NOT EXISTS idx_cloud_mirror_resource ON cloud_mirror_entities(resource_key);

      CREATE TABLE IF NOT EXISTS cloud_mirror_push_jobs (
        id TEXT PRIMARY KEY,
        payload_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        retry_count INTEGER NOT NULL DEFAULT 0,
        last_error TEXT,
        next_attempt_at TEXT
      );

      CREATE INDEX IF NOT EXISTS idx_cloud_push_due
        ON cloud_mirror_push_jobs(is_synced, next_attempt_at, created_at);
    `);
}

module.exports = { initializeDatabase };
