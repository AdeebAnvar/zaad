'use strict';

function nowIso() {
  return new Date().toISOString();
}

/**
 * Inserts outbound sync payload (typically called inside orders transaction).
 *
 * @param {*} db
 * @param {{ id: string; operation: string; entity_type: string; entity_id?: string | null; payload: string }} job
 */
async function enqueueSync(db, job) {
  const t = nowIso();
  await db.run(
    `INSERT INTO sync_queue (id, operation, entity_type, entity_id, payload, created_at, updated_at,
       is_synced, retry_count, last_error, next_attempt_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, 0, 0, NULL, ?)`,
    [job.id, job.operation, job.entity_type, job.entity_id ?? null, job.payload, t, t, t],
  );
}

/**
 * @param {*} db
 * @param {{ limit: number }} opts
 */
async function fetchDueJobs(db, opts) {
  const t = nowIso();
  return db.all(
    `SELECT * FROM sync_queue
       WHERE is_synced = 0 AND (next_attempt_at IS NULL OR next_attempt_at <= ?)
       ORDER BY created_at ASC
       LIMIT ?`,
    [t, opts.limit],
  );
}

/**
 * @param {*} db
 * @param {string} id
 */
async function markSynced(db, id) {
  const t = nowIso();
  await db.run(
    'UPDATE sync_queue SET is_synced = 1, updated_at = ?, last_error = NULL, next_attempt_at = NULL WHERE id = ?',
    [t, id],
  );
}

/**
 * @param {*} db
 * @param {string} id
 * @param {{ retryCount: number; error: string; nextAttemptAt: string }} err
 */
async function markFailure(db, id, err) {
  const t = nowIso();
  await db.run(
    `UPDATE sync_queue SET retry_count = ?, last_error = ?, next_attempt_at = ?, updated_at = ?
     WHERE id = ?`,
    [err.retryCount, err.error, err.nextAttemptAt, t, id],
  );
}

function computeBackoffMs(retryCount) {
  const base = 1000;
  const max = 5 * 60 * 1000;
  const exp = Math.min(12, Math.max(0, retryCount));
  return Math.min(max, base * 2 ** exp);
}

module.exports = {
  enqueueSync,
  fetchDueJobs,
  markSynced,
  markFailure,
  computeBackoffMs,
  nowIso,
};
