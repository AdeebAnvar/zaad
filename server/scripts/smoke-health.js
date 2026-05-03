'use strict';

const base = process.env.SMOKE_BASE_URL || `http://${process.env.HOST || '127.0.0.1'}:${process.env.PORT || 3000}`;

async function main() {
  const res = await fetch(new URL('/health', base.endsWith('/') ? base : `${base}/`), {
    headers: { accept: 'application/json' },
  });
  const body = await res.text();
  if (!res.ok) {
    console.error('[smoke] failed', res.status, body);
    process.exitCode = 1;
    return;
  }
  console.log('[smoke]', res.status, body);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
