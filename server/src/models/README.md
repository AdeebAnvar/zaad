See `shared/contracts.md` for JSON shapes exchanged with Flutter clients.

Persistent columns follow snake_case inside SQLite (`invoice_number`, `created_at`). WebSocket payloads currently mirror persisted rows keyed as returned by SQLite drivers.
