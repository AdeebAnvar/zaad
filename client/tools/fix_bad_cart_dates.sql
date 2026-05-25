-- Repair carts/orders seeded with TEXT created_at (breaks Drift DateTimeColumn / add-to-cart).
--
-- Run with Zaad POS closed:
--   sqlite3 "%USERPROFILE%\Documents\ZaadPOS\local\pos.sqlite" < fix_bad_cart_dates.sql
--
-- Or one-liner (PowerShell):
--   C:\sqlite\sqlite3.exe "$env:USERPROFILE\Documents\ZaadPOS\local\pos.sqlite" "DELETE FROM cart_items WHERE cart_id IN (SELECT id FROM carts WHERE typeof(created_at)='text'); DELETE FROM carts WHERE typeof(created_at)='text'; DELETE FROM orders WHERE typeof(created_at)='text';"

PRAGMA foreign_keys = ON;

BEGIN IMMEDIATE;

DELETE FROM cart_items
WHERE cart_id IN (SELECT id FROM carts WHERE typeof(created_at) = 'text');

DELETE FROM orders
WHERE cart_id IN (SELECT id FROM carts WHERE typeof(created_at) = 'text');

DELETE FROM carts WHERE typeof(created_at) = 'text';

DELETE FROM orders WHERE typeof(created_at) = 'text';

COMMIT;
