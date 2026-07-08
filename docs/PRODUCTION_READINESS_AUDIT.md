# Dhrigro Production Readiness Audit

**Date:** 2026-07-08  
**Scope:** Full monorepo — Flutter customer/admin, NestJS backend, Prisma, deployment, security  
**Status:** Audit only — no code changes in this phase

---

## Executive Summary

Dhrigro has a **solid MVP foundation**: NestJS security middleware, JWT auth with refresh rotation, global validation, structured logging with request IDs, Prisma migrations in deploy pipelines, and Vercel CI for Flutter web. **Production launch is blocked** by several critical security and inventory integrity issues. Recommended path: fix Critical/High items, deploy API on Railway + frontends on Vercel, then iterate on Medium items.

| Severity | Count |
|----------|-------|
| Critical | 2 |
| High | 9 |
| Medium | 18 |
| Low | 14 |

---

## Critical

### C-01 — No stock validation on order placement

| Field | Detail |
|-------|--------|
| **Description** | `placeOrder` creates orders without checking or decrementing product stock. Overselling is possible under concurrent load. |
| **File** | `backend/src/modules/orders/orders.service.ts` |
| **Recommended fix** | Validate stock in transaction; atomic decrement; reject if insufficient. |
| **Effort** | 4–6 hours |

### C-02 — Hardcoded admin credentials in admin web bundle

| Field | Detail |
|-------|--------|
| **Description** | Admin login form pre-fills `admin@dhrigro.com` / `Admin@123456`, compiled into the web build. |
| **File** | `apps/daily_rashan/lib/features/admin/presentation/screens/admin_auth_gate.dart` (L79–80) |
| **Recommended fix** | Empty `TextEditingController()` defaults; use env/dev-only flag for seed hints. |
| **Effort** | 30 minutes |

---

## High

### H-01 — Public unauthenticated `/metrics` endpoint

| Field | Detail |
|-------|--------|
| **Description** | Prometheus metrics exposed without auth. Leaks operational data. |
| **File** | `backend/src/common/metrics/metrics.controller.ts` |
| **Recommended fix** | Protect with API key, IP allowlist, or internal-only network. |
| **Effort** | 1–2 hours |

### H-02 — OTP brute-force / no SMS delivery

| Field | Detail |
|-------|--------|
| **Description** | OTP endpoints share global 100/min throttle; OTP logged to server; no SMS provider integrated. |
| **File** | `backend/src/modules/auth/auth.service.ts`, `auth.controller.ts` |
| **Recommended fix** | Stricter `@Throttle` on auth routes; integrate SMS; remove OTP logging. |
| **Effort** | 1 day |

### H-03 — JWT strategy fallback secret

| Field | Detail |
|-------|--------|
| **Description** | `secretOrKey` falls back to `'fallback-secret'` if config missing. |
| **File** | `backend/src/modules/auth/strategies/jwt.strategy.ts` (L23) |
| **Recommended fix** | Throw at startup if secret missing; remove fallback. |
| **Effort** | 15 minutes |

### H-04 — Web token storage vulnerable to XSS

| Field | Detail |
|-------|--------|
| **Description** | `FlutterSecureStorage` on web uses localStorage-based backend without `WebOptions`. |
| **File** | `apps/daily_rashan/lib/shared/providers/storage_provider.dart` |
| **Recommended fix** | Add CSP headers; consider httpOnly cookie auth for web; document XSS risk. |
| **Effort** | 4–8 hours |

### H-05 — `.env` files bundled as Flutter assets

| Field | Detail |
|-------|--------|
| **Description** | `pubspec.yaml` includes `.env` and `.env.development` as assets — can ship secrets in web bundle if present at build time. |
| **File** | `apps/daily_rashan/pubspec.yaml` |
| **Recommended fix** | Remove from assets; use `--dart-define` only for production web builds. |
| **Effort** | 1 hour |

### H-06 — Admin ErrorWidget exposes exception details

| Field | Detail |
|-------|--------|
| **Description** | Custom `ErrorWidget.builder` renders full `exceptionAsString()` to users. |
| **File** | `apps/daily_rashan/lib/main_admin.dart` |
| **Recommended fix** | Generic error UI in production; log details server-side only. |
| **Effort** | 30 minutes |

