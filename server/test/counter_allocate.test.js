'use strict';

const { test, before } = require('node:test');
const assert = require('node:assert');
const fs = require('fs');
const os = require('os');
const path = require('path');

const { openDatabase } = require('../src/db/sqlite');
const { allocateCounters, seedCounters, bumpCountersFromOrderPayload } = require('../src/services/counterService');

let db;
let tmpDir;

before(() => {
  tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'pos-counter-test-'));
  db = openDatabase(path.join(tmpDir, 'counters.sqlite'));
});

test('allocateCounters issues monotonic invoice and token per branch', () => {
  const a = allocateCounters(db, {
    branchId: 1,
    prefix: 'KC',
    allocateInvoice: true,
    allocatePickupToken: true,
    localInvoiceMax: 10,
    localPickupTokenMax: 86,
  });
  assert.strictEqual(a.ok, true);
  assert.strictEqual(a.invoiceNumber, 'KC-1-011');
  assert.strictEqual(a.invoiceSuffix, 11);
  assert.strictEqual(a.pickupToken, 87);

  const b = allocateCounters(db, {
    branchId: 1,
    prefix: 'KC',
    allocateInvoice: true,
    allocatePickupToken: true,
  });
  assert.strictEqual(b.invoiceNumber, 'KC-1-012');
  assert.strictEqual(b.pickupToken, 88);
});

test('seedCounters only raises stored values', () => {
  seedCounters(db, { branchId: 2, prefix: 'INV', lastInvoiceSuffix: 100, lastPickupToken: 50 });
  const next = allocateCounters(db, {
    branchId: 2,
    prefix: 'INV',
    allocateInvoice: true,
    localInvoiceMax: 5,
  });
  assert.strictEqual(next.invoiceSuffix, 101);
});

test('bumpCountersFromOrderPayload tracks ORDER_CREATE snapshot', () => {
  const payload = {
    orderId: '42',
    snapshot: {
      branch_id: 1,
      invoice_number: 'KC-1-050',
      pickup_token: 120,
    },
  };
  db.prepare('INSERT OR REPLACE INTO orders (id, json, updated_at) VALUES (?, ?, ?)').run(
    '42',
    JSON.stringify(payload),
    Date.now(),
  );
  bumpCountersFromOrderPayload(db, payload);

  const next = allocateCounters(db, {
    branchId: 1,
    prefix: 'KC',
    allocateInvoice: true,
    allocatePickupToken: true,
  });
  assert.strictEqual(next.invoiceSuffix, 51);
  assert.strictEqual(next.pickupToken, 121);
});
