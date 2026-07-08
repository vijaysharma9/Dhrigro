# Daily Rashan — Architecture

## Overview

Monorepo grocery platform: Flutter (customer / admin / delivery entry points), NestJS API, PostgreSQL, Redis.

```
┌─────────────┐     REST/WS      ┌──────────────┐
│ Flutter Web │ ◄──────────────► │  NestJS API  │
│ Admin/Ops   │                  │  + Gateway   │
└─────────────┘                  └──────┬───────┘
                                        │
                    ┌───────────────────┼───────────────────┐
                    ▼                   ▼                   ▼
              PostgreSQL              Redis              BullMQ workers
              (Prisma)           (cache/queues)        (notifications…)
```

## Admin architecture

- **Entry:** `lib/main_admin.dart` → `AdminAuthGate` → `AdminHomeScreen`
- **Shell:** `AdminShell` — nav, top bar, offline banner, FAB, command palette
- **State:** Riverpod providers in `admin_providers.dart`
- **Data:** `AdminRepository` (Dio) — no architecture change from Phase 4
- **Live ops:** WebSocket (`admin_realtime.dart`) with polling fallback (`AdminSectionPoller`)

## Backend modules

| Module | Purpose |
|--------|---------|
| `common/realtime` | Socket.IO gateway, JWT auth, room subscriptions |
| `common/metrics` | Prometheus `/metrics`, HTTP timing |
| `common/queues` | BullMQ — notifications, exports, reconciliation, analytics, stock alerts |
| `common/audit` | Admin mutation audit trail |
| `common/automation` | Rule engine — delayed orders, stock alerts, VIP priority |

## Scaling notes

- **Horizontal API:** Stateless NestJS + Redis-backed throttle (future) + shared Redis for queues/cache
- **WebSocket:** Sticky sessions or Redis adapter for multi-instance Socket.IO
- **Workers:** Run queue consumers as separate processes (`QUEUES_ENABLED=true`)
- **Database:** Indexed queries on `Order.placedAt`, `Order.status`, `AdminAuditLog.createdAt`

## RBAC

Staff roles: `SUPER_ADMIN`, `OPERATIONS_ADMIN`, `INVENTORY_MANAGER`, `CUSTOMER_SUPPORT`.  
Permissions enforced via `PermissionsGuard` + `@AdminAccess()` on `/admin/*`.
