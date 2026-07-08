# Production Launch Roadmap

Track launch progress for **Dhrigro** (Railway API + Vercel web + Neon Postgres).

**Last updated:** 2026-07-08  
**Overall status:** 🟡 Pre-launch — local stack verified; cloud infrastructure not provisioned

| Phase | Status |
|-------|--------|
| 1 — Provision infrastructure | ❌ Not started |
| 2 — Database initialization | ✅ Local only |
| 3 — API validation | ✅ Local only |
| 4 — Frontend validation | ⚠️ Partial (local) |
| 5 — External services | ❌ Not configured |
| 6 — Remaining production items | 🟡 In progress |
| Go-live checklist | ❌ Not ready |

---

## Phase 1 — Provision infrastructure

Complete in this order.

### Neon

- [ ] Create PostgreSQL database at [neon.tech](https://neon.tech)
- [ ] Copy pooled `DATABASE_URL`
- [ ] Store in Railway as `DATABASE_URL`

### Railway

- [ ] Create new project at [railway.app](https://railway.app)
- [ ] Connect GitHub repo `vijaysharma9/Dhrigro`
- [ ] Set root directory to `backend`
- [ ] Configure production env (see `backend/.env.example`)
- [ ] Verify deployment logs and `GET /health` → 200
- [ ] Add custom domain `api.dhrigro.com`

**Required env:**
```env
NODE_ENV=production
DATABASE_URL=<neon-pooled-url>
JWT_ACCESS_SECRET=<64-char-random>
JWT_REFRESH_SECRET=<64-char-random>
CORS_ORIGINS=https://dhrigro.com,https://www.dhrigro.com,https://admin.dhrigro.com
REDIS_ENABLED=false
QUEUES_ENABLED=false
REALTIME_ENABLED=false
SWAGGER_ENABLED=false
```

### Vercel

- [ ] Create **Customer** project (root `apps/daily_rashan`, output `build/web`)
- [ ] Create **Admin** project (same settings)
- [ ] Connect both to GitHub
- [ ] Add GitHub secrets: `VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID_CUSTOMER`, `VERCEL_PROJECT_ID_ADMIN`
- [ ] Set repo variable `API_BASE_URL=https://api.dhrigro.com/api/v1`
- [ ] Trigger `.github/workflows/deploy-vercel.yml`

### DNS

| Host | Points to |
|------|-----------|
| `dhrigro.com` | Vercel customer project |
| `www.dhrigro.com` | Vercel customer project |
| `admin.dhrigro.com` | Vercel admin project |
| `api.dhrigro.com` | Railway service |

- [ ] Configure CNAME/A records
- [ ] Wait for DNS propagation (`dig api.dhrigro.com`)

### SSL

- [ ] Railway certificate active for `api.dhrigro.com`
- [ ] Vercel certificates active for customer + admin domains

---

## Phase 2 — Database initialization

Run **after** Railway is connected to Neon:

```bash
cd backend
DATABASE_URL="postgresql://..." npx prisma migrate deploy
DATABASE_URL="postgresql://..." npm run prisma:seed
```

| Check | Local | Production |
|-------|-------|------------|
| Migrations applied | ✅ | ⬜ |
| Seed completed | ✅ | ⬜ |
| Categories (16 top-level) | ✅ | ⬜ |
| Subcategories (85) | ✅ | ⬜ |
| Products | ✅ | ⬜ |
| Admin `admin@dhrigro.com` | ✅ | ⬜ |
| Settings | ⚠️ defaults | ⬜ |

---

## Phase 3 — API validation

```bash
./scripts/verify-api.sh https://api.dhrigro.com
```

| Endpoint / area | Local | Production |
|-----------------|-------|------------|
| `/health` | ✅ | ⬜ |
| `/health/database` | ✅ | ⬜ |
| `/health/version` | ✅ | ⬜ |
| Authentication | ✅ | ⬜ |
| Categories | ✅ | ⬜ |
| Products | ✅ | ⬜ |
| Cart | ✅ | ⬜ |
| Orders | ✅ | ⬜ |
| Inventory (admin) | ✅ | ⬜ |
| Reports (admin) | ✅ | ⬜ |

---

## Phase 4 — Frontend validation

### Customer (`dhrigro.com`)

| Screen | Local | Production |
|--------|-------|------------|
| Home | ⬜ manual | ⬜ |
| Categories | ⬜ | ⬜ |
| Search | ⬜ | ⬜ |
| Product details | ⬜ | ⬜ |
| Cart | ⬜ | ⬜ |
| Checkout | ⬜ Razorpay not set | ⬜ |
| Orders | ⬜ | ⬜ |

### Admin (`admin.dhrigro.com`)

| Screen | Local | Production |
|--------|-------|------------|
| Login | ⬜ | ⬜ |
| Dashboard | ⬜ | ⬜ |
| Categories | ⬜ | ⬜ |
| Products | ⬜ | ⬜ |
| Inventory | ⬜ | ⬜ |
| Orders | ⬜ | ⬜ |
| Reports | ⬜ | ⬜ |
| Settings | ⬜ | ⬜ |

**Local URLs:** Customer http://localhost:8081 · Admin http://localhost:8080

---

## Phase 5 — Configure external services

### SMS / OTP

- [ ] Choose provider (MSG91, Twilio, etc.)
- [ ] Add API keys to Railway env
- [ ] Verify OTP expiry and rate limits in production

### Payments

- [ ] Set production Razorpay keys (`RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, `RAZORPAY_WEBHOOK_SECRET`)
- [ ] Set `RAZORPAY_KEY_ID` in Vercel build / Flutter `--dart-define`
- [ ] Test full payment → webhook → order confirmed flow

### Push notifications

- [ ] Configure Firebase web (`FIREBASE_*` in Vercel build)
- [ ] Test browser notifications on customer app

---

## Phase 6 — Remaining production items

| Item | Status | Notes |
|------|--------|-------|
| Commit frontend env fixes | 🟡 Pending commit | `env_config.dart`, `pubspec.yaml`, `api_exception.dart` |
| Stock validation at checkout | ✅ Implemented | Atomic reserve on place; restore on cancel |
| Redis for multi-instance | ⬜ Optional | Set `REDIS_ENABLED=true` + Upstash when scaling |
| Remove hardcoded admin credentials | ✅ Done | Empty controllers in `admin_auth_gate.dart` |
| API verification script | ✅ Done | `scripts/verify-api.sh` |

---

## Final go-live checklist

Before public announcement:

- [ ] `main` contains all approved commits
- [ ] GitHub Actions deploy workflow succeeds
- [ ] Railway deployment healthy (`/health` 200)
- [ ] Neon migrate + seed succeed
- [ ] Vercel customer + admin live
- [ ] DNS resolves for all four hosts
- [ ] SSL active on all domains
- [ ] Customer app hits production API (no CORS errors)
- [ ] Admin panel works end-to-end
- [ ] `./scripts/verify-api.sh` passes on production
- [ ] Change default admin password after first login

---

## Related docs

- [PRODUCTION_DEPLOYMENT_GUIDE.md](./PRODUCTION_DEPLOYMENT_GUIDE.md)
- [VERCEL_DEPLOYMENT.md](./VERCEL_DEPLOYMENT.md)
- [PRODUCTION_VERIFICATION_REPORT.md](./PRODUCTION_VERIFICATION_REPORT.md)
- [PRODUCTION_READINESS_AUDIT.md](./PRODUCTION_READINESS_AUDIT.md)
