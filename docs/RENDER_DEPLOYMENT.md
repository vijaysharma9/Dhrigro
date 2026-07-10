# Free deployment: Render API + Neon Postgres + Vercel frontends

**$0/month** for MVP — with cold-start tradeoffs on Render free tier.

```
Customer  →  dhrigro-customer.vercel.app  →  Vercel (free)
Admin     →  dhrigro-admin.vercel.app      →  Vercel (free)
API       →  dhrigro-api.onrender.com      →  Render (free)
Database  →  Neon project                  →  Neon (free)
```

---

## Overview

| Step | What you do | Time |
|------|-------------|------|
| 1 | Create free Neon Postgres | ~5 min |
| 2 | Deploy API on Render (Blueprint) | ~10 min |
| 3 | Seed the database | ~2 min |
| 4 | Point Vercel apps at Render API | ~5 min |
| 5 | Verify end-to-end | ~5 min |

---

## Step 1 — Neon (free database)

1. Go to [neon.tech](https://neon.tech) and sign up (GitHub login is fine).
2. **New Project** → name it `dhrigro` → region closest to you (e.g. `Asia Pacific`).
3. Open **Dashboard → Connection details**.
4. Copy the **pooled** connection string (not direct). It looks like:
   ```
   postgresql://user:password@ep-xxxx.ap-southeast-1.aws.neon.tech/neondb?sslmode=require
   ```
5. Save it somewhere safe — you'll paste it into Render in Step 2.

> Neon free tier: 0.5 GB storage, DB may sleep when idle (first query can be slow).

---

## Step 2 — Render (free API)

### Option A — Blueprint (recommended)

1. Push this repo to GitHub if not already:
   ```bash
   git push origin main
   ```
2. Go to [render.com](https://render.com) → sign up → connect GitHub.
3. **New +** → **Blueprint** → select repo `vijaysharma9/Dhrigro`.
4. Render reads `render.yaml` and creates service `dhrigro-api`.
5. When prompted for **`DATABASE_URL`**, paste your Neon pooled URL from Step 1.
6. Click **Apply** and wait for the first deploy (~5–10 min).

### Option B — Manual web service

1. **New +** → **Web Service** → connect GitHub repo.
2. Settings:

   | Setting | Value |
   |---------|-------|
   | Name | `dhrigro-api` |
   | Root Directory | `backend` |
   | Runtime | **Docker** |
   | Plan | **Free** |
   | Region | Singapore (or nearest) |
   | Health Check Path | `/health` |

3. **Environment** → add variables (see table below).
4. **Create Web Service**.

### Required environment variables

Set these in Render → your service → **Environment**:

| Variable | Value |
|----------|-------|
| `NODE_ENV` | `production` |
| `DATABASE_URL` | Neon pooled URL from Step 1 |
| `JWT_ACCESS_SECRET` | Run `./scripts/generate-production-secrets.sh` locally |
| `JWT_REFRESH_SECRET` | (same script) |
| `RAZORPAY_WEBHOOK_SECRET` | (same script — placeholder until Razorpay is configured) |
| `CORS_ORIGINS` | `https://dhrigro-customer.vercel.app,https://dhrigro-admin.vercel.app` |
| `REDIS_ENABLED` | `false` |
| `QUEUES_ENABLED` | `false` |
| `REALTIME_ENABLED` | `false` |
| `SWAGGER_ENABLED` | `false` |

Add custom domains to `CORS_ORIGINS` when you set them up (comma-separated, no spaces).

### Get your API URL

After deploy succeeds:

```
https://dhrigro-api.onrender.com
```

Test:

```bash
curl https://dhrigro-api.onrender.com/health
# {"status":"ok","database":"ok",...}
```

> **Free tier note:** Render sleeps after ~15 min without traffic. The first request after sleep may take 30–60+ seconds.

---

## Step 3 — Seed the database

From your machine (with Node.js installed):

```bash
cd /path/to/dailyRashan
DATABASE_URL="postgresql://..." ./scripts/seed-neon.sh
```

Replace `DATABASE_URL` with the same Neon URL from Step 1.

This creates:

- Admin: `admin@dhrigro.com` / `Admin@123456`
- Sample categories and products

Verify login:

```bash
curl -X POST https://dhrigro-api.onrender.com/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@dhrigro.com","password":"Admin@123456"}'
```

---

## Step 4 — Point Vercel frontends at Render

Your Flutter web apps need the Render API URL baked in at build time.

### Option A — GitHub Actions (if CI deploys Vercel)

1. GitHub repo → **Settings → Secrets and variables → Actions → Variables**
2. Add repository variable:
   ```
   API_BASE_URL = https://dhrigro-api.onrender.com/api/v1
   ```
3. Re-run workflow **Deploy** (or push a change to `apps/daily_rashan/`).

### Option B — Build and deploy locally

```bash
API_BASE_URL=https://dhrigro-api.onrender.com/api/v1 ./scripts/build-vercel.sh customer
API_BASE_URL=https://dhrigro-api.onrender.com/api/v1 ./scripts/build-vercel.sh admin
# Then deploy build/web folders to Vercel (or use vercel CLI)
```

### Option C — Vercel dashboard rebuild

If Vercel builds from git without the dart-define, use Option A or B — `API_BASE_URL` must be set at **build** time.

---

## Step 5 — Verify everything

| Check | Command / URL |
|-------|----------------|
| API health | `curl https://dhrigro-api.onrender.com/health` |
| Products | `curl 'https://dhrigro-api.onrender.com/api/v1/products?limit=3'` |
| Customer app | Open https://dhrigro-customer.vercel.app |
| Admin app | Open https://dhrigro-admin.vercel.app → login |

---

## Optional — custom domain for API

1. Render service → **Settings → Custom Domains** → add `api.dhrigro.com`.
2. Add the CNAME record Render gives you at your DNS provider.
3. Update `CORS_ORIGINS` and `API_BASE_URL` to use `https://api.dhrigro.com/api/v1`.
4. Rebuild Vercel apps.

---

## Troubleshooting

### Deploy fails on migrations

The startup script auto-bootstraps fresh databases. Check **Logs** in Render for `[deploy]` messages.

### `Invalid credentials` on admin login

Run Step 3 (seed) again with the correct `DATABASE_URL`.

### CORS errors in browser

Add your exact frontend origin to `CORS_ORIGINS` in Render (including `https://`, no trailing slash).

### Cold start / slow first request

Normal on Render free tier. Upgrade to **Starter ($7/mo)** when you need always-on.

### Neon connection errors

- Use the **pooled** connection string.
- Ensure `?sslmode=require` is present.

---

## Cost summary

| Service | Free tier limits |
|---------|------------------|
| Neon | 0.5 GB, projects sleep when idle |
| Render | 750 hrs/mo, sleeps after 15 min idle |
| Vercel | Hobby tier for personal projects |

**Total: $0** for development and early MVP.

---

## Migrating from Railway

1. Export data from Railway Postgres if needed (or re-seed on Neon).
2. Follow Steps 1–4 above.
3. Update `API_BASE_URL` on Vercel.
4. Cancel Railway subscription when done.
