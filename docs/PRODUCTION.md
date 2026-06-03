# Production Hardening Guide

## Environment setup

### Backend

```bash
cd backend
cp .env.example .env.production
# Edit secrets — JWT min 32 chars, Razorpay webhook secret required in production
export NODE_ENV=production
```

Load order: `.env.${NODE_ENV}` → `.env`

Startup validates `DATABASE_URL`, JWT secrets, and production Razorpay webhook secret.

### Flutter

```bash
cd apps/daily_rashan
cp .env.example .env.production
flutter run --dart-define=ENV=production
```

## Deploy (Docker)

```bash
chmod +x scripts/*.sh
./scripts/deploy.sh docker
```

Uses `docker-compose.production.yml` + Nginx reverse proxy.

## Health checks

| URL | Purpose |
|-----|---------|
| `GET /health` | Liveness |
| `GET /health/ready` | DB + Redis readiness |
| `GET /health/db` | DB latency |

## Redis

Set `REDIS_URL`. Used for:

- Home feed cache (`CACHE_TTL_HOME`)
- Admin dashboard cache (`CACHE_TTL_DASHBOARD`)
- Payment locks + webhook idempotency
- OTP storage optional fallback to Postgres

## Migrations

```bash
./scripts/migrate.sh
# includes: 20250603180000_production_audit_logs
```

## Monitoring

- Structured HTTP logs with `x-request-id`
- `PaymentAuditLog` + `NotificationDeliveryLog` tables
- Optional `SENTRY_DSN` (wire SDK when ready)
- Prometheus/Grafana: add scrape target for `/health` (custom metrics TBD)

## CI

GitHub Actions: `.github/workflows/ci.yml` — backend build + test, Flutter analyze + test.

## Rollback

1. `pm2 reload` previous build or `docker compose` previous image tag
2. DB: restore from `./scripts/backup-db.sh` output