### H-07 — GoRouter debug diagnostics enabled in production

| Field | Detail |
|-------|--------|
| **Description** | `debugLogDiagnostics: true` logs route info to browser console. |
| **File** | `apps/daily_rashan/lib/core/router/app_router.dart` |
| **Recommended fix** | `debugLogDiagnostics: kDebugMode` |
| **Effort** | 15 minutes |

### H-08 — Readiness probe returns HTTP 200 when not ready

| Field | Detail |
|-------|--------|
| **Description** | `/health/ready` returns 200 with `status: not_ready` when DB is down. Orchestrators won't detect failure. |
| **File** | `backend/src/health/health.controller.ts` |
| **Recommended fix** | Return 503 when `not_ready`. |
| **Effort** | 30 minutes |

### H-09 — Sentry DSN configured but not wired

| Field | Detail |
|-------|--------|
| **Description** | `SENTRY_DSN` in config but no SDK initialization. Errors not tracked in production. |
| **File** | `backend/src/config/configuration.ts`, `backend/src/main.ts` |
| **Recommended fix** | Optional `@sentry/node` init when DSN set. |
| **Effort** | 2–3 hours |

---

## Medium

### M-01 — No graceful shutdown on SIGTERM

| **File** | `backend/src/main.ts` |
| **Fix** | `app.enableShutdownHooks()` |
| **Effort** | 30 min |

### M-02 — No `trust proxy` behind Railway/nginx

| **File** | `backend/src/main.ts` |
| **Fix** | Enable trust proxy in production |
| **Effort** | 15 min |

### M-03 — 500 errors may leak internal `Error.message`

| **File** | `backend/src/common/filters/http-exception.filter.ts` |
| **Fix** | Generic message in production for non-HTTP exceptions |
| **Effort** | 30 min |

### M-04 — Refresh token DB expiry hardcoded +7 days

| **File** | `backend/src/modules/auth/auth.service.ts` |
| **Fix** | Use `JWT_REFRESH_EXPIRES` from config |
| **Effort** | 30 min |

### M-05 — `LOG_LEVEL` config unused

| **File** | `backend/src/config/configuration.ts`, logging interceptor |
| **Fix** | Wire Nest logger level |
| **Effort** | 1 hour |

### M-06 — Localhost API URL compile-time fallback

| **File** | `apps/daily_rashan/lib/core/config/env_config.dart` |
| **Fix** | Fail validation in production if URL contains localhost |
| **Effort** | 30 min |

### M-07 — Dev error message exposed to users

| **File** | `apps/daily_rashan/lib/core/network/api_exception.dart` |
| **Fix** | Generic "Unable to connect" in production |
| **Effort** | 15 min |

### M-08 — Missing CSP / HSTS on Vercel

| **File** | `apps/daily_rashan/vercel.json` |
| **Fix** | Add security headers |
| **Effort** | 1 hour |

### M-09 — Categories API returns all records (no pagination)

| **File** | `backend/src/modules/categories/categories.service.ts` |
| **Fix** | Paginate or cap tree depth |
| **Effort** | 2–3 hours |

### M-10 — Reports `topProductsReport` loads all order IDs into memory

| **File** | `backend/src/modules/admin/services/admin-reports.service.ts` |
| **Fix** | SQL aggregation instead of in-memory |
| **Effort** | 2 hours |

### M-11 — Railway healthcheck is liveness-only

| **File** | `backend/railway.toml` |
| **Fix** | Document; optionally use `/health/ready` |
| **Effort** | 15 min |

### M-12 — In-memory throttler ineffective with multiple replicas

| **File** | `backend/src/app.module.ts` |
| **Fix** | Redis-backed throttler for production |
| **Effort** | 4 hours |

### M-13 — Customer product list no infinite scroll

| **File** | `apps/daily_rashan/lib/features/products/presentation/providers/` |
| **Fix** | Paginated provider with load-more |
| **Effort** | 3–4 hours |

### M-14 — `CachedNetworkImage` without `memCacheWidth`

| **File** | `apps/daily_rashan/lib/shared/widgets/product_card.dart` and others |
| **Fix** | Add memory cache dimensions |
| **Effort** | 2 hours |

### M-15 — Production CORS not validated at boot

