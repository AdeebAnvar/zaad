'use strict';

require('dotenv').config();
const { start } = require('./src/bootstrap');

start().catch((err) => {
  console.error('[pos-server] fatal', err);
  process.exitCode = 1;
});
