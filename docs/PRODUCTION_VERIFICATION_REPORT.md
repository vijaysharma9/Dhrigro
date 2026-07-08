# Production Verification Checklist

Use this checklist after deploying Dhrigro to production (Railway API + Vercel frontends).

**Last run:** 2026-07-08 (local pre-production)  
**Production status:** Infrastructure **not deployed** — `api.dhrigro.com`, `dhrigro.com`, and `admin.dhrigro.com` do not resolve yet.

| Environment | API | Customer | Admin |
|-------------|-----|----------|-------|
| **Local (verified)** | http://localhost:3000 | http://localhost:8081 | http://localhost:8080 |
| **Production (target)** | https://api.dhrigro.com | https://dhrigro.com | https://admin.dhrigro.com |

---

## Step 2 — Infrastructure deployment

| Step | Status | Notes |
|------|--------|-------|
| Neon PostgreSQL | ❌ Not started | Create project at [neon.tech](https://neon.tech), copy pooled `DATABASE_URL` |
| Railway API | ❌ Not started | Connect `vijaysharma9/Dhrigro`, root dir `backend` |
| Customer app (Vercel) | ❌ Not started | Project + `VERCEL_PROJECT_ID_CUSTOMER` secret |
| Admin app (Vercel) | ❌ Not started | Project + `VERCEL_PROJECT_ID_ADMIN` secret |
| Custom domains | ❌ Not started | DNS CNAMEs for api / www / admin |
| SSL certificates | ❌ Not started | Auto-provisioned by Railway & Vercel after DNS |

### Step 2 action checklist

1. **Neon** — Create DB → run `DATABASE_URL="..." npx prisma migrate deploy` → `npm run prisma:seed`
2. **Railway** — Deploy `backend/` → set env from `backend/.env.example` → domain `api.dhrigro.com`
3. **Vercel** — Two projects (`apps/daily_rashan`, output `build/web`) → domains `dhrigro.com` + `admin.dhrigro.com`
4. **GitHub** — Secrets: `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID_CUSTOMER`, `VERCEL_PROJECT_ID_ADMIN`; variable `API_BASE_URL`
5. **Deploy** — Push to `main` or run **Deploy** workflow manually

See [PRODUCTION_DEPLOYMENT_GUIDE.md](./PRODUCTION_DEPLOYMENT_GUIDE.md) and [VERCEL_DEPLOYMENT.md](./VERCEL_DEPLOYMENT.md).

---

## Step 3 — Database (local run)

| Check | Status | Notes |
|-------|--------|-------|
| `prisma migrate deploy` | ✅ Passed | All 6 migrations applied (incl. `20260708120000_production_indexes`) |
| `npm run prisma:seed` | ✅ Passed | Admin, 101 categories, delivery partner seeded |
| Categories | ✅ Passed | 16 top-level categories |
| Subcategories | ✅ Passed | 85 subcategories |
| Admin account | ✅ Passed | `admin@dhrigro.com` / `Admin@123456` |
| Products | ✅ Passed | Product API returns paginated data |
| Settings | ⚠️ Warning | App settings use DB defaults; verify after production seed |

> **Neon:** Repeat migrate + seed with production `DATABASE_URL` after Step 2.

---

## Step 4 — API verification (local)

| Endpoint | Status | HTTP |
|----------|--------|------|
| `GET /health` | ✅ Passed | 200 — status, uptime, version, database, environment |
| `GET /health/database` | ✅ Passed | 200 — database ok |
| `GET /health/version` | ✅ Passed | 200 — version metadata |
| `POST /api/v1/auth/login` | ✅ Passed | 201 — admin login |
| `GET /api/v1/categories/tree` | ✅ Passed | 200 |
| `GET /api/v1/home` | ✅ Passed | 200 |
| `GET /api/v1/products` | ✅ Passed | 200 |
| `GET /api/v1/cart` (auth) | ✅ Passed | 200 |
| `GET /api/v1/orders` (auth) | ✅ Passed | 200 |
| `GET /api/v1/admin/dashboard` | ✅ Passed | 200 |
| `GET /api/v1/admin/inventory` | ✅ Passed | 200 |
| `GET /api/v1/admin/reports/revenue` | ✅ Passed | 200 |
| `GET /api/v1/admin/reports/orders` | ✅ Passed | 200 |

### Production API (pending Step 2)

| Check | Status |
|-------|--------|
| All endpoints on `api.dhrigro.com` | ⬜ Pending |
| CORS from Vercel origins | ⬜ Pending |
| `GET /health/ready` returns 503 when DB down | ⬜ Pending |

---

## Step 5 — Frontend verification (local)

### Customer app

| Check | Status | Notes |
|-------|--------|-------|
| App loads | ✅ Passed | Title `Dhrigro`, routes to onboarding |
| Home page | ⬜ Pending | Manual UI test after onboarding |
| Categories | ⬜ Pending | |
| Product details | ⬜ Pending | |
| Search | ⬜ Pending | |
| Cart | ⬜ Pending | |
| Checkout | ⬜ Pending | Razorpay keys not set |
| Orders | ⬜ Pending | |
| Responsive layout | ⬜ Pending | |

### Admin panel

| Check | Status | Notes |
|-------|--------|-------|
| App loads | ✅ Passed | Title `Dhrigro Admin` |
| Login | ⬜ Pending | Manual — `admin@dhrigro.com` / `Admin@123456` |
| Dashboard | ⬜ Pending | |
| Categories | ⬜ Pending | |
| Products | ⬜ Pending | |
| Inventory | ⬜ Pending | |
| Orders | ⬜ Pending | |
| Reports | ⬜ Pending | |
| Settings | ⬜ Pending | |

---

## Full checklist (production — run after Step 2)

### Authentication

| Check | Status | Notes |
|-------|--------|-------|
| Admin email/password login | ⬜ Pending | |
| Customer login | ⬜ Pending | |
| OTP request/verify | ⬜ Pending | Requires SMS provider |
| Token refresh on 401 | ⬜ Pending | |
| Logout clears session | ⬜ Pending | |
| Invalid credentials rejected | ⬜ Pending | |

### Deployment

| Check | Status | Notes |
|-------|--------|-------|
| Railway API running | ⬜ Pending | |
| Prisma migrations on Neon | ⬜ Pending | |
| Vercel customer deploy | ⬜ Pending | |
| Vercel admin deploy | ⬜ Pending | |
| GitHub Actions deploy workflow | ⬜ Pending | |
| SSL on all domains | ⬜ Pending | |
| Security headers on Vercel | ⬜ Pending | |

---

## Summary

| Result | Local | Production |
|--------|-------|------------|
| ✅ Passed | 22 | 0 |
| ⚠️ Warnings | 2 | 0 |
| ❌ Failed | 0 | 6 (infra not provisioned) |

### Warnings

- OTP/SMS not configured — disable or stub in production until provider is set
- Razorpay live keys empty — checkout will fail until configured
- Uncommitted local env fixes (`env_config.dart`, `pubspec.yaml`) — commit before Vercel deploy

### Failed (production blockers)

- Neon PostgreSQL not provisioned
- Railway API not deployed
- Vercel customer/admin not deployed
- Custom domains not configured
- DNS does not resolve for `*.dhrigro.com`
- SSL not yet applicable (no domains)

### Recommended fixes

1. Complete **Step 2** in order: Neon → Railway → Vercel → DNS → SSL
2. On Neon: `DATABASE_URL="..." npx prisma migrate deploy && npm run prisma:seed`
3. Set Railway `CORS_ORIGINS` to production Vercel URLs
4. Add GitHub secrets and trigger deploy workflow
5. Re-run this checklist against production URLs
6. Commit env-loading fix before next frontend deploy

---

## Quick smoke commands

```bash
# API health (replace host after deploy)
curl -s https://api.dhrigro.com/health | jq
curl -s https://api.dhrigro.com/health/database | jq
curl -s https://api.dhrigro.com/health/version | jq

# Categories
curl -s https://api.dhrigro.com/api/v1/categories/tree | jq '.[0:2]'

# Local verification script
./scripts/verify-api.sh http://localhost:3000
```
