'use strict';

const path = require('path');

/**
 * Production: run from C:\POS\server\
 * Usage: cd C:\POS\server && npm install --omit=dev && pm2 start ecosystem.config.cjs
 */
module.exports = {
  apps: [
    {
      name: 'pos-server',
      script: path.join(__dirname, 'server.js'),
      cwd: __dirname,
      instances: 1,
      exec_mode: 'fork',
      autorestart: true,
      watch: false,
      max_memory_restart: '512M',
      env: {
        NODE_ENV: 'production',
      },
      error_file: path.join(__dirname, 'logs', 'pm2-error.log'),
      out_file: path.join(__dirname, 'logs', 'pm2-out.log'),
      merge_logs: true,
      time: true,
    },
  ],
};
