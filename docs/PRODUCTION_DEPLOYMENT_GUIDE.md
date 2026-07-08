# Dhrigro Production Deployment Guide

End-to-end guide for running Dhrigro in production using **Railway (API)** + **Vercel (Flutter web)** + **Neon (Postgres)**.

See also:
- [VERCEL_DEPLOYMENT.md](./VERCEL_DEPLOYMENT.md) — Vercel-specific setup
- [PRODUCTION_READINESS_AUDIT.md](./PRODUCTION_READINESS_AUDIT.md) — audit findings
- [PRODUCTION_VERIFICATION_REPORT.md](./PRODUCTION_VERIFICATION_REPORT.md) — post-deploy checklist

---

## Architecture

```
Customer (dhrigro.com)     ──┐
                             ├──► API (api.dhrigro.com) ──► Neon Postgres
Admin (admin.dhrigro.com)  ──┘         Railway
```

Optional: Upstash Redis for caching, queues, and realtime at scale.

---

## 1. Provision services

| Service | Provider | Purpose |
|---------|----------|---------|
| Postgres | Neon | Primary database |
| API | Railway | NestJS backend (`backend/`) |
| Customer web | Vercel | Flutter `main.dart` |
| Admin web | Vercel | Flutter `main_admin.dart` |

---

## 2. Database setup

```bash
cd backend
DATABASE_URL="postgresql://..." npx prisma migrate deploy
DATABASE_URL="postgresql://..." npm run prisma:seed
```

---

## 3. Railway API

1. Connect GitHub repo `vijaysharma9/Dhrigro`
2. Set root directory: `backend`
3. Uses `backend/railway.toml` and `scripts/railway-start.sh`
4. Set environment variables from `backend/.env.example`
5. Custom domain: `api.dhrigro.com`

**Required production env:**
```env
NODE_ENV=production
DATABASE_URL=...
JWT_ACCESS_SECRET=<64-char-random>
JWT_REFRESH_SECRET=<64-char-random>
CORS_ORIGINS=https://dhrigro.com,https://admin.dhrigro.com
RAZORPAY_WEBHOOK_SECRET=...
REDIS_ENABLED=false
QUEUES_ENABLED=false
REALTIME_ENABLED=false
SWAGGER_ENABLED=false
```

---

## 4. Vercel frontends

Two projects from the same repo. Builds run via GitHub Actions (`.github/workflows/deploy-vercel.yml`).

**GitHub secrets required:**
- `VERCEL_TOKEN`, `VERCEL_ORG_ID`
- `VERCEL_PROJECT_ID_CUSTOMER`, `VERCEL_PROJECT_ID_ADMIN`

**Repository variable:**
- `API_BASE_URL` = `https://api.dhrigro.com/api/v1`

---

## 5. Health endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET /health` | Liveness + summary (status, uptime, version, database, environment) |
| `GET /health/database` | Database connectivity |
| `GET /health/version` | Build version metadata |
| `GET /health/ready` | Readiness (503 when DB unavailable) |
| `GET /health/db` | Legacy alias (backward compatible) |

---

## 6. Monitoring (optional)

```env
SENTRY_DSN=https://...@sentry.io/...
LOG_LEVEL=info
METRICS_TOKEN=<random>
```

Install Sentry SDK on Railway: `npm install @sentry/node` in `backend/`.

Protect metrics: pass header `x-metrics-token: <METRICS_TOKEN>` to `GET /metrics`.

---

## 7. Verify deployment

Run through [PRODUCTION_VERIFICATION_REPORT.md](./PRODUCTION_VERIFICATION_REPORT.md).

---

## 8. Rollback

- **API:** Railway → redeploy previous deployment
- **Frontends:** Vercel → instant rollback to prior deployment
- **Database:** restore Neon snapshot; run `prisma migrate resolve` if needed
