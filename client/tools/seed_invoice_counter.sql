-- Resume local invoice numbering after wiping ZaadPOS data.
--
-- How the app picks the next invoice (see order_repository_impl.dart):
--   next_suffix = max(orders, carts for PREFIX + branch_id) + 1
--   format: PREFIX-branchId-###  (e.g. INV-1-245)
--
-- This script inserts ONE sentinel cart at your LAST admin invoice
-- so the NEXT new sale becomes PREFIX-branchId-(suffix+1).
--
-- IMPORTANT: created_at must be INTEGER milliseconds (Drift DateTimeColumn).
-- Never use TEXT dates like '2000-01-01 00:00:00' or datetime('now') strings.
--
-- BEFORE RUNNING:
--   1. Close Zaad POS completely (no app using the DB).
--   2. Edit the invoice string and branch_id in the INSERT below.
--   3. Confirm PREFIX matches branches.prefix_inv (or INV if empty).
--
-- DB path (Windows): %USERPROFILE%\Documents\ZaadPOS\local\pos.sqlite
--
-- Run (if sqlite3 is installed):
--   sqlite3 "%USERPROFILE%\Documents\ZaadPOS\local\pos.sqlite" < seed_invoice_counter.sql
--
-- Or open the DB in DB Browser for SQLite and execute this file.

-- ═══════════════════════════════════════════════════════════════════
-- CONFIG — edit these only
-- ═══════════════════════════════════════════════════════════════════

-- Full last invoice already used in admin, e.g. INV-1-245
-- REPLACE 'INV-1-245' and branch id 1 in the INSERT statement.

-- ═══════════════════════════════════════════════════════════════════

PRAGMA foreign_keys = ON;

BEGIN IMMEDIATE;

-- Optional: inspect branch invoice prefix
-- SELECT id, name, prefix_inv FROM branches;

INSERT INTO carts (invoice_number, created_at, order_type, branch_id)
VALUES (
  'INV-1-245',
  (CAST(strftime('%s', 'now') AS INTEGER) * 1000),
  'take_away',
  1
);

COMMIT;

-- Verify: next app invoice should be INV-1-246 for branch 1 (if prefix is INV)
-- SELECT invoice_number FROM carts WHERE branch_id = 1 ORDER BY id DESC LIMIT 5;
-- SELECT invoice_number, status, final_amount FROM orders WHERE branch_id = 1 ORDER BY id DESC LIMIT 5;
