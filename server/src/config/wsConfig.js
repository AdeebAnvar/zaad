/**
 * WebSocket server configuration (host, port, safety limits).
 * Values override via `.env`; see `.env.example`.
 */

function envInt(key, fallback) {
  const v = Number.parseInt(process.env[key], 10);
  return Number.isFinite(v) ? v : fallback;
}

module.exports = {
  host: process.env.WS_HOST || "0.0.0.0",
  port: envInt("WS_PORT", 3001),
  // Default 15 MiB: ITEM_UPSERT may embed base64 images for SUB terminals.
  maxPayloadBytes: envInt("WS_MAX_PAYLOAD_BYTES", 15 * 1024 * 1024),
  heartbeatMs: envInt("WS_HEARTBEAT_MS", 30000),
  maxConnections: envInt("WS_MAX_CONNECTIONS", 512),
};
