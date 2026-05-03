# Shared contracts

Lightweight schemas for coordinating Flutter clients (`client/`) and the LAN hub (`server/`). Adapt field names gradually as you migrate repositories off drift.

## REST — `POST /orders`

Server assigns `invoice_number` and UUID `id`.

```json
{
  "localId": "optional-client-uuid-stable-id",
  "customerId": "optional",
  "device": {
    "id": "device-uuid",
    "name": "Front desk",
    "platform": "flutter",
    "appVersion": "1.0.0+20"
  },
  "notes": "optional text",
  "metadata": {},
  "items": [
    {
      "sku": "SKU-123",
      "name": "Cappuccino",
      "qty": 2,
      "unitPriceCents": 350,
      "taxCents": 0
    }
  ],
  "payments": [
    {
      "method": "cash",
      "amountCents": 700,
      "reference": "optional receipt ref",
      "metadata": {}
    }
  ]
}
```

Success `201`:

```json
{
  "order": { "...sqlite row..." },
  "items": [ "..." ],
  "payments": [ "..." ]
}
```

## REST — `PATCH /orders/:id/status`

```json
{ "status": "completed" }
```

Statuses are free-form strings validated by your workflows server-side (`open`, `completed`, `void`, etc.).

## WebSocket envelopes

```json
{ "type": "NEW_ORDER"|"ORDER_UPDATED", "payload": { "order": {}, "items": [], "payments": [] }, "ts": "ISO-8601" }
```

Dart clients should tolerate unknown `type`s for forwards compatibility.

## Cloud relay batch

See `server/README.md § Cloud push`.