| **File** | `backend/src/config/env.validation.ts` |
| **Fix** | Require `CORS_ORIGINS` in production |
| **Effort** | 30 min |

### M-16 — Missing indexes on `RefreshToken.expiresAt`, `OtpRecord.expiresAt`

| **File** | `backend/prisma/schema.prisma` |
| **Fix** | Add indexes + cleanup job |
| **Effort** | 1 hour |

### M-17 — Config scattered (hardcoded URLs in realtime gateway)

| **File** | `backend/src/common/realtime/realtime.gateway.ts` |
| **Fix** | Use ConfigService for CORS origins |
| **Effort** | 1 hour |

### M-18 — Deploy pipeline lacks backend build gate

| **File** | `.github/workflows/deploy-vercel.yml` |
| **Fix** | Add NestJS build + Flutter analyze/test before deploy |
| **Effort** | 2 hours |

---

## Low

| ID | Issue | File | Effort |
|----|-------|------|--------|
| L-01 | Helmet defaults only (no custom CSP) | `main.ts` | 1h |
| L-02 | No Dockerfile HEALTHCHECK | `backend/Dockerfile` | 30m |
| L-03 | Container runs as root | `backend/Dockerfile` | 1h |
| L-04 | Category parent delete no cascade rule | `schema.prisma` | 1h |
| L-05 | `placeOrder` inline body type (no DTO) | `orders.controller.ts` | 1h |
| L-06 | Delivery app not in Vercel pipeline | `deploy-vercel.yml` | 2h |
| L-07 | No refresh-token mutex on parallel 401s | `dio_client.dart` | 2h |
| L-08 | Monolithic Flutter web bundle | `app_router.dart` | 1 day |
| L-09 | `admin_repository` no local try/catch | `admin_repository.dart` | 1h |
| L-10 | Bootstrap logs hardcoded localhost | `main.ts` | 15m |
| L-11 | `REALTIME_ENABLED` missing from `.env.example` | `backend/.env.example` | 15m |
| L-12 | Import template uses example.com URL | `products.controller.ts` | 15m |
| L-13 | Soft-delete `Product.deletedAt` not indexed | `schema.prisma` | 30m |
| L-14 | PM2 cluster without Redis queue coordination | `ecosystem.config.js` | 4h |

---

## Area Summaries

### Flutter Customer App
**Ready:** Env-driven API, auth + refresh, go_router guards, cached images, platform-aware payments.  
**Gaps:** localhost fallback, debug logging, web token storage, no product pagination.

### Flutter Admin App
**Ready:** Role gate, session timeout, paginated tables, realtime optional.  
**Gaps:** Hardcoded credentials (Critical), error widget leak, debug diagnostics.

### NestJS Backend
**Ready:** Helmet, compression, CORS, ValidationPipe, exception filter, JWT, throttling, audit log, pagination on core entities.  
**Gaps:** Stock validation, metrics exposure, OTP security, Sentry unwired, graceful shutdown.

### Prisma / Database
**Ready:** Good index coverage on orders/products/users; sensible FK restrict on orders.  
**Gaps:** Missing expiry indexes, no stock constraint at DB level.

### Authentication
**Ready:** bcrypt(12), refresh rotation, role guards, `@Public()` decorator.  
**Gaps:** OTP abuse, fallback JWT secret, dev OTP in response.

### Deployment
**Ready:** Railway.toml, Vercel CI, Docker multi-stage, Prisma migrate on deploy.  
**Gaps:** Readiness semantics, Flutter not on Vercel native build, no deploy gates.

### Environment Variables
**Ready:** `.env.example` files, dart-define for production API URL.  
**Gaps:** Incomplete production validation, config not fully centralized.

### Security
**Ready:** Swagger disabled in prod, Razorpay webhook verification, admin RBAC.  
**Gaps:** Metrics public, credential prefill, XSS surface on web, info leakage in errors.

---

## Recommended Fix Order

1. **Critical** — Stock validation, remove admin credential prefill  
2. **High** — JWT secret, metrics auth, Sentry, readiness 503, web security headers  
3. **Medium** — Graceful shutdown, trust proxy, config centralization, CI gates  
4. **Low** — Performance polish, delivery web deploy, code splitting  

Phases 2–10 of the production hardening plan address items in this audit.
