---
language: en
---

# design-be: Webhook Retry Queue

Implements `REQ-01`, `REQ-02` (see `STDD/webhook-retry-queue/spec.md`).

## BE plan

The delivery worker gains a retry queue backed by the existing job-queue
table. No new service is introduced — retry scheduling is a new job type on
the existing worker.

## Table schema

| Column | Type | Notes |
|---|---|---|
| `id` | uuid | primary key |
| `webhook_id` | uuid | FK to `webhooks.id` |
| `attempt` | int | starts at 0, max 5 (REQ-01) |
| `status` | enum(`pending`,`failed`,`delivered`) | REQ-01 |
| `next_attempt_at` | timestamptz | null once `status != pending` |

## Services relationship

```mermaid
graph LR
  API[Webhook API] --> Worker[Delivery Worker]
  Worker --> Queue[(Retry Queue table)]
  Worker --> Ext[Third-party Endpoint]
```

## Sequence: retry on 5xx (REQ-01, S-01)

```mermaid
sequenceDiagram
  participant W as Delivery Worker
  participant E as Third-party Endpoint
  participant Q as Retry Queue

  W->>E: POST payload
  E-->>W: 503
  W->>Q: enqueue retry (delay = min(2^attempt*1s, 60s))
  W->>Q: increment attempt
```

## C3 (Component) — Delivery Worker internals (conditional, this change splits it)

Plain Mermaid `graph` syntax only (banned constructs: single source of truth
is `stdd-lint`'s `references/checklist.md` — not restated here).

```mermaid
graph TD
  Dispatcher[Dispatch Loop] --> Scheduler[Backoff Scheduler]
  Dispatcher --> Sender[HTTP Sender]
  Scheduler --> Queue[(Retry Queue table)]
  Sender --> Queue
```

## N/A sections

- Auth/authz changes: N/A — this change reuses the existing webhook API's
  existing auth.
