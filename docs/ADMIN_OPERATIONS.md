# Admin Operations Guide

## Daily ops workflow

1. **Dashboard** — live activity stream, KPIs, polling every 20s
2. **Orders** — bulk actions, filter presets, keyboard shortcuts (`/`, J/K, Enter)
3. **Delivery → Dispatch board** — kanban with SLA countdown and urgency highlighting
4. **System** — health, audit, automation rules, BI metrics

## Live updates

- **WebSocket connected:** near-realtime invalidation (orders, inventory, dashboard)
- **Polling fallback:** automatic when WS unavailable
- **Offline banner:** shows degraded/disconnected state with retry

## System Health page

| Metric | Meaning |
|--------|---------|
| API latency | DB ping proxy |
| Redis | Cache/queue connectivity |
| WebSocket connections | Active admin/partner sockets |
| Queue depth | Pending BullMQ jobs |
| Payment failures today | Failed transactions count |

## Automation rules

Toggle in **System → Automation**:

- Mark delayed orders (>2h pending)
- Low stock alerts
- VIP order priority
- Auto-assign nearest partner (disabled by default)

## Command palette (⌘K)

Quick commands: delayed orders, pending assignment, low stock, dispatch board, reports.

## Performance targets

- 10k+ orders: use virtualized tables + server pagination
- 100 concurrent admins: WebSocket + Redis cache; avoid full dashboard rebuild storms

## Troubleshooting

| Symptom | Check |
|---------|-------|
| Stale orders | WS indicator → Reconnect; manual refresh |
| 401 loops | Re-login; check JWT expiry |
| Queue backlog | System → Health queue breakdown |
| Slow pages | DevTools + `AdminPerfLogger.snapshot()` |
