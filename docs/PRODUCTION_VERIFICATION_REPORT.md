# Production Verification Checklist

Use this checklist after deploying Dhrigro to production (Railway API + Vercel frontends).

**Last run:** _not yet executed against production_  
**Environment:** _fill in URLs before testing_

| Service | URL |
|---------|-----|
| API | `https://api.dhrigro.com` |
| Customer | `https://dhrigro.com` |
| Admin | `https://admin.dhrigro.com` |

---

## Authentication

| Check | Status | Notes |
|-------|--------|-------|
| Admin email/password login | ⬜ Pending | `admin@dhrigro.com` |
| Customer login | ⬜ Pending | |
| OTP request/verify | ⬜ Pending | Requires SMS provider |
| Token refresh on 401 | ⬜ Pending | |
| Logout clears session | ⬜ Pending | |
| Invalid credentials rejected | ⬜ Pending | |

---

## Categories & Products

| Check | Status | Notes |
|-------|--------|-------|
| Category tree loads | ⬜ Pending | `GET /api/v1/categories/tree` |
| Subcategories load | ⬜ Pending | |
| Product list paginates | ⬜ Pending | |
| Product detail by slug/id | ⬜ Pending | |
| Search returns results | ⬜ Pending | |
| Home feed loads | ⬜ Pending | `GET /api/v1/home` |

---

## Inventory & Orders

| Check | Status | Notes |
|-------|--------|-------|
| Admin inventory list | ⬜ Pending | |
| Stock update from admin | ⬜ Pending | |
| Cart add/update/remove | ⬜ Pending | |
| Checkout places order | ⬜ Pending | |
| Order history for customer | ⬜ Pending | |
| Admin order status update | ⬜ Pending | |

---

## Reports (Admin)

| Check | Status | Notes |
|-------|--------|-------|
| Dashboard KPIs | ⬜ Pending | `GET /api/v1/admin/dashboard` |
| Revenue report | ⬜ Pending | |
| Orders report | ⬜ Pending | |
| CSV export | ⬜ Pending | |

---

## Admin Panel (Web)

| Check | Status | Notes |
|-------|--------|-------|
| Login page loads | ⬜ Pending | No pre-filled credentials |
| Dashboard renders | ⬜ Pending | |
| Products CRUD | ⬜ Pending | |
| Orders board | ⬜ Pending | |
| Users list | ⬜ Pending | |
| Session timeout (30 min) | ⬜ Pending | |

---

## Customer App (Web)

| Check | Status | Notes |
|-------|--------|-------|
| Splash → home flow | ⬜ Pending | |
| Product browsing | ⬜ Pending | |
| Cart & checkout | ⬜ Pending | |
| Profile & orders | ⬜ Pending | |
| Deep links work (SPA) | ⬜ Pending | Refresh on `/products/:id` |

---

## API Health

| Check | Status | Command |
|-------|--------|---------|
| `GET /health` | ⬜ Pending | Returns status, uptime, version, database |
| `GET /health/database` | ⬜ Pending | DB latency |
| `GET /health/version` | ⬜ Pending | Version metadata |
| `GET /health/ready` | ⬜ Pending | 503 when DB down |
| CORS from Vercel origins | ⬜ Pending | Browser preflight |

---

## Deployment

| Check | Status | Notes |
|-------|--------|-------|
| Railway API running | ⬜ Pending | |
| Prisma migrations applied | ⬜ Pending | |
| Vercel customer deploy | ⬜ Pending | |
| Vercel admin deploy | ⬜ Pending | |
| GitHub Actions deploy workflow | ⬜ Pending | |
| SSL on all domains | ⬜ Pending | |
| Security headers on Vercel | ⬜ Pending | CSP, HSTS |

---

## Summary (fill after testing)

| Result | Count |
|--------|-------|
| ✅ Passed | 0 |
| ⚠️ Warnings | 0 |
| ❌ Failed | 0 |

### Warnings
- _None yet_

### Failed
- _None yet_

### Recommended fixes
- Run this checklist after first production deploy
- Enable Redis + realtime when scaling beyond MVP
- Integrate SMS provider before enabling OTP in production
- Set `METRICS_TOKEN` before exposing `/metrics`

---

## Quick smoke commands

```bash
# API health
curl -s https://api.dhrigro.com/health | jq

# Admin login
curl -s -X POST https://api.dhrigro.com/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@dhrigro.com","password":"YOUR_PASSWORD"}' | jq

# Categories
curl -s https://api.dhrigro.com/api/v1/categories/tree | jq '.[0:2]'
```
