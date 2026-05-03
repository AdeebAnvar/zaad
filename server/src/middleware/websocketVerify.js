'use strict';

const { websocketTokenOk } = require('./requireBearer');

/** @typedef {import('../config/index').AppConfig['auth']} AuthCfg */

/**
 * Adapter for ws `verifyClient(info, cb)` / boolean form.
 * @param {AuthCfg | Record<string, unknown>} authConfig
 */
function createWsVerifyClient(authConfig) {
  const auth = /** @type {AuthCfg & { disabled?: boolean; required_token?: string }} */ (
    typeof authConfig === 'object' && authConfig !== null ? authConfig : {}
  );

  return function verifyWsClient(info /* , cb unused */ ) {
    const req = /** @type {import('http').IncomingMessage | undefined} */ (info.req);
    const url = typeof req?.url === 'string' ? req.url : '';
    return websocketTokenOk(auth, url.startsWith('/') ? url : `/${url}`);
  };
}

module.exports = { createWsVerifyClient };
