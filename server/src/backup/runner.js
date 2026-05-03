'use strict';

const fs = require('fs');
const path = require('path');
const cron = require('node-cron');

/**
 * Copies SQLite WAL files require checkpoint - WAL mode may need restarting copy.
 * Copies main db file atomically-ish for snapshot at rest.
 * @param {string} sourceDbPath
 * @param {string} backupsDir
 * @returns {string} written file path
 */
function copyDatabaseBackup(sourceDbPath, backupsDir) {
  fs.mkdirSync(backupsDir, { recursive: true });
  const stamp = new Date().toISOString().replace(/[:.]/g, '-');
  const dest = path.join(backupsDir, `pos-${stamp}.db`);

  fs.copyFileSync(sourceDbPath, dest);
  return dest;
}

/**
 * @param {{ backupsDir: string; keepDays: number }} opts
 */
function pruneOldBackups(opts) {
  const { backupsDir, keepDays } = opts;
  if (!fs.existsSync(backupsDir)) return;

  const cutoffMs = Date.now() - Math.max(1, keepDays) * 86_400_000;
  for (const name of fs.readdirSync(backupsDir)) {
    if (!/^pos-.*\.db$/i.test(name)) continue;
    const full = path.join(backupsDir, name);
    let stat;
    try {
      stat = fs.statSync(full);
    } catch {
      continue;
    }
    if (stat.mtimeMs < cutoffMs) {
      try {
        fs.unlinkSync(full);
      } catch (e) {
        console.warn('[backup] failed to delete old backup', full, e.message);
      }
    }
  }
}

/**
 * Runs scheduled backups via cron syntax (default every 30 minutes).
 * @param {{
 *   db_path: string;
 *   backup_dir: string;
 *   backup_keep_days?: number;
 *   backup_interval_cron?: string;
 *   log?: (m: string, ...a: unknown[]) => void;
 * }} cfg
 */
function startBackupScheduler(cfg) {
  const log = cfg.log || ((m, ...a) => console.log(`[backup] ${m}`, ...a));
  const cronExpr = cfg.backup_interval_cron || '*/30 * * * *';

  /** @type {import('node-cron').ScheduledTask | null} */
  let task = null;
  task = cron.schedule(
    cronExpr,
    () => {
      try {
        if (!fs.existsSync(cfg.db_path)) {
          log('db missing at %s — skip snapshot', cfg.db_path);
          return;
        }
        const dest = copyDatabaseBackup(cfg.db_path, cfg.backup_dir);
        pruneOldBackups({ backupsDir: cfg.backup_dir, keepDays: cfg.backup_keep_days ?? 7 });
        log('snapshot written %s', dest);
      } catch (err) {
        log('scheduler error %s', err instanceof Error ? err.message : String(err));
      }
    },
    { scheduled: true }
  );

  return () => {
    if (task) task.stop();
    task = null;
  };
}

module.exports = {
  copyDatabaseBackup,
  pruneOldBackups,
  startBackupScheduler,
};
