# Background Queues (BullMQ)

## Queues

| Queue | Purpose |
|-------|---------|
| `notifications` | Push/email delivery |
| `exports` | CSV/PDF report generation |
| `payment-reconciliation` | Razorpay sync |
| `analytics` | Dashboard aggregation |
| `stock-alerts` | Low stock notifications |

## Configuration

```env
QUEUES_ENABLED=true
REDIS_URL=redis://localhost:6379
```

When `QUEUES_ENABLED=false`, jobs run inline (dev fallback).

## Retry & dead letter

- **Attempts:** 3 with exponential backoff (2s base)
- **Completed jobs:** keep last 100
- **Failed jobs:** keep last 500 (manual replay via BullMQ UI or custom admin tool)

## Worker separation

Run API and workers separately in production:

```bash
# API
node dist/main.js

# Workers (future dedicated entry)
QUEUES_ENABLED=true node dist/worker.js
```

## Monitoring

Admin **System → Health** shows queue depth and failed job counts.  
Prometheus metric: `bullmq_queue_depth{queue="notifications"}`.

## Enqueue from code

```typescript
await this.queues.enqueue(QUEUE_NAMES.STOCK_ALERTS, {
  type: 'stock_alert',
  data: { productId, name, stock },
  correlationId: requestId,
});
```
