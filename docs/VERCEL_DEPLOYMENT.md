# Dhrigro production deployment (Option A)

**Vercel** hosts the Flutter web frontends. **Railway** hosts the NestJS API. **Neon** (or similar) hosts Postgres.

```
Customer  →  dhrigro.com          →  Vercel
Admin     →  admin.dhrigro.com    →  Vercel
API       →  api.dhrigro.com      →  Railway
Database  →  (managed Postgres)   →  Neon
```

---

## 1. Database (Neon)

1. Create a project at [neon.tech](https://neon.tech).
2. Copy the pooled `DATABASE_URL`.
3. Run migrations locally once:

```bash
cd backend
DATABASE_URL="postgresql://..." npx prisma migrate deploy
DATABASE_URL="postgresql://..." npm run prisma:seed
```

---

## 2. API on Railway

1. Go to [railway.app](https://railway.app) → **New Project** → **Deploy from GitHub repo**.
2. Select `vijaysharma9/Dhrigro`.
3. Set **Root Directory** to `backend`.
4. Railway reads `backend/railway.toml` for build/start commands.

### Required Railway variables

```env
NODE_ENV=production
APP_NAME=Dhrigro
API_PREFIX=api/v1
DATABASE_URL=postgresql://...   # from Neon

JWT_ACCESS_SECRET=<random-64-chars>
JWT_REFRESH_SECRET=<random-64-chars>

CORS_ORIGINS=https://dhrigro.com,https://www.dhrigro.com,https://admin.dhrigro.com

# MVP — optional services (enable later)
REDIS_ENABLED=false
QUEUES_ENABLED=false
REALTIME_ENABLED=false
```

Railway injects `PORT` automatically; the API reads `PORT` before `API_PORT`.

### Custom domain

1. Railway service → **Settings** → **Networking** → **Custom Domain** → `api.dhrigro.com`.
2. Add the CNAME record at your DNS provider.
3. Verify: `curl https://api.dhrigro.com/health`

---

## 3. Vercel projects (2 frontends)

Create **two** Vercel projects from the same GitHub repo.

### Project A — Customer (`dhrigro-customer`)

| Setting | Value |
|---------|-------|
| Root Directory | `apps/daily_rashan` |
| Framework | Other |
| Build Command | *(leave empty — CI builds)* |
| Output Directory | `build/web` |

Domain: `dhrigro.com` (or `app.dhrigro.com`)

### Project B — Admin (`dhrigro-admin`)

Same settings as customer. Domain: `admin.dhrigro.com`

> Builds run in GitHub Actions (Flutter is not available on Vercel's default image). Vercel receives the prebuilt `build/web` output.

---

## 4. GitHub secrets & variables

In **GitHub → Settings → Secrets and variables → Actions**:

### Secrets

| Name | How to get it |
|------|----------------|
| `VERCEL_TOKEN` | [vercel.com/account/tokens](https://vercel.com/account/tokens) |
| `VERCEL_ORG_ID` | Vercel project → Settings → General |
| `VERCEL_PROJECT_ID_CUSTOMER` | Customer project settings |
| `VERCEL_PROJECT_ID_ADMIN` | Admin project settings |

### Variables (repository)

| Name | Example |
|------|---------|
| `API_BASE_URL` | `https://api.dhrigro.com/api/v1` |

---

## 5. Deploy

### Automatic (on push to `main`)

Pushes that touch `apps/daily_rashan/**` trigger `.github/workflows/deploy-vercel.yml`.

### Manual

```bash
# GitHub Actions → Deploy → Run workflow → target: all | customer | admin
```

### Local build (test before deploy)

```bash
API_BASE_URL=https://api.dhrigro.com/api/v1 ./scripts/build-vercel.sh customer
API_BASE_URL=https://api.dhrigro.com/api/v1 ./scripts/build-vercel.sh admin
```

Output: `apps/daily_rashan/build/web/`

---

## 6. Post-deploy checklist

- [ ] `curl https://api.dhrigro.com/health` returns 200
- [ ] Admin login at `https://admin.dhrigro.com` with `admin@dhrigro.com`
- [ ] Customer app loads products from live API
- [ ] CORS allows both Vercel domains (check browser console)
- [ ] Razorpay live keys set when enabling payments
- [ ] Firebase web config set for push notifications

---

## 7. Enable Redis & realtime (later)

When ready for production-grade features:

1. Add [Upstash Redis](https://upstash.com) and set `REDIS_URL` on Railway.
2. Set `REDIS_ENABLED=true`, `QUEUES_ENABLED=true`, `REALTIME_ENABLED=true`.
3. Redeploy API.

---

## Files added for this setup

| File | Purpose |
|------|---------|
| `apps/daily_rashan/vercel.json` | SPA routing + cache headers |
| `scripts/build-vercel.sh` | Local/CI Flutter web build |
| `.github/workflows/deploy-vercel.yml` | Build + deploy to Vercel |
| `backend/railway.toml` | Railway build/start config |
