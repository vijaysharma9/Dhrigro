# Daily Rashan — Production Monitoring

## Stack

| Component | Purpose |
|-----------|---------|
| Prometheus | Scrapes `/metrics` from API |
| Grafana | Dashboards + visualization |
| Alertmanager | Routes alerts to Slack/PagerDuty |
| Sentry | Backend + Flutter error tracking |
| Firebase Crashlytics | Mobile crash reports |

## Quick start (local)

```bash
# API must expose /metrics on :3000
docker compose -f docker-compose.monitoring.yml up -d

# Grafana: http://localhost:3001 (admin / admin)
# Prometheus: http://localhost:9090
```

## Metrics exposed

- `http_requests_total` — counter by method, route, status
- `http_request_duration_seconds` — histogram
- `websocket_connections_active` — gauge
- `bullmq_queue_depth` — gauge by queue name
- `db_query_duration_seconds` — histogram
- Node.js default metrics (CPU, memory, event loop)

## Dashboards

Pre-built: `infra/grafana/dashboards/daily-rashan-api.json`

Panels: request rate, P95 latency, WebSocket connections, queue depth, 5xx rate.

## Alert rules

File: `infra/alerts/daily-rashan.rules.yml`

| Alert | Condition | Severity |
|-------|-----------|----------|
| HighErrorRate | 5xx > 5% for 5m | critical |
| HighLatencyP95 | p95 > 1s for 10m | warning |
| QueueBacklog | depth > 100 for 5m | warning |
| WebSocketConnectionsDrop | -50 in 10m | warning |
| DatabaseSlowQueries | DB p95 > 500ms | warning |
| PaymentFailuresSpike | payment 4xx/5xx spike | critical |

## Sentry setup

```bash
# backend/.env.production
SENTRY_DSN=https://...@sentry.io/...

# Flutter — add to release build
flutter build appbundle --dart-define=SENTRY_DSN=...
```

## Crashlytics

Enabled via Firebase in `main.dart` bootstrap. Verify dSYM/upload symbols for iOS release builds.

## On-call runbook

1. **Payment alert** → Check Razorpay dashboard + `payment_audit_log` table
2. **Queue alert** → Redis connectivity + BullMQ failed jobs
3. **WebSocket alert** → Socket.io pod restarts, CORS, JWT expiry
4. **DB alert** → Slow query log, connection pool, index health
